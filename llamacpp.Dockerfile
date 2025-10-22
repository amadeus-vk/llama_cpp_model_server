# Start from a clean Debian base image
# version="1.10"
FROM debian:bookworm

# Set DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisite packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set up the working directory and install the Vulkan SDK
WORKDIR /app
RUN wget https://sdk.lunarg.com/sdk/download/1.3.283.0/linux/vulkan-sdk-1.3.283.0-x86_64.tar.gz -O vulkan-sdk.tar.gz && \
    tar -xJf vulkan-sdk.tar.gz && \
    rm vulkan-sdk.tar.gz

# --- Compile and Install llama-cpp-python ---
RUN VULKAN_SDK_PATH=$(find /app -name "vulkansdk*" -type d) && \
    CMAKE_ARGS="-DLLAMA_VULKAN=on -DVulkan_INCLUDE_DIRS=$VULKAN_SDK_PATH/include -DVulkan_LIBRARIES=$VULKAN_SDK_PATH/lib/libvulkan.so" \
    pip3 install \
        --no-cache-dir \
        --break-system-packages \
        "llama-cpp-python[server]" # Install with 'server' extras

# --- Set Final Environment for Runtime ---
ENV VULKAN_SDK_PATH /app/vulkansdk*
ENV PATH $VULKAN_SDK_PATH/bin:$PATH
ENV LD_LIBRARY_PATH $VULKAN_SDK_PATH/lib:$LD_LIBRARY_PATH
ENV VK_LAYER_PATH $VULKAN_SDK_PATH/etc/vulkan/explicit_layer.d

# Expose the port the server will run on
EXPOSE 4000