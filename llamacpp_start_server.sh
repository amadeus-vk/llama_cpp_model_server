#!/bin/sh
version='0.7'
echo "🚀 ($version): Starting LiteLLM server ..."
echo "============ VERSION =============="
echo "       $(litellm --version)" 
echo "==================================="

echo "Serving all models found in the /models directory."

# Start LiteLLM proxy, binding to all interfaces on port 4000
# It will automatically discover and serve models from the /models directory
litellm --host 0.0.0.0 --port 4000