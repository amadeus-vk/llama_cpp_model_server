# version='0.10'
# Use the official pre-built image with Vulkan support as our base
FROM ghcr.io/abetlen/llama-cpp-python:v0.2.62-vulkan
# Set the working directory
WORKDIR /app

# Install litellm and its proxy dependencies
RUN pip install "litellm[proxy]"

# Copy our configuration and startup script
COPY litellm_config.yaml .
COPY llamacpp_start_server.sh .
RUN chmod +x llamacpp_start_server.sh

# Expose the port and set the startup command
EXPOSE 4000
CMD ["./llamacpp_start_server.sh"]