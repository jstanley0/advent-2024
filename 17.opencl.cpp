#include <OpenCL/cl.h>
#include <iostream>
#include <limits>
#include <stdlib.h>

#define CHECK_ERROR(err, msg) if (err != CL_SUCCESS) { fprintf(stderr, "%s\n", msg); exit(1); }

const char* kernel_source = R"(
__kernel void find_quine(
    __global unsigned long* result, // Output: first valid 'a'
    unsigned long start,            // Starting value of 'a'
    unsigned long chunk_size        // Number of values per thread
) {
    const unsigned long quine = 02411754603145530UL;
    unsigned long base = start + get_global_id(0) * chunk_size;

    for (unsigned long i = 0; i < chunk_size; ++i) {
        unsigned long a = base + i, b;
        unsigned long res = 0LL;
        while (a != 0) {
            b = (a & 7) ^ 1;
            b ^= (a >> b) ^ 4;
            res = (res << 3) | (b & 7);
            a >>= 3;
        }

        // atom_min would be better here, but the MacOS OpenCL implementation
        // doesn't support 64-bit atomic operations :(
        if (res == quine && base + i < *result) {
            *result = base + i;
            return;
        }
    }
}
)";

int main() {
    const unsigned long chunk_size = 100000; 
    const size_t global_size = 10240;
    const size_t local_size = 256;

    cl_int err;
    cl_platform_id platform;
    cl_device_id device;
    cl_context context;
    cl_command_queue queue;
    cl_program program;
    cl_kernel kernel;

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
    err = clBuildProgram(program, 1, &device, "-cl-std=CL2.0", NULL, NULL);
    if (err != CL_SUCCESS) {
        char log[1024];
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, sizeof(log), log, NULL);
        fprintf(stderr, "Build log: %s\n", log);
        exit(1);
    }
    kernel = clCreateKernel(program, "find_quine", &err);
    CHECK_ERROR(err, "Failed to create kernel");

    unsigned long start = 201972175280682UL;
    unsigned long result = std::numeric_limits<unsigned long>::max();

    cl_mem result_buf = clCreateBuffer(context, CL_MEM_READ_WRITE, sizeof(unsigned long), NULL, &err);
    CHECK_ERROR(err, "Failed to create buffer for result");
    err = clEnqueueWriteBuffer(queue, result_buf, CL_TRUE, 0, sizeof(unsigned long), &result, 0, NULL, NULL);
    CHECK_ERROR(err, "Failed to write initial result value");

    while (result == std::numeric_limits<unsigned long>::max()) {
        err = clSetKernelArg(kernel, 0, sizeof(unsigned long), &result_buf);
        CHECK_ERROR(err, "Failed to set result argument");
        err = clSetKernelArg(kernel, 1, sizeof(unsigned long), &start);
        CHECK_ERROR(err, "Failed to set start argument");
        err = clSetKernelArg(kernel, 2, sizeof(unsigned long), &chunk_size);
        CHECK_ERROR(err, "Failed to set chunk_size argument");

        err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &global_size, &local_size, 0, NULL, NULL);
        CHECK_ERROR(err, "Failed to enqueue kernel");

        err = clEnqueueReadBuffer(queue, result_buf, CL_TRUE, 0, sizeof(unsigned long), &result, 0, NULL, NULL);
        CHECK_ERROR(err, "Failed to read result value");

        std::cerr << "." << std::flush;
        start += global_size * chunk_size;
    }

    std::cout << result << std::endl;

    clReleaseMemObject(result_buf);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    return 0;
}

