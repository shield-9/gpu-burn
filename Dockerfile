ARG CUDA_VERSION=11.8.0
ARG CUDA_COMPUTE=9.0
ARG IMAGE_DISTRO=ubi8

FROM nvidia/cuda:${CUDA_VERSION}-devel-${IMAGE_DISTRO} AS builder

WORKDIR /build

COPY . /build/

RUN make COMPUTE=${CUDA_COMPUTE}

FROM nvidia/cuda:${CUDA_VERSION}-runtime-${IMAGE_DISTRO}

COPY --from=builder /build/gpu_burn /app/
COPY --from=builder /build/compare.ptx /app/

WORKDIR /app

CMD ["./gpu_burn", "60"]
