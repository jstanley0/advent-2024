
#include <iostream>
#include <fstream>
#include <vector>
#include <windows.h>

constexpr size_t PRICE_TABLE_SIZE = 2000;

__global__ void hash(uint32_t *secrets, uint32_t secrets_sz, int8_t *price_table_base) {
    unsigned long idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= secrets_sz)
        return;
    int8_t* start = price_table_base + idx * PRICE_TABLE_SIZE;
    int8_t* end = start + PRICE_TABLE_SIZE;
    uint32_t n = secrets[idx];
    for (int8_t* i = start; i < end; ++i) {
        n = ((n << 6) ^ n) & 0xFFFFFF;
        n = ((n >> 5) ^ n);
        n = ((n << 11) ^ n) & 0xFFFFFF;
        *i = n % 10;
    }
}

__global__ void search(int8_t *price_table_base, uint32_t secrets_sz, int32_t *best) {
    int n = blockIdx.x * blockDim.x + threadIdx.x;
    if (n > 19 * 19 * 19 * 19)
        return;

    int d0 = (n / (19 * 19 * 19)) - 9;
    int d1 = ((n / (19 * 19)) % 19) - 9;
    int d2 = ((n / 19) % 19) - 9;
    int d3 = (n % 19) - 9;
    
    int32_t bid = 0;
    int8_t* prices = price_table_base;
    for (uint32_t m = 0; m < secrets_sz; ++m) {
        for (int i = 1; i < PRICE_TABLE_SIZE - 4; ++i) {
            if (prices[i] - prices[i - 1] == d0 &&
                prices[i + 1] - prices[i] == d1 &&
                prices[i + 2] - prices[i + 1] == d2 &&
                prices[i + 3] - prices[i + 2] == d3)
            {
                bid += prices[i + 3];
                break;
            }
        }
        prices += PRICE_TABLE_SIZE;
    }
    atomicMax(best, bid);
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        std::cerr << "usage: " << argv[0] << " infile" << std::endl;
        return 1;
    }

    LARGE_INTEGER before;
    QueryPerformanceCounter(&before);

    std::ifstream infile(argv[1]);
    std::vector<uint32_t> secrets;
    uint32_t n;
    while (infile >> n) {
        secrets.push_back(n);
    }

    uint32_t* deviceSecrets;
    cudaMalloc(&deviceSecrets, secrets.size() * sizeof(uint32_t));
    cudaMemcpy(deviceSecrets, secrets.data(), secrets.size() * sizeof(uint32_t), cudaMemcpyHostToDevice);

    int8_t* devicePriceTable;
    cudaMalloc(&devicePriceTable, secrets.size() * PRICE_TABLE_SIZE * sizeof(int8_t));
    hash<<<(secrets.size() + 255) / 256, 256>>>(deviceSecrets, secrets.size(), devicePriceTable);

    int32_t* deviceBest;
    cudaMalloc(&deviceBest, sizeof(int32_t));
    cudaMemset(deviceBest, 0, sizeof(int32_t));
    search<<<510, 256>>>(devicePriceTable, secrets.size(), deviceBest);
    int32_t best;
    cudaMemcpy(&best, deviceBest, sizeof(int32_t), cudaMemcpyDeviceToHost);
    std::cout << best << std::endl;

    cudaFree(deviceBest);
    cudaFree(devicePriceTable);
    cudaFree(deviceSecrets);

    LARGE_INTEGER after;
    LARGE_INTEGER frequency;
    QueryPerformanceCounter(&after);
    QueryPerformanceFrequency(&frequency);
    printf("Elapsed time: %.3f seconds\n", (double)(after.QuadPart - before.QuadPart) / frequency.QuadPart);

    return 0;
}
