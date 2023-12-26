ARG CUDA_VERSION=12.3.1
ARG CUDA_COMPUTE=9.0
ARG IMAGE_DISTRO=ubuntu22.04

FROM nvidia/cuda:${CUDA_VERSION}-devel-${IMAGE_DISTRO} AS builder

WORKDIR /build

COPY . /build/

RUN make COMPUTE=${CUDA_COMPUTE}

FROM nvidia/cuda:${CUDA_VERSION}-runtime-${IMAGE_DISTRO}

COPY --from=builder /build/gpu_burn /app/
COPY --from=builder /build/compare.ptx /app/

WORKDIR /app

CMD ["./gpu_burn", "7200"]
