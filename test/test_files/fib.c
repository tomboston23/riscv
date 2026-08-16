#include "print.h"

int fib_rec(int n) {
    if (n <= 1) {
        return n;
    }
    return fib_rec(n - 1) + fib_rec(n - 2);

    // return n;
}

int fib_dp(int n) {
    if (n <= 1) {
        return n;
    }
    int prev1 = 0;
    int prev2 = 1;
    int current;
    for (int i = 2; i <= n; i++) {
        current = prev1 + prev2;
        prev1 = prev2;
        prev2 = current;
    }
    return current;

    return n;
}

int main() {
    int n = 20;
    int result_dp = fib_dp(n);
    int result_rec = fib_rec(n);
    int success;
    if (result_dp == result_rec) {
        success = 1; // Success
    } else {
        success = 0; // Failure
    }
    _printf("Success: %d\n", success);
    return 0;
}