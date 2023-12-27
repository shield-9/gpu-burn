ifneq ("$(wildcard /usr/bin/nvcc)", "")
CUDAPATH ?= /usr
else ifneq ("$(wildcard /usr/local/cuda/bin/nvcc)", "")
CUDAPATH ?= /usr/local/cuda
endif

IS_JETSON   ?= $(shell if grep -Fwq "Jetson" /proc/device-tree/model 2>/dev/null; then echo true; else echo false; fi)
NVCC        :=  ${CUDAPATH}/bin/nvcc
CCPATH      ?=

override CFLAGS   ?=
override CFLAGS   += -O3
override CFLAGS   += -Wno-unused-result
override CFLAGS   += -I${CUDAPATH}/include
override CFLAGS   += -std=c++11
override CFLAGS   += -DIS_JETSON=${IS_JETSON}

override LDFLAGS  ?=
override LDFLAGS  += -lcuda
override LDFLAGS  += -L${CUDAPATH}/lib64
override LDFLAGS  += -L${CUDAPATH}/lib64/stubs
override LDFLAGS  += -L${CUDAPATH}/lib
override LDFLAGS  += -L${CUDAPATH}/lib/stubs
override LDFLAGS  += -Wl,-rpath=${CUDAPATH}/lib64
override LDFLAGS  += -Wl,-rpath=${CUDAPATH}/lib
override LDFLAGS  += -lcublas
override LDFLAGS  += -lcudart

COMPUTE      ?= 50
COMPUTES     ?= ${COMPUTE}
CUDA_VERSION ?= 11.8.0
IMAGE_DISTRO ?= ubi8

override NVCCFLAGS ?=
override NVCCFLAGS += -I${CUDAPATH}/include
override NVCCFLAGS += -arch=compute_$(subst .,,${COMPUTE})

IMAGE_NAME ?= gpu-burn

SHELL=/bin/bash
.ONESHELL:
.PHONY: clean

gpu_burn: gpu_burn-drv.o compare.ptx
	g++ -o $@ $< -O3 ${LDFLAGS}

universal:
	@for compute in $(COMPUTES); do
		compute=$${compute//./}
		$(MAKE) COMPUTE=$${compute}
		mkdir -p bin/cc$${compute}
		mv gpu_burn compare.ptx bin/cc$${compute}
	done

%.o: %.cpp
	g++ ${CFLAGS} -c $<

%.ptx: %.cu
	PATH="${PATH}:${CCPATH}:." ${NVCC} ${NVCCFLAGS} -ptx $< -o $@

clean:
	$(RM) *.ptx *.o gpu_burn

image:
	docker build --build-arg CUDA_VERSION=${CUDA_VERSION} --build-arg IMAGE_DISTRO=${IMAGE_DISTRO} -t ${IMAGE_NAME} .
