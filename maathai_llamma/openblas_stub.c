// Minimal OpenBLAS stub for testing
// This allows the build to proceed but provides no acceleration
// Replace with actual OpenBLAS library for production use

#include <stdio.h>

// Stub functions
void cblas_sgemm() { printf("OpenBLAS stub: cblas_sgemm\n"); }
void cblas_dgemm() { printf("OpenBLAS stub: cblas_dgemm\n"); }
void cblas_sgemv() { printf("OpenBLAS stub: cblas_sgemv\n"); }
void cblas_dgemv() { printf("OpenBLAS stub: cblas_dgemv\n"); }
