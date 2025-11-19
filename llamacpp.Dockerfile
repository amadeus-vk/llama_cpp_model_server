# Start from a clean Debian base image
# version="1.10"
FROM debian:bookworm

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install dependencies including Vulkan runtime and development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    wget \
    build-essential \
    cmake \
    apt-utils \
    file \
    mesa-vulkan-drivers \
    vulkan-tools \
    glslang-tools \
    libvulkan-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up the working directory and install the Vulkan SDK
WORKDIR /app
RUN wget https://sdk.lunarg.com/sdk/download/1.3.283.0/linux/vulkan-sdk-1.3.283.0-x86_64.tar.gz -O vulkan-sdk.tar.gz
RUN file vulkan-sdk.tar.gz
RUN tar -xJf vulkan-sdk.tar.gz
RUN rm vulkan-sdk.tar.gz

# --- Compile llama-cpp-python ---
# Copy the requirements file
COPY llamacpp_requirements.txt .

# Install the necessary libraries and compile llama-cpp-python with Vulkan flags
RUN VULKAN_SDK_PATH=/app/1.3.283.0/x86_64 && \
    CMAKE_ARGS="-DGGML_VULKAN=ON -DVulkan_INCLUDE_DIRS=$VULKAN_SDK_PATH/include -DVulkan_LIBRARIES=$VULKAN_SDK_PATH/lib/libvulkan.so" \
    pip3 install \
        --no-cache-dir \
        --break-system-packages \
        --verbose \
        -r llamacpp_requirements.txt

# --- Set Final Environment for Runtime ---
ENV VULKAN_SDK_PATH /app/1.3.283.0/x86_64
ENV PATH $VULKAN_SDK_PATH/bin:$PATH
ENV LD_LIBRARY_PATH $VULKAN_SDK_PATH/lib:$LD_LIBRARY_PATH
ENV VK_LAYER_PATH $VULKAN_SDK_PATH/etc/vulkan/explicit_layer.d

# Expose the port and run the server
EXPOSE 4000
CMD ["/usr/bin/python3", "-m", "llama_cpp.server"]
