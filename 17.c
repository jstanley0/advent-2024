#include <stdio.h>
#include <stdbool.h>

bool run(long a) {
  int n = 0;
  long b, r = 0;
  while (a != 0 && n++ < 16) {
    b = (a & 7) ^ 1;
    b ^= (a >> b) ^ 4;
    a >>= 3;
    r = (r << 3) | b & 7;
  }
  return a == 0 && n == 16 && r == 02411754603145530L;
}

int main()
{
  long a = 0x200000000000L;
  while(!run(a)) {
    if ((++a & 0xffffffff) == 0)
      printf("> 0x%lx\n", a);
  }
  printf("%ld\n", a);
  return 0;
}