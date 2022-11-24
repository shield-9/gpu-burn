FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 AS builder

WORKDIR /build

COPY . /build/

RUN make COMPUTE=9.0

FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

COPY --from=builder /build/gpu_burn /app/
COPY --from=builder /build/compare.ptx /app/

WORKDIR /app

CMD ["./gpu_burn", "7200"]
