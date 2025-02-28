# Use a specific base image; adjust as needed
FROM rocm/dev-almalinux-8:6.3.3-complete AS base-amd64
RUN yum install -y yum-utils \
    && yum-config-manager --add-repo https://dl.rockylinux.org/vault/rocky/8.5/AppStream/\$basearch/os/ \
    && rpm --import https://dl.rockylinux.org/pub/rocky/RPM-GPG-KEY-Rocky-8 \
    && dnf install -y yum-utils ccache gcc-toolset-10-gcc gcc-toolset-10-gcc-c++ \
    && yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
ENV PATH=/opt/rh/gcc-toolset-10/root/usr/bin:$PATH

FROM base-amd64 AS base
ARG CMAKEVERSION=3.31.2
RUN curl -fsSL https://github.com/Kitware/CMake/releases/download/v${CMAKEVERSION}/cmake-${CMAKEVERSION}-linux-x86_64.tar.gz | tar xz -C /usr/local --strip-components 1
COPY CMakeLists.txt CMakePresets.json .
COPY ml/backend/ggml/ggml ml/backend/ggml/ggml

# Additional build stages for CPU, CUDA, etc.
# ...

FROM ubuntu:20.04
RUN apt-get update \
    && apt-get install -y ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
COPY --from=base /bin/ollama /usr/bin
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
COPY --from=base /lib/ollama /usr/lib/ollama
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_VISIBLE_DEVICES=all
ENV OLLAMA_HOST=0.0.0.0:11434
EXPOSE 11434
ENTRYPOINT ["/usr/bin/ollama"]
CMD ["serve"]