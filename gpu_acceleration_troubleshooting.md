# Llama.cpp Server GPU Acceleration Troubleshooting Guide

**Objective:** Configure the `llama-cpp-python` server to utilize the AMD Radeon RX Vega M GH GPU for model offloading.

**System:**
*   **CPU:** Intel(R) Core(TM) i7-8809G
*   **GPU:** ATI Polaris 22 XT [Radeon RX Vega M GH]
*   **Driver:** `amdgpu`
*   **Environment:** Docker Container

---

## Investigation Log

This document tracks the steps taken to diagnose and resolve issues with GPU acceleration.

### Step 1: Verify GPU Visibility in Container

*   **Action:** Check if the GPU device is accessible inside the Docker container. This is typically done by passing the `--device=/dev/dri` flag to the `docker run` command.
*   **Test:** `ls /dev/dri` inside the container.
*   **Result:** **`SUCCESS`**. The device is visible inside the container.

### Step 2: Verify Build Environment and Dependencies

*   **Action:** Check for issues with the build environment.
*   **Test:** A full disk (`/media/data`) was causing errors that appeared to be related to `apt` GPG keys.
*   **Result:** **`RESOLVED`**. The disk space issue was fixed, and the environment is now stable.

### Step 3: Rebuild `llama-cpp-python` with Vulkan Support

*   **Status:** **`IN PROGRESS`**
*   **Analysis:** The current logs (`llamacpp-vulkan-cblast_logs.txt`) show that all 32 layers of the model are loaded onto the CPU. This indicates that `llama-cpp-python` was likely installed without GPU support compiled in. A standard `pip install llama-cpp-python` will not include the necessary backends for AMD GPU acceleration.
*   **Action:** Re-install `llama-cpp-python` from source with the correct flags to enable the Vulkan backend, which is suitable for your AMD GPU.
*   **Findings:**
    *   Vulkan SDK was installed at `/app/1.3.283.0/` but binaries are in `/app/1.3.283.0/x86_64/`
    *   `vulkaninfo` confirms AMD Radeon RX Vega M GH GPU is detected after installing `mesa-vulkan-drivers`
    *   Rebuilt llama-cpp-python multiple times but Vulkan backend not being used
    *   Need to rebuild Docker image with proper Vulkan runtime drivers included from the start

#### **Instructions:**

1.  **Uninstall Existing Version:**
    Ensure a clean slate by removing the current installation.
    ```bash
    pip uninstall llama-cpp-python -y
    ```

2.  **Install with Vulkan Backend:**
    Use the `CMAKE_ARGS` environment variable to instruct the build process to include Vulkan support. The build will use the Vulkan SDK to compile the necessary components.
    ```bash
    CMAKE_ARGS="-DLLAMA_VULKAN=on" pip install --force-reinstall --no-cache-dir llama-cpp-python
    ```

3.  **Verify Installation:**
    After installation, the build log should indicate that Vulkan was detected and used.

### Step 4: Run Server with GPU Offloading Arguments

*   **Status:** **`PENDING`**
*   **Analysis:** To utilize the GPU-enabled build, you must explicitly tell the server to offload model layers to the GPU.
*   **Action:** Start the `llama-cpp-python` server using the `n_gpu_layers` argument.

#### **Instructions:**

1.  **Start the Server:**
    Set `n_gpu_layers` to a number greater than 0. A good starting point is to offload all layers (`-1`) and let the library manage them.
    ```bash
    python3 -m llama_cpp.server --model /models/Phi-3-mini-4k-instruct-q4.gguf --n_gpu_layers -1
    ```

2.  **Check the Logs:**
    Observe the server's startup logs. You should now see messages indicating that layers are being offloaded to the GPU. The log entries `layer ... assigned to device CPU` should change to show a GPU device.

---

**Current Status (2025-11-19):**

### Step 5: Vulkan Compilation Issues

*   **Status:** **`BLOCKED`**
*   **Issue:** llama-cpp-python (v0.3.16) Vulkan backend compilation fails due to cooperative matrix feature incompatibility
*   **Error:** `VkPhysicalDeviceCooperativeMatrixFeaturesKHR` not declared - expects NV variant instead
*   **Root Cause:** Vulkan SDK 1.3.283 and system Vulkan 1.3.239 headers don't include KHR cooperative matrix extensions
*   **Attempted Fixes:**
    *   Added mesa-vulkan-drivers, vulkan-tools, glslang-tools, libvulkan-dev
    *   Configured CMAKE with proper Vulkan paths and glslc executable
    *   Attempted to disable cooperative matrix with `-DGGML_VULKAN_DISABLE_COOPMAT2=ON` (did not work)

**Alternative Approaches:**
1.  Try CLBlast backend instead of Vulkan (OpenCL-based, may work with AMD)
2.  Use older llama-cpp-python version that doesn't require cooperative matrix
3.  Upgrade to newer Vulkan SDK with KHR cooperative matrix support

**Next Steps:**
1.  Test CLBlast backend as it's more compatible with older systems
2.  If CLBlast works, document and deploy
3.  Otherwise, consider older llama-cpp-python version or newer Vulkan SDK
