#include <OpenCL/cl.h>
#include <iostream>
#include <fstream>
#include <vector>

constexpr size_t PRICE_TABLE_SIZE = 2000;

void CHECK_ERROR(cl_int err, const char *msg) {
    if (err != CL_SUCCESS) {
        fprintf(stderr, "%s: %d\n", msg, err);
        exit(1);
    }
}

size_t round_up(size_t size, size_t multiple_of = 256) {
    return ((size + multiple_of - 1) / multiple_of) * multiple_of;
}

const char* kernel_source = R"(
#define PRICE_TABLE_SIZE 2000

__kernel void hash(__global const int *secrets, int secrets_sz, __global char *price_table_base) {
    int idx = get_global_id(0);
    if (idx >= secrets_sz)
        return;
    __global char *start = price_table_base + idx * PRICE_TABLE_SIZE;
    __global char *end = start + PRICE_TABLE_SIZE;
    int n = secrets[idx];
    for (__global char *i = start; i < end; ++i) {
        n = ((n << 6) ^ n) & 0xFFFFFF;
        n = ((n >> 5) ^ n);
        n = ((n << 11) ^ n) & 0xFFFFFF;
        *i = n % 10;
    }
}

__kernel void search(__global char *price_table_base, int secrets_sz, volatile __global int *best) {
    uint n = get_global_id(0);
    if (n > 19 * 19 * 19 * 19)
        return;

    int d0 = (n / (19 * 19 * 19)) - 9;
    int d1 = ((n / (19 * 19)) % 19) - 9;
    int d2 = ((n / 19) % 19) - 9;
    int d3 = (n % 19) - 9;
    
    int bid = 0;
    __global char *prices = price_table_base;
    for (int m = 0; m < secrets_sz; ++m) {
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
    if (bid > *best) {
        printf("%d,%d,%d,%d -> %d\n", d0, d1, d2, d3, bid);
        atomic_max(best, bid);
    }
}
)";

int main(int argc, char **argv)
{
    if (argc < 2) {
        std::cerr << "usage: " << argv[0] << " infile" << std::endl;
        return 1;
    }

    std::ifstream infile(argv[1]);
    std::vector<cl_int> secrets;
    cl_int n;
    while (infile >> n) {
        secrets.push_back(n);
    }

    cl_int err;
    cl_platform_id platform;
    cl_device_id device;
    cl_context context;
    cl_command_queue queue;
    cl_program program;
    cl_kernel hash, search;

    err = clGetPlatformIDs(1, &platform, NULL);
    CHECK_ERROR(err, "Failed to get platform ID");
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);
    CHECK_ERROR(err, "Failed to get device ID");

    context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    CHECK_ERROR(err, "Failed to create context");
    queue = clCreateCommandQueue(context, device, 0, &err);
    CHECK_ERROR(err, "Failed to create command queue");

    program = clCreateProgramWithSource(context, 1, &kernel_source, NULL, &err);
    CHECK_ERROR(err, "Failed to create program");
    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        char log[1024];
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, sizeof(log), log, NULL);
        fprintf(stderr, "Build log: %s\n", log);
        exit(1);
    }

    hash = clCreateKernel(program, "hash", &err);
    CHECK_ERROR(err, "Failed to create kernel 'hash'");
    search = clCreateKernel(program, "search", &err);
    CHECK_ERROR(err, "Failed to create kernel 'search'");

    cl_event secrets_written{nullptr};
    cl_mem secrets_buf = clCreateBuffer(context, CL_MEM_READ_ONLY, secrets.size() * sizeof(cl_int), NULL, &err);
    CHECK_ERROR(err, "Failed to create GPU buffer for secrets");
    err = clEnqueueWriteBuffer(queue, secrets_buf, CL_TRUE, 0, secrets.size() * sizeof(cl_int), secrets.data(), 0, NULL, &secrets_written);
    CHECK_ERROR(err, "Failed to write secrets to GPU");

    cl_mem price_table_buf = clCreateBuffer(context, CL_MEM_READ_WRITE, secrets.size() * PRICE_TABLE_SIZE * sizeof(cl_char), NULL, &err);
    CHECK_ERROR(err, "Failed to create GPU buffer for price table");

    cl_int best = 0;
    cl_mem result_buf = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(cl_int), NULL, &err);
    CHECK_ERROR(err, "Failed to create buffer for result");
    cl_event result_initialized{nullptr};
    err = clEnqueueWriteBuffer(queue, result_buf, CL_TRUE, 0, sizeof(cl_int), &best, 0, NULL, &result_initialized);
    CHECK_ERROR(err, "Failed to write initial result value");

    err = clSetKernelArg(hash, 0, sizeof(cl_mem), &secrets_buf);
    CHECK_ERROR(err, "Failed to set secrets argument");
    cl_int secrets_sz = secrets.size();
    err = clSetKernelArg(hash, 1, sizeof(cl_int), &secrets_sz);
    CHECK_ERROR(err, "Failed to set secrets_sz argument");
    err = clSetKernelArg(hash, 2, sizeof(cl_mem), &price_table_buf);
    CHECK_ERROR(err, "Failed to set price_table_buf argument");

    size_t global_size = round_up(secrets.size(), 128), local_size = 128;
    cl_event hash_event{nullptr};
    err = clEnqueueNDRangeKernel(queue, hash, 1, NULL, &global_size, &local_size, 1, &secrets_written, &hash_event);
    CHECK_ERROR(err, "Failed to enqueue hash kernel");

    err = clSetKernelArg(search, 0, sizeof(cl_mem), &price_table_buf);
    CHECK_ERROR(err, "Failed to set price_table_buf argument");
    err = clSetKernelArg(search, 1, sizeof(cl_int), &secrets_sz);
    CHECK_ERROR(err, "Failed to set secrets_sz argument");
    err = clSetKernelArg(search, 2, sizeof(cl_mem), &result_buf);
    CHECK_ERROR(err, "Failed to set result_buf argument");

    size_t global_size_2 = round_up(19 * 19 * 19 * 19, 256), local_size_2 = 256;
    cl_event search_event{nullptr};
    cl_event search_prereqs[2] = { result_initialized, hash_event };
    err = clEnqueueNDRangeKernel(queue, search, 1, NULL, &global_size_2, &local_size_2, 2, search_prereqs, &search_event);
    CHECK_ERROR(err, "Failed to enqueue search kernel");

    err = clEnqueueReadBuffer(queue, result_buf, CL_TRUE, 0, sizeof(cl_int), &best, 1, &search_event, NULL);
    CHECK_ERROR(err, "Failed to read result value");
    std::cout << best << std::endl;

    clReleaseEvent(search_event);
    clReleaseEvent(hash_event);
    clReleaseEvent(result_initialized);
    clReleaseEvent(secrets_written);
    clReleaseMemObject(result_buf);
    clReleaseMemObject(price_table_buf);
    clReleaseMemObject(secrets_buf);
    clReleaseKernel(search);
    clReleaseKernel(hash);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    return best > 0 ? 0 : -1;
}
