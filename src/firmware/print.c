#include <stdint.h>
#include <stdarg.h>
#include "print.h"
#include "_start.h"

static void _print_dec(int value)
{
    char buffer[12];
    int i = 0;

    if (value == 0) {
        _putchar('0');
        return;
    }

    if (value < 0) {
        _putchar('-');
        value = -value;
    }

    while (value > 0) {
        buffer[i++] = '0' + (value % 10);
        value /= 10;
    }

    while (i > 0) {
        _putchar(buffer[--i]);
    }
}

void _printf(const char * format, ...){
    va_list args;
    va_start(args, format);
    while (*format) {
        if (*format != '%'){
            _putchar(*format);
            format++;
        } else {
            format++;
            switch (*format) {
                case 'd': {
                    // Handle integer
                    int value = va_arg(args, int);
                    _print_dec(value);
                    break;
                }
                case 's': {
                    // Handle string
                    const char *str = va_arg(args, const char *);
                    _puts(str);
                    break;
                }
                case '%': {
                    // Handle literal '%'
                    _putchar('%');
                    break;
                }
                case 'x': {
                    // Handle hexadecimal
                    unsigned int value = va_arg(args, unsigned int);
                    int skip;
                    char buffer[9];
                    for (int i = 0; i < 8; i++) {
                        buffer[7 - i] = "0123456789abcdef"[value & 0xF];
                        value >>= 4;
                    }
                    buffer[8] = '\0';
                    _puts(buffer);
                    break;
                }
            }
            format++;
        }
    }
}

void _puts(const char *s) {
    while (*s) {
        _putchar(*s++);
    }
}

void _putchar(char c) {
    volatile uint8_t * buffer_ptr = _get_print_buffer_start();
    *buffer_ptr = c;
    _increment_print_buffer_start();
}
