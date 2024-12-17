#include <stdio.h>
#include <stdbool.h>

const int quine[16] = {2,4,1,1,7,5,4,6,0,3,1,4,5,5,3,0};

bool run(long a) {
  int res[16];
  size_t sz = 0;
  long b;
  while (a != 0 && sz < 16) {
    b = (a & 7) ^ 1;
    b ^= (a >> b) ^ 4;
    a >>= 3;
    res[sz++] = b & 7;
  }
  if (a != 0 || sz != 16)
    return false;

  for(size_t i = 0; i < 16; ++i)
    if(res[i] != quine[i])
      return false;

  return true;
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