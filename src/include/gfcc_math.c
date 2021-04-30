// AUM SHREEGANESHAAYA NAMAH|| /* DIETY INVOCATION */
#ifndef __GFCC_MATH__
#define __GFCC_MATH__

double GFCC_M_PI = 3.141592653589793115997963468544185162;
double GFCC_M_E  = 2.718281828459045090795598298427648842;
double __GFCC_M_PREC__  = 0.000000000000001;
double __GFCC_M_LOG2__  = 0.693147180559945286226763982995180413;
double __GFCC_M_LOG10__ = 2.302585092994045901093613792909309268;

double gfcc_fabs(double x) { return (x > 0.0) ? x : (-x); } // ok

unsigned long long gfcc_abs(long long x) { return (x > 0) ? x : (-x); } // ok

unsigned long long gfcc_fact(int x) { // ok
  if (x < 0) return 0; // must be -INFINITY
  if (x <= 1) return 1;
  return x*gfcc_fact(x-1);
}

long long gfcc_fib(int x) { // 5 -3 2 -1 1 0 1 1 2 3 5 // ok
  if (x < 0) return ((x % 2) ? 1 : -1) * gfcc_fib(-x); // negative values
  if (x <= 1) return x; // 0, 1
  long long y_2 = 0, y_1 = 1, y = 1, tmp;
  int curr = 2;
  while (curr != x) {
    tmp = y_1 + y;
    y_2 = y_1; y_1 = y; y = tmp;
    curr++;
  }
  return y;
}

// TODO
// long long gfcc_floor (double x) {
//   if (x > 0.0) return ((long long) x);
//   return ((long long) x) - 1;
// }

// TODO
// long long gfcc_ceil (double x) {
//   if (x > 0.0) return ((long long) x) + 1;
//   return ((long long) x);
// }

double gfcc_intpow(double x, int N) { // ok
  if (N == 0) return 1;
  if (N < 0) { x = 1 / x; N = -N; }
  double ret = 1;
  while (N) { ret *= x; N--; }
  return ret;
}

double gfcc_sqrt(double x) { // Newton's Method // ok
  if (x < 0.0) return 0.0; // or some other return value?
  if (x == 0.0) return 0.0;
  double r = x;
  while (gfcc_fabs(x - r * r) > __GFCC_M_PREC__) r = (r + (x / r)) / 2.0;
  return r;
}

double gfcc_exp(double x) { // use Taylor's expansion // ok
  if (x < 0.0) return (1.0 / gfcc_exp(-x));
  if (x > 500) return 1.0e+308;
  double ret = 0.0, term_N = 1.0;
  int N = 0;
  while (term_N > __GFCC_M_PREC__) { ret += term_N; term_N *= (x / (++N)); }
  return ret;
}

double gfcc_sin (double x) { // use Taylor's expansion // ok
  if (x < 0.0) return (-gfcc_sin(-x));
  double ret = 0.0, term_N = x;
  int N = 0;
  while (term_N > __GFCC_M_PREC__) {
    ret += (N % 2) ? (-term_N) : term_N;
    N++; term_N *= ((x * x) / (2*N*(2*N+1)));
  }
  return ret;
}

double gfcc_cos (double x) { return gfcc_sin((GFCC_M_PI / 2.0) - x); } // ok

double gfcc_tan (double x) { // ok
  double num = gfcc_sin(x), denom = gfcc_cos(x);
  if (denom != 0.0) return (num / denom);
  if (num > 0.0) return 1.0e+308; // + infinity
  return (-1.0e+308); // - infinity
}

double gfcc_arcsin (double x) { // use Taylor's expansion
  // not good enough for arcsin(1) = GFCC_M_PI / 2.0
  // try using arctan() for implementation
  if (x < 0.0) return (-gfcc_arcsin(-x));
  if (x == 1.0) return GFCC_M_PI / 2.0;
  if (x > 1.0) return 0.0; // or some other return value?
  double ret = 0.0, term_N = x;
  int N = 0; int two_N;
  while (term_N > __GFCC_M_PREC__) {
    ret += term_N; N++; two_N = 2*N;
    term_N *= ((x * x * (two_N-1) * (two_N - 1)) / (two_N*(two_N+1)));
  }
  return ret;
}

double gfcc_arccos (double x) { return (GFCC_M_PI / 2.0) - gfcc_arcsin(x); }

double gfcc_arctan (double x) { // use Taylor's expansion
  if (x < 0.0) return (-gfcc_arctan(-x));
  if (x == 1.0) return GFCC_M_PI / 4.0;
  if (x > 1.0) return ((GFCC_M_PI / 2.0) - gfcc_arctan(1.0 / x));
  double ret = 0.0, term_N = x;
  int N = 0;
  while (term_N > __GFCC_M_PREC__) {
    ret += (N % 2) ? (-term_N) : term_N; N++;
    term_N *= ((x * x * (2*N-1)) / (2*N+1));
  }
  return ret;
}

double gfcc_sinh (double x) {
  double a = gfcc_exp(x);
  return (a - (1.0 / a)) / 2.0;
}

double gfcc_cosh (double x) {
  double a = gfcc_exp(x);
  return (a + (1.0 / a)) / 2.0;
}

double gfcc_tanh (double x) {
  double a = gfcc_exp(x);
  return (a*a - 1) / (a*a + 1);
}

double gfcc_log (double x) {
  if (x <= 0.0) return -1.0e+308;
  if (x == 1.0) return 0.0;
  if (x < 1.0) return (- gfcc_log(1.0 / x)); // now assured that x > 1.0
  // now assured that x > 1.0 : so perform binary search
  double low = 0.0, high = 1.0e+308, mid = (low + high) / 2.0;
  while ((high - low) > __GFCC_M_PREC__) {
    if (gfcc_exp(mid) <= x) low = mid; else high = mid;
    mid = (low + high) / 2.0;
  }
  // if (x < 2.0) {
    // x = x - 1.0; // now use Taylor's expansion
    // double ret = 0.0, term_N = x;
    // int N = 1;
    // while (term_N > __GFCC_M_PREC__) {
    //   ret += (N % 2) ? term_N : (- term_N); N++;
    //   term_N *= (x * (N-1)) / N;
    // }
    // return ret;
  // } // what to do for values >= 2.0
  return mid;
}

double gfcc_log2 (double x) {
  return gfcc_log(x) / __GFCC_M_LOG2__;
}

double gfcc_log10 (double x) {
  return gfcc_log(x) / __GFCC_M_LOG10__;
}

double gfcc_arcsinh (double x) {
  return gfcc_log(x + gfcc_sqrt(x*x + 1.0));
}

double gfcc_arccosh (double x) {
  if (x < 1.0) return 0.0; // or some other return value?
  return gfcc_log(x + gfcc_sqrt(x*x - 1.0));
}

double gfcc_arctanh (double x) {
  if (x >= 1.0) return 1.0e+308;
  if (x <= -1.0) return -1.0e+308;
  return 0.5 * gfcc_log((1.0 + x) / (1.0 - x));
}

// TODO
// double gfcc_pow(double x) {
//   return 0.0;
// }

#endif
