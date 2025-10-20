# Start from a clean Debian base image
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

# Set up the working directory and install the Vulkan SDK
WORKDIR /app
RUN wget https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.gz
RUN tar -xzf vulkan-sdk.tar.gz

# --- Compile llama-cpp-python ---
# First, install the Python libraries we need (litellm)
COPY llamacpp_requirements.txt .
RUN pip3 install --no-cache-dir -r llamacpp_requirements.txt

# Now, compile llama-cpp-python with the Vulkan flags.
# All the path logic is handled safely inside this RUN command.
RUN VULKAN_SDK_PATH=$(find /app -name "vulkansdk*" -type d) && \
    CMAKE_ARGS="-DLLAMA_VULKAN=on -DVulkan_INCLUDE_DIRS=$VULKAN_SDK_PATH/include -DVulkan_LIBRARIES=$VULKAN_SDK_PATH/lib/libvulkan.so" \
    pip3 install \
        --no-cache-dir \
        --force-reinstall \
        --upgrade \
        llama-cpp-python

# --- Set Final Environment for the Running Container ---
# This sets the necessary paths for the application to find the Vulkan libraries at runtime.
ENV VULKAN_SDK_PATH /app/vulkansdk*
ENV PATH $VULKAN_SDK_PATH/bin:$PATH
ENV LD_LIBRARY_PATH $VULKAN_SDK_PATH/lib:$LD_LIBRARY_PATH
ENV VK_LAYER_PATH $VULKAN_SDK_PATH/etc/vulkan/explicit_layer.d

# --- Final Setup ---
# Copy our application files
COPY litellm_config.yaml .
COPY llamacpp_start_server.sh .
RUN chmod +x llamacpp_start_server.sh

# Expose the port and run the server
EXPOSE 4000
CMD ["./llamacpp_start_server.sh"]