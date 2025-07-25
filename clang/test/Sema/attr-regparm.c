// RUN: %clang_cc1 -triple i386-apple-darwin9 -fsyntax-only -verify %s

__attribute((regparm(2))) int x0(void);
__attribute((regparm(1.0))) int x1(void); // expected-error{{'regparm' attribute requires an integer constant}}
__attribute((regparm(-1))) int x2(void); // expected-error{{'regparm' parameter must be between 0 and 3 inclusive}}
__attribute((regparm(5))) int x3(void); // expected-error{{'regparm' parameter must be between 0 and 3 inclusive}}
__attribute((regparm(5,3))) int x4(void); // expected-error{{'regparm' attribute takes one argument}}

void __attribute__((regparm(3))) x5(int);
void x5(int); // expected-note{{previous declaration is here}}
void __attribute__((regparm(2))) x5(int); // expected-error{{function declared with regparm(2) attribute was previously declared with the regparm(3) attribute}}

[[gnu::regparm(3)]] void x6(int); // expected-note{{previous declaration is here}}
[[gnu::regparm(2)]] void x6(int); // expected-error{{function declared with regparm(2) attribute was previously declared with the regparm(3) attribute}}
void x6 [[gnu::regparm(3)]] (int);
void [[gnu::regparm(3)]] x6(int); // expected-warning{{'regparm' only applies to function types; type here is 'void'}}
void x6(int) [[gnu::regparm(3)]]; // expected-warning{{GCC does not allow the 'gnu::regparm' attribute to be written on a type}}
