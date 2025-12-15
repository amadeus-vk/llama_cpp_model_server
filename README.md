# Llama.cpp Model Server

## Purpose

This project provides a Dockerized llama.cpp server with GPU acceleration support for running large language models (LLMs) efficiently. The server is designed to:

- Serve GGUF-format language models via an OpenAI-compatible API
- Utilize AMD Radeon GPU acceleration for improved inference performance
- Run in a containerized environment for easy deployment and isolation
- Support multiple model formats and sizes with configurable layer offloading

## Current Status

The server is currently configured to run the Phi-3-mini-4k-instruct model in Q4 quantization format. GPU acceleration via Vulkan backend is under development (see [gpu_acceleration_troubleshooting.md](gpu_acceleration_troubleshooting.md) for current progress and issues).

## System Requirements

- **CPU**: Intel Core i7-8809G (or equivalent)
- **GPU**: AMD Radeon RX Vega M GH (or compatible AMD GPU with amdgpu driver)
- **Docker**: Recent version with GPU device passthrough support
- **Storage**: Sufficient space for GGUF models (varies by model size)

## Quick Start

### Building the Image

```bash
docker build -t llamacpp-server-final -f llamacpp.Dockerfile .
```

### Running the Container

```bash
docker run -d \
  --name llamacpp-vulkan-cblast \
  --device=/dev/dri:/dev/dri \
  -v /media/data/gguf-models:/models:ro \
  -p 4000:8080 \
  -e VULKAN_SDK_PATH=/app/1.3.283.0/x86_64 \
  -e LD_LIBRARY_PATH=/app/1.3.283.0/x86_64/lib:/lib \
  -e VK_LAYER_PATH=/app/1.3.283.0/x86_64/etc/vulkan/explicit_layer.d \
  --network agent_network \
  llamacpp-server-final \
  /usr/bin/python3 -m llama_cpp.server \
    --model /models/Phi-3-mini-4k-instruct-q4.gguf \
    --n_gpu_layers -1 \
    --host 0.0.0.0 \
    --port 8080
```

Or using docker-compose:

```bash
docker compose up -d
```

## Configuration

Key configuration files:

- **docker-compose.yaml**: Service definition with environment variables and volume mounts
- **llamacpp.Dockerfile**: Multi-stage build with Vulkan SDK and llama-cpp-python
- **llamacpp_requirements.txt**: Python dependencies including llama-cpp-python and litellm

### Environment Variables

- `MODEL`: Path to the GGUF model file inside the container
- `N_GPU_LAYERS`: Number of layers to offload to GPU (-1 for automatic/all layers)
- `PORT`: Internal server port (default: 8080)
- `HOST`: Bind address (default: 0.0.0.0)
- `VULKAN_SDK_PATH`: Path to Vulkan SDK installation
- `LD_LIBRARY_PATH`: Library search path including Vulkan libraries
- `VK_LAYER_PATH`: Vulkan validation layer path

## API Usage

The server exposes an OpenAI-compatible API endpoint:

```bash
curl http://localhost:4000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Phi-3-mini-4k-instruct-q4",
    "prompt": "Hello, how are you?",
    "max_tokens": 100
  }'
```

## Documentation

- **[gpu_acceleration_troubleshooting.md](gpu_acceleration_troubleshooting.md)**: Detailed troubleshooting guide for GPU acceleration issues
- **[system_specs.md](system_specs.md)**: System specifications and hardware information
- **[~/Warp/mcp_servers_reference.md](../../../Warp/mcp_servers_reference.md)**: MCP server configurations for AI agent integration

## Development Notes

### GPU Acceleration Status

Currently working on enabling Vulkan-based GPU acceleration. The main challenge is compatibility between:
- llama-cpp-python v0.3.16 Vulkan backend requirements
- Available Vulkan SDK and driver versions
- AMD Radeon RX Vega M GH hardware capabilities

See [gpu_acceleration_troubleshooting.md](gpu_acceleration_troubleshooting.md) for the full investigation log and next steps.

### Alternative Backends

If Vulkan proves incompatible, alternative GPU acceleration options include:
1. **CLBlast** (OpenCL-based, better compatibility with older AMD GPUs)
2. **Older llama-cpp-python versions** (without cooperative matrix requirements)
3. **Newer Vulkan SDK** (with KHR cooperative matrix extension support)

## Contributing

When making changes:
1. Update relevant documentation files
2. Test container build and runtime
3. Document any GPU-related findings in the troubleshooting guide
4. Commit changes with descriptive messages

## License

[Add your license information here]

## References

- **Warp AI Agent Documentation**: See `~/Warp/mcp_servers_reference.md` for MCP server integration details
- **llama.cpp**: [GitHub Repository](https://github.com/ggerganov/llama.cpp)
- **llama-cpp-python**: [GitHub Repository](https://github.com/abetlen/llama-cpp-python)
