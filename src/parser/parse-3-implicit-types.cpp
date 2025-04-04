/*
 * Copyright 2024 WebAssembly Community Group participants
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

#include "wat-parser-internal.h"

namespace wasm::WATParser {

Result<>
parseImplicitTypeDefs(ParseDeclsCtx& decls,
                      Lexer& input,
                      IndexMap& typeIndices,
                      std::vector<HeapTypeDef>& types,
                      std::unordered_map<Index, HeapTypeDef>& implicitTypes) {
  ParseImplicitTypeDefsCtx ctx(input, types, implicitTypes, typeIndices);
  for (Index pos : decls.implicitTypeDefs) {
    WithPosition with(ctx, pos);
    CHECK_ERR(typeuse(ctx));
  }
  // Record type indices now that all the types have been parsed.
  for (Index i = 0; i < types.size(); ++i) {
    decls.wasm.typeIndices.insert({types[i], i});
  }
  return Ok{};
}

} // namespace wasm::WATParser
