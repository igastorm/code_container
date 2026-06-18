# code-container

[![Build and Push to GHCR (main)](https://github.com/igastorm/code-container/actions/workflows/build-and-push.yml/badge.svg?branch=main)](https://github.com/igastorm/code-container/actions/workflows/build-and-push.yml)
[![Test and Auto PR (test)](https://github.com/igastorm/code-container/actions/workflows/test-and-pr.yml/badge.svg?branch=test)](https://github.com/igastorm/code-container/actions/workflows/test-and-pr.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Container](https://img.shields.io/badge/GHCR-ghcr.io%2Figastorm%2Fcode-container-2496ED?logo=docker&logoColor=white)](https://github.com/igastorm/code-container/pkgs/container/code-container)

A portable, lightweight development environment that integrates **code-server** (VS Code in the browser) with a fully native **LLVM toolchain**.

This container provides a clean and secure coding environment for C++ and Python 3 without cluttering your host operating system.

---

## Key Features

- **Native LLVM Stack:** Pre-configured to use `clang++`, `lld`, and `libc++` natively, bypassing GCC/GNU toolchain dependencies.
- **Permission Sync (Zero-Config):** Automatically matches the container user's UID/GID with the host directory's owner, eliminating host-container file permission issues.
- **Secure by Default:** Designed to run with a read-only root filesystem (`--read-only`) to reduce the attack surface.

---

## Included Tools

- **C++:** Clang, lld, lldb, libc++, clangd, clang-format, clang-tidy.
- **Python 3:** python3, pip, venv, Ruff.
- **Build Tools:** CMake, Ninja, Git.

---

## Quick Start

### Method:

```
mkdir -p workspace
docker run -d \
  --name devenv \
  --read-only \
  --tmpfs /tmp:exec \
  -e LOG=ON \ # or -e LOG=OFF; If omitted, LOG=ON
  -v $(pwd)/workspace:/home \
  -p 3000:3000 \
  ghcr.io/igastorm/code-container:latest
```

After starting, open your browser and navigate to **`http://localhost:3000`** to start coding.

---

## License

- The scripts, Dockerfiles, and configuration files in this repository are licensed under the **MIT License**.
- Third-party software components bundled inside the distributed container image (including but not limited to Clang/LLVM, code-server, Python, GoogleTest, and various VS Code extensions) are governed by their respective original upstream licenses. Please respect and adhere to their respective license terms.
