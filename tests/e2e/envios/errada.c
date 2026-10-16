// Errada de propósito: int de 32 bits, e a soma de 2·10^9 com 2·10^9 estoura.
#include <stdio.h>

int main(void) {
    int a, b;
    if (scanf("%d %d", &a, &b) == 2) printf("%d\n", a + b);
    return 0;
}
