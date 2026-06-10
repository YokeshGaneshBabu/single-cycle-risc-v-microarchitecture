// Software multiply for RV32I (no M extension)
unsigned int __mulsi3(unsigned int a, unsigned int b) {
    unsigned int result = 0;
    while (b) {
        if (b & 1) result += a;
        a <<= 1;
        b >>= 1;
    }
    return result;
}
