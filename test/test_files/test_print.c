#include "print.h"

int main(){
    int a = 42;
    int b = 2000000000;
    _printf("Hello, World! a = %d\r", a);
    _printf("\r\n");
    _printf("Hello\t,\tWorld! a = %d\n", a);
    _printf("Hello, World! b = 0x%x\n", b);
    _printf("Hello, World! b = %d\n", b);
    _printf("a = 0x%x, b = 0x%x\n", a, b);

    return 0;
}