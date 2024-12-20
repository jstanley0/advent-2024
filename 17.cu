
#include <stdio.h>
#include <windows.h>

#define CHECKS_PER_THREAD 16384ULL
#define THREADS_PER_BLOCK 1024
#define BLOCKS 256

__device__ bool check(uint64_t a) {
    uint64_t b, r = 0;
    while (a != 0) {
        b = (a & 7) ^ 1;
        b ^= (a >> b) ^ 4;
        a >>= 3;
        r = (r << 3) | b & 7;
    }
    return r == 02411754603145530ULL;
}

__global__ void search(uint64_t batch_start, uint64_t* result) {
    unsigned long idx = blockIdx.x * blockDim.x + threadIdx.x;

    uint64_t range_start = batch_start + idx * CHECKS_PER_THREAD;
    uint64_t range_end = range_start + CHECKS_PER_THREAD;

    for (uint64_t i = range_start; i < range_end; ++i) {
        if (check(i)) {
            atomicMin(result, i);
            break;
        }
    }
}

__managed__ uint64_t result = ULLONG_MAX;

int main()
{
    LARGE_INTEGER before;
    QueryPerformanceCounter(&before);

    uint64_t a = 201972175280682ULL;
    for(;;) {
        search<<<BLOCKS, THREADS_PER_BLOCK>>>(a, &result);
        cudaDeviceSynchronize();
        if (result != ULLONG_MAX)
            break;

        a += BLOCKS * THREADS_PER_BLOCK * CHECKS_PER_THREAD;
        putchar('.');
    } 
    printf("\n%llx (%lld)\n", result, result);

    LARGE_INTEGER after;
    LARGE_INTEGER frequency;
    QueryPerformanceCounter(&after);
    QueryPerformanceFrequency(&frequency);
    printf("Elapsed time: %.3f seconds\n", (double)(after.QuadPart - before.QuadPart) / frequency.QuadPart);

    return 0;
}
