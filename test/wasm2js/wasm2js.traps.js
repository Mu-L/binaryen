
    function f32Equal(a, b) {
       var i = new Int32Array(1);
       var f = new Float32Array(i.buffer);
       f[0] = a;
       var ai = f[0];
       f[0] = b;
       var bi = f[0];

       return (isNaN(a) && isNaN(b)) || a == b;
    }

    function f64Equal(a, b) {
       var i = new Int32Array(2);
       var f = new Float64Array(i.buffer);
       f[0] = a;
       var ai1 = i[0];
       var ai2 = i[1];
       f[0] = b;
       var bi1 = i[0];
       var bi2 = i[1];

       return (isNaN(a) && isNaN(b)) || (ai1 == bi1 && ai2 == bi2);
    }

    function i64Equal(actual_lo, actual_hi, expected_lo, expected_hi) {
       return (actual_lo | 0) == (expected_lo | 0) && (actual_hi | 0) == (expected_hi | 0);
    }
  
function asmFunc0(imports) {
 var Math_imul = Math.imul;
 var Math_fround = Math.fround;
 var Math_abs = Math.abs;
 var Math_clz32 = Math.clz32;
 var Math_min = Math.min;
 var Math_max = Math.max;
 var Math_floor = Math.floor;
 var Math_ceil = Math.ceil;
 var Math_trunc = Math.trunc;
 var Math_sqrt = Math.sqrt;
 function $0() {
  
 }
 
 function $1(x, y) {
  x = x | 0;
  y = y | 0;
  return x + y | 0 | 0;
 }
 
 function $2(x, y) {
  x = x | 0;
  y = y | 0;
  return (x | 0) / (y | 0) | 0 | 0;
 }
 
 return {
  "empty": $0, 
  "add": $1, 
  "div_s": $2
 };
}

var retasmFunc0 = asmFunc0({
});
function check1() {
 retasmFunc0.empty();
 return 1 | 0;
}

if (!check1()) throw 'assertion failed on line 9';
function check2() {
 return (retasmFunc0.add(1 | 0, 1 | 0) | 0 | 0) == (2 | 0) | 0;
}

if (!check2()) throw 'assertion failed on line 10';
function check3() {
 function f() {
  return retasmFunc0.div_s(0 | 0, 0 | 0) | 0 | 0;
 }
 
 try {
  f();
 } catch (e) {
  return 1;
 };
 return 0;
}

if (!check3()) throw 'assertion failed on line 11';
function check4() {
 function f() {
  return retasmFunc0.div_s(-2147483648 | 0, -1 | 0) | 0 | 0;
 }
 
 try {
  f();
 } catch (e) {
  return 1;
 };
 return 0;
}

if (!check4()) throw 'assertion failed on line 12';
