# hello-vscode-docker

A small example of using **Docker/Podman as your development environment**.

You don't install compilers, libraries or Python packages on your machine. Everything lives inside a Docker/Podman **image**.
Your source code stays on your machine and is *mounted* into a short-lived **container** whenever you build or run something.

The repo contains two tiny "hello" programs:

- a **C++** program (built with CMake) that opens an XML file with [libxml++](https://libxmlplusplus.github.io/libxmlplusplus/)
- a **Python** program that starts an [OPC UA](https://opcfoundation.org/about/opc-technologies/opc-ua/) server with [asyncua](https://github.com/FreeOpcUa/opcua-asyncio)

## Docker/Podman in 30 seconds

| Term | What it means here |
|------|--------------------|
| **Dockerfile** | A recipe listing the steps to prepare an environment: start from Debian, install packages… |
| **Image** | The result of running the recipe: a frozen snapshot of that environment. You build it once. |
| **Container** | A running instance of an image. We start one per command and throw it away afterwards (`--rm`). |
| **Volume mount** (`-v`) | Makes a folder on your machine visible inside the container. Here the repo appears as `/workspace`. |
| **Port mapping** (`-p`) | Forwards a port from your machine into the container. Here `4840` is used for OPC UA. |

Since the repo is mounted and not copied, build outputs written to `/workspace/build` inside the container end up in `build/` on your machine.

## Project structure

```
.
├── CMakeLists.txt          # CMake build description for the C++ part
├── src/                    # C++ sources
│   ├── hello.h / hello.cpp #   hello(path): parses an XML file, returns its root node name
│   ├── main.cpp            #   executable: prints the root node of the file given as argument
│   └── hello.xml           #   sample XML file
├── hello/                  # Python package
│   ├── __init__.py         #   package version
│   └── main.py             #   OPC UA server exposing a Hello/Counter variable
├── scripts/
│   ├── hello.Dockerfile    # recipe for the image (debian:bookworm + libxml++ + asyncua)
│   ├── requirements.txt    # Python dependencies installed into the image with pip
│   └── hello.sh            # helper functions wrapping the docker/podman commands (see below)
└── build/                  # CMake build directory (created by hello_build_project, git-ignored)
```

## Prerequisites

See [Docker Development Cycle](https://docs.google.com/document/d/1kKp6K6ooHuQC6vhndg3YbnAnZBSIVdObCeH4A69btLo/edit?usp=sharing) technical document.
Check that it works:

```bash
podman run --rm hello-world
```

## Getting started: source `hello.sh`

[scripts/hello.sh](scripts/hello.sh) is a **library of shell functions**, not a program. You have to **source** it so the functions get loaded into your current shell:

```bash
cd hello-vscode-docker
source scripts/hello.sh      # or: . scripts/hello.sh
```

Executing it with `./scripts/hello.sh` does not work, because the functions would disappear when the script exits. Once it is sourced, type `hello_` and press <kbd>Tab</kbd> to list the available functions. You need to source it again in every new terminal.

### The `hello_*` functions

- **`hello_build_image`**: Builds the Docker/Podman image `pbertoni/hello-vscode-docker:latest` from [scripts/hello.Dockerfile](scripts/hello.Dockerfile). It installs the C++ toolchain, CMake, `libxml++2.6-dev`, Python, and the packages from [scripts/requirements.txt](scripts/requirements.txt). Run it once at the start, and again whenever you change the Dockerfile or `requirements.txt`.
- **`hello_build_project`**: Starts a throw-away container that configures and compiles the C++ project with CMake. The output goes to `build/` at the root of the repo.
- **`hello_run_cxx [file.xml]`**: Runs the compiled `build/hello` executable inside a container. Without an argument it parses [src/hello.xml](src/hello.xml). Paths must be as seen *inside* the container, e.g. `/workspace/src/hello.xml`.
- **`hello_run_py`**: Starts the OPC UA server from [hello/main.py](hello/main.py) inside a container and publishes port `4840`. OPC UA clients on your machine can connect to `opc.tcp://localhost:4840/hello/server/`. Stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd>.

Every `hello_run_*` / `hello_build_project` call prints the full `docker run` command it executes. Read it to learn what's going on.

### Typical session

```bash
source scripts/hello.sh
hello_build_image       # once
hello_build_project     # after each C++ change
hello_run_cxx           # -> Hello Docker, root node: hello
hello_run_py            # Ctrl+C to stop
```

## Under the hood

All functions except `hello_build_image` go through one helper that runs roughly:

```bash
podman run --rm -it \
    -v "<repo root>:/workspace" \
    -w /workspace \
    <image> <command>
```

- `--rm`: delete the container when the command finishes
- `-it`: interactive terminal, so colours and <kbd>Ctrl</kbd>+<kbd>C</kbd> work. It's added only when you run from a real terminal.
- `-v` / `-w`: mount the repo as `/workspace` and start there

You can override the image name with the `HELLO_IMAGE` environment variable before sourcing, e.g. `HELLO_IMAGE=my-hello:dev source scripts/hello.sh`.

## Useful Docker commands

```bash
podman images                 # list images on your machine
podman ps                     # list running containers
podman stop <container-id>    # stop a running container
podman image rm hello-vscode-docker:latest   # delete the image
```
