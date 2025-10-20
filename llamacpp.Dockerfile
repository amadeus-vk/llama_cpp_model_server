# version='0.7'
# Use a more complete base image that includes more system libraries
FROM python:3.11-bookworm

# Prevents prompts from apt during installation
ENV DEBIAN_FRONTEND=noninteractive

# A slightly more robust command for installing packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/**

WORKDIR /app

# Copy and install requirements
COPY llamacpp_requirements.txt .
RUN pip install --no-cache-dir -r llamacpp_requirements.txt

# Copy the rest of the application files
COPY litellm_config.yaml .
COPY llamacpp_start_server.sh .
RUN chmod +x llamacpp_start_server.sh

EXPOSE 4000
CMD ["./llamacpp_start_server.sh"]