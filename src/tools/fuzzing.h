/*
 * Copyright 2017 WebAssembly Community Group participants
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
// Translate a binary stream of bytes into a valid wasm module, *somehow*.
// This is helpful for fuzzing.
//

#include "ir/branch-utils.h"
#include "ir/struct-utils.h"
#include "support/insert_ordered.h"
#include "tools/fuzzing/random.h"
#include <ir/eh-utils.h>
#include <ir/find_all.h>
#include <ir/literal-utils.h>
#include <ir/manipulation.h>
#include <ir/names.h>
#include <ir/public-type-validator.h>
#include <ir/utils.h>
#include <support/file.h>
#include <tools/optimization-options.h>
#include <wasm-builder.h>

namespace wasm {

// helper structs, since list initialization has a fixed order of
// evaluation, avoiding UB

struct ThreeArgs {
  Expression* a;
  Expression* b;
  Expression* c;
};

struct UnaryArgs {
  UnaryOp a;
  Expression* b;
};

struct BinaryArgs {
  BinaryOp a;
  Expression* b;
  Expression* c;
};

// params

struct FuzzParams {
  // The maximum amount of params to each function.
  int MAX_PARAMS;

  // The maximum amount of vars in each function.
  int MAX_VARS;

  // The maximum number of globals in a module.
  int MAX_GLOBALS;

  // The maximum number of tuple elements.
  int MAX_TUPLE_SIZE;

  // The maximum number of struct fields.
  int MAX_STRUCT_SIZE;

  // The maximum number of elements in an array.
  int MAX_ARRAY_SIZE;

  // The number of nontrivial heap types to generate.
  int MIN_HEAPTYPES;
  int MAX_HEAPTYPES;

  // some things require luck, try them a few times
  int TRIES;

  // beyond a nesting limit, greatly decrease the chance to continue to nest
  int NESTING_LIMIT;

  // the maximum size of a block
  int BLOCK_FACTOR;

  // the memory that we use, a small portion so that we have a good chance of
  // looking at writes (we also look outside of this region with small
  // probability) this should be a power of 2
  Address USABLE_MEMORY;

  // the number of runtime iterations (function calls, loop backbranches) we
  // allow before we stop execution with a trap, to prevent hangs. 0 means
  // no hang protection.
  int HANG_LIMIT;

  // the maximum amount of new GC types (structs, etc.) to create
  int MAX_NEW_GC_TYPES;

  // the maximum amount of catches in each try (not including a catch-all, if
  // present).
  int MAX_TRY_CATCHES;

  FuzzParams() { setDefaults(); }

  void setDefaults();
};

// main reader

class TranslateToFuzzReader {
  static constexpr size_t VeryImportant = 4;
  static constexpr size_t Important = 2;

public:
  TranslateToFuzzReader(Module& wasm,
                        std::vector<char>&& input,
                        bool closedWorld = false);
  TranslateToFuzzReader(Module& wasm,
                        std::string& filename,
                        bool closedWorld = false);

  void pickPasses(OptimizationOptions& options);
  void setAllowMemory(bool allowMemory_) { allowMemory = allowMemory_; }
  void setAllowOOB(bool allowOOB_) { allowOOB = allowOOB_; }
  void setPreserveImportsAndExports(bool preserveImportsAndExports_) {
    preserveImportsAndExports = preserveImportsAndExports_;
  }

  void build();

  Module& wasm;

private:
  // Whether the module will be tested in a closed-world environment.
  bool closedWorld;
  Builder builder;
  Random random;

  // Whether to emit memory operations like loads and stores.
  bool allowMemory = true;

  // Whether to emit loads, stores, and call_indirects that may be out
  // of bounds (which traps in wasm, and is undefined behavior in C).
  bool allowOOB = true;

  // Whether we preserve imports and exports. Normally we add imports (for
  // logging and other useful functionality for testing), and add exports of
  // functions as we create them. With this set, we add neither imports nor
  // exports, which is useful if the tool using us only wants us to mutate an
  // existing testcase (using initial-content).
  bool preserveImportsAndExports = false;

  // Whether we allow the fuzzer to add unreachable code when generating changes
  // to existing code. This is randomized during startup, but could be an option
  // like the above options eventually if we find that useful.
  bool allowAddingUnreachableCode;

  // Whether to emit atomic waits (which in single-threaded mode, may hang...)
  static const bool ATOMIC_WAITS = false;

  // The chance to emit a logging operation for a none expression. We
  // randomize this in each function.
  unsigned LOGGING_PERCENT = 0;

  Name HANG_LIMIT_GLOBAL;

  Name funcrefTableName;
  Name exnrefTableName;

  std::unordered_map<Type, Name> logImportNames;
  Name hashMemoryName;
  Name throwImportName;
  Name tableGetImportName;
  Name tableSetImportName;
  Name callExportImportName;
  Name callExportCatchImportName;
  Name callRefImportName;
  Name callRefCatchImportName;
  Name sleepImportName;

  std::unordered_map<Type, std::vector<Name>> globalsByType;
  std::unordered_map<Type, std::vector<Name>> mutableGlobalsByType;
  std::unordered_map<Type, std::vector<Name>> immutableGlobalsByType;
  std::unordered_map<Type, std::vector<Name>> importedImmutableGlobalsByType;

  std::vector<Type> loggableTypes;

  // The heap types we can pick from to generate instructions.
  std::vector<HeapType> interestingHeapTypes;

  // A mapping of a heap type to the subset of interestingHeapTypes that are
  // subtypes of it.
  std::unordered_map<HeapType, std::vector<HeapType>> interestingHeapSubTypes;

  // Type => list of struct fields that have that type.
  std::unordered_map<Type, std::vector<StructField>> typeStructFields;

  // Type => list of array types that have that type.
  std::unordered_map<Type, std::vector<HeapType>> typeArrays;

  // All struct fields that are mutable.
  std::vector<StructField> mutableStructFields;

  // All arrays that are mutable.
  std::vector<HeapType> mutableArrays;

  Index numAddedFunctions = 0;

  // The name of an empty tag.
  Name trivialTag;

  // RAII helper for managing the state used to create a single function.
  struct FunctionCreationContext {
    TranslateToFuzzReader& parent;
    Function* func;
    std::vector<Expression*> breakableStack; // things we can break to
    Index labelIndex = 0;

    // a list of things relevant to computing the odds of an infinite loop,
    // which we try to minimize the risk of
    std::vector<Expression*> hangStack;

    // type => list of locals with that type
    std::unordered_map<Type, std::vector<Index>> typeLocals;

    FunctionCreationContext(TranslateToFuzzReader& parent, Function* func);

    ~FunctionCreationContext();

    // Fill in the typeLocals data structure.
    void computeTypeLocals() {
      typeLocals.clear();
      for (Index i = 0; i < func->getNumLocals(); i++) {
        typeLocals[func->getLocalType(i)].push_back(i);
      }
    }
  };

  FunctionCreationContext* funcContext = nullptr;

  // The fuzzing parameters we use. This may change from function to function or
  // even in a more refined manner, so we use an RAII context to manage it.
  struct FuzzParamsContext : public FuzzParams {
    TranslateToFuzzReader& parent;

    FuzzParamsContext* old;

    FuzzParamsContext(TranslateToFuzzReader& parent)
      : parent(parent), old(parent.fuzzParams) {
      parent.fuzzParams = this;
    }

    ~FuzzParamsContext() { parent.fuzzParams = old; }
  };

  FuzzParamsContext* fuzzParams = nullptr;

  // The default global context we use throughout the process (unless it is
  // overridden using another context in an RAII manner).
  std::unique_ptr<FuzzParamsContext> globalParams;

public:
  int nesting = 0;

  struct AutoNester {
    TranslateToFuzzReader& parent;
    size_t amount = 1;

    AutoNester(TranslateToFuzzReader& parent) : parent(parent) {
      parent.nesting++;
    }
    ~AutoNester() { parent.nesting -= amount; }

    // Add more nesting manually.
    void add(size_t more) {
      parent.nesting += more;
      amount += more;
    }
  };

private:
  // Generating random data is common enough that it's worth having helpers that
  // forward to `random`.
  int8_t get() { return random.get(); }
  int16_t get16() { return random.get16(); }
  int32_t get32() { return random.get32(); }
  int64_t get64() { return random.get64(); }
  float getFloat() { return random.getFloat(); }
  double getDouble() { return random.getDouble(); }
  Index upTo(Index x) { return random.upTo(x); }
  bool oneIn(Index x) { return random.oneIn(x); }
  Index upToSquared(Index x) { return random.upToSquared(x); }

  // Pick from a vector-like container or a fixed list.
  template<typename T> const typename T::value_type& pick(const T& vec) {
    return random.pick(vec);
  }
  template<typename T, typename... Args> T pick(T first, Args... args) {
    return random.pick(first, args...);
  }
  // Pick from options associated with features.
  template<typename T> using FeatureOptions = Random::FeatureOptions<T>;
  template<typename T> const T pick(FeatureOptions<T>& picker) {
    return random.pick(picker);
  }

  // Setup methods
  void setupMemory();
  void setupHeapTypes();
  void setupTables();
  void setupGlobals();
  void setupTags();
  void addTag();
  void finalizeMemory();
  void finalizeTable();
  void shuffleExports();
  void prepareHangLimitSupport();
  void addHangLimitSupport();
  void addImportLoggingSupport();
  void addImportCallingSupport();
  void addImportThrowingSupport();
  void addImportTableSupport();
  void addImportSleepSupport();
  void addHashMemorySupport();

  // Special expression makers
  Expression* makeHangLimitCheck();
  Expression* makeImportLogging();
  Expression* makeImportThrowing(Type type);
  Expression* makeImportTableGet();
  Expression* makeImportTableSet(Type type);
  // Call either an export or a ref. We do this from a single function to better
  // control the frequency of each.
  Expression* makeImportCallCode(Type type);
  Expression* makeImportSleep(Type type);
  Expression* makeMemoryHashLogging();

  // We must be careful not to add exports that have invalid public types, such
  // as those that reach exact types when custom descriptors is disabled.
  PublicTypeValidator publicTypeValidator;
  bool isValidPublicType(Type type) {
    return publicTypeValidator.isValidPublicType(type);
  }

  // Function operations. The main processFunctions() loop will call addFunction
  // as well as modFunction().
  void processFunctions();
  // Add a new function.
  Function* addFunction();
  // Modify an existing function.
  void modFunction(Function* func);

  void addHangLimitChecks(Function* func);

  // Recombination and mutation

  // Recombination and mutation can replace a node with another node of the same
  // type, but should not do so for certain types that are dangerous. For
  // example, it would be bad to add a non-nullable reference to a tuple, as
  // that would force us to use temporary locals for the tuple, but non-nullable
  // references cannot always be stored in locals. Also, the 'pop' pseudo
  // instruction for EH is supposed to exist only at the beginning of a 'catch'
  // block, so it shouldn't be moved around or deleted freely.
  bool canBeArbitrarilyReplaced(Expression* curr) {
    // TODO: Remove this once we better support exact references.
    if (curr->type.isExact()) {
      return false;
    }
    return curr->type.isDefaultable() &&
           !EHUtils::containsValidDanglingPop(curr);
  }
  void recombine(Function* func);
  void mutate(Function* func);
  // Fix up the IR after recombination and mutation.
  void fixAfterChanges(Function* func);
  void modifyInitialFunctions();

  // Initial wasm contents may have come from a test that uses the drop pattern:
  //
  //  (drop ..something interesting..)
  //
  // The dropped interesting thing is optimized to some other interesting thing
  // by a pass, and we verify it is the expected one. But this does not use the
  // value in a way the fuzzer can notice. Replace some drops with a logging
  // operation instead.
  void dropToLog(Function* func);

  // the fuzzer external interface sends in zeros (simpler to compare
  // across invocations from JS or wasm-opt etc.). Add invocations in
  // the wasm, so they run everywhere
  void addInvocations(Function* func);

  Name makeLabel() {
    return std::string("label$") + std::to_string(funcContext->labelIndex++);
  }

  // Expression making methods. Always call the toplevel make(type) command, not
  // the specific ones.
  Expression* make(Type type);
  Expression* _makeConcrete(Type type);
  Expression* _makenone();
  Expression* _makeunreachable();

  // Make something with no chance of infinite recursion.
  Expression* makeTrivial(Type type);

  // We must note when we are nested in a makeTrivial() call. When we are, all
  // operations must try to be as trivial as possible.
  int trivialNesting = 0;

  // Specific expression creators
  Expression* makeBlock(Type type);
  Expression* makeLoop(Type type);
  Expression* makeCondition();
  // Make something, with a good chance of it being a block
  Expression* makeMaybeBlock(Type type);
  Expression* buildIf(const struct ThreeArgs& args, Type type);
  Expression* makeIf(Type type);
  Expression* makeTry(Type type);
  Expression* makeTryTable(Type type);
  Expression* makeBreak(Type type);
  Expression* makeCall(Type type);
  Expression* makeCallIndirect(Type type);
  Expression* makeCallRef(Type type);
  Expression* makeLocalGet(Type type);
  Expression* makeLocalSet(Type type);
  Expression* makeGlobalGet(Type type);
  Expression* makeGlobalSet(Type type);
  Expression* makeTupleMake(Type type);
  Expression* makeTupleExtract(Type type);
  Expression* makePointer();
  Expression* makeNonAtomicLoad(Type type);
  Expression* makeLoad(Type type);
  Expression* makeNonAtomicStore(Type type);
  Expression* makeStore(Type type);

  // Makes a small change to a constant value.
  Literal tweak(Literal value);
  Literal makeLiteral(Type type);
  Expression* makeRefFuncConst(Type type);

  // Emit a constant expression for a given type, as best we can. We may not be
  // able to emit a literal Const, like say if the type is a function reference
  // then we may emit a RefFunc, but also we may have other requirements, like
  // we may add a GC cast to fixup the type.
  Expression* makeConst(Type type);

  // Generate reference values. One function handles basic types, and the other
  // compound ones.
  Expression* makeBasicRef(Type type);
  Expression* makeCompoundRef(Type type);

  Expression* makeStringConst();
  Expression* makeStringNewArray();
  Expression* makeStringNewCodePoint();
  Expression* makeStringConcat();
  Expression* makeStringSlice();
  Expression* makeStringEq(Type type);
  Expression* makeStringMeasure(Type type);
  Expression* makeStringGet(Type type);
  Expression* makeStringEncode(Type type);

  // Similar to makeBasic/CompoundRef, but indicates that this value will be
  // used in a place that will trap on null. For example, the reference of a
  // struct.get or array.set would use this.
  Expression* makeTrappingRefUse(HeapType type);

  Expression* buildUnary(const UnaryArgs& args);
  Expression* makeUnary(Type type);
  Expression* buildBinary(const BinaryArgs& args);
  Expression* makeBinary(Type type);
  Expression* buildSelect(const ThreeArgs& args);
  Expression* makeSelect(Type type);
  Expression* makeSwitch(Type type);
  Expression* makeDrop(Type type);
  Expression* makeReturn(Type type);
  Expression* makeNop(Type type);
  Expression* makeUnreachable(Type type);
  Expression* makeAtomic(Type type);
  Expression* makeSIMD(Type type);
  Expression* makeSIMDExtract(Type type);
  Expression* makeSIMDReplace();
  Expression* makeSIMDShuffle();
  Expression* makeSIMDTernary();
  Expression* makeSIMDShift();
  Expression* makeSIMDLoad();
  Expression* makeBulkMemory(Type type);
  Expression* makeTableGet(Type type);
  Expression* makeTableSet(Type type);
  // TODO: support other RefIs variants, and rename this
  Expression* makeRefIsNull(Type type);
  Expression* makeRefEq(Type type);
  Expression* makeRefTest(Type type);
  Expression* makeRefCast(Type type);
  Expression* makeBrOn(Type type);

  // Decide to emit a signed Struct/ArrayGet sometimes, when the field is
  // packed.
  bool maybeSignedGet(const Field& field);

  Expression* makeStructGet(Type type);
  Expression* makeStructSet(Type type);
  Expression* makeArrayGet(Type type);
  Expression* makeArraySet(Type type);
  // Use a single method for the misc array operations, to not give them too
  // much representation (e.g. compared to struct operations, which only include
  // get/set).
  Expression* makeArrayBulkMemoryOp(Type type);
  Expression* makeI31Get(Type type);
  Expression* makeThrow(Type type);
  Expression* makeThrowRef(Type type);

  Expression* makeMemoryInit();
  Expression* makeDataDrop();
  Expression* makeMemoryCopy();
  Expression* makeMemoryFill();

  // Getters for Types
  Type getSingleConcreteType();
  Type getReferenceType();
  Type getEqReferenceType();
  Type getMVPType();
  Type getTupleType();
  Type getConcreteType();
  Type getControlFlowType();
  Type getStorableType();
  Type getLoggableType();
  bool isLoggableType(Type type);
  Nullability getNullability();
  Exactness getExactness();
  Nullability getSubType(Nullability nullability);
  Exactness getSubType(Exactness exactness);
  HeapType getSubType(HeapType type);
  Type getSubType(Type type);
  Nullability getSuperType(Nullability nullability);
  HeapType getSuperType(HeapType type);
  Type getSuperType(Type type);
  HeapType getArrayTypeForString();

  // Utilities
  Name getTargetName(Expression* target);
  Type getTargetType(Expression* target);

  // statistical distributions

  // 0 to the limit, logarithmic scale
  Index logify(Index x) {
    return std::floor(std::log(std::max(Index(1) + x, Index(1))));
  }
};

} // namespace wasm
