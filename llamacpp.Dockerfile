# Use a lean Python base image
FROM python:3.11-slim
# version='0.4'
# Install build tools and Vulkan loaders required for compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    pkg-config \
    libvulkan-dev \
    vulkan-tools \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy and install Python requirements
COPY llamacpp_requirements.txt .

# VITAL: Ensure this line exists to copy your config file
COPY litellm_config.yaml .

# CRITICAL: Set environment variables to force a Vulkan build for llama-cpp-python
ENV CMAKE_ARGS="-DLLAMA_VULKAN=on"
ENV FORCE_CMAKE=1

# Install the python packages, forcing a build from source
RUN pip install --no-cache-dir -r llamacpp_requirements.txt

# Copy the startup script and make it executable
COPY llamacpp_start_server.sh .
RUN chmod +x llamacpp_start_server.sh

# Expose the port the server will run on
EXPOSE 4000

# Command to run the server on container start
CMD ["./llamacpp_start_server.sh"]