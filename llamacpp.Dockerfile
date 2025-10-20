# version='1.0'
# Start from a clean Debian base image as recommended by the guide
FROM debian:bookworm

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisite packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# --- Install Vulkan SDK (as per the guide) ---
WORKDIR /app
RUN wget https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.gz
RUN tar -xzf vulkan-sdk.tar.gz
# Set environment variables for the Vulkan SDK
ENV VULKAN_SDK=/app/$(ls | grep vulkansdk)
ENV PATH=$VULKAN_SDK/bin:$PATH
ENV LD_LIBRARY_PATH=$VULKAN_SDK/lib:$LD_LIBRARY_PATH
ENV VK_LAYER_PATH=$VULKAN_SDK/etc/vulkan/explicit_layer.d

# --- Compile and install llama-cpp-python ---
# First, install the Python libraries we need
COPY llamacpp_requirements.txt .
RUN pip3 install --no-cache-dir -r llamacpp_requirements.txt

# Now, compile llama-cpp-python with the Vulkan flags
# This tells the build script to use our newly installed Vulkan SDK
RUN CMAKE_ARGS="-DLLAMA_VULKAN=on -DVulkan_INCLUDE_DIRS=$VULKAN_SDK/include -DVulkan_LIBRARIES=$VULKAN_SDK/lib/libvulkan.so" \
    pip3 install --no-cache-dir --force-reinstall --upgrade llama-cpp-python

# --- Final Setup ---
# Copy our application files
COPY litellm_config.yaml .
COPY llamacpp_start_server.sh .
RUN chmod +x llamacpp_start_server.sh

# Expose the port and run the server
EXPOSE 4000
CMD ["./llamacpp_start_server.sh"]