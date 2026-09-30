#!/usr/bin/env bash
# Usage: source scripts/hello.sh && hello_build_image

# Container binary to use (docker or podman)
CONTAINER_BIN="podman"
# Image name for the hello project (include registry so it doesn't default to localhost/)
HELLO_IMAGE="docker.io/pbertoni/hello-vscode-docker:latest"


function _hello_git_root() {
    git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel
}


function _hello_docker_run() {
    local gitRoot
    gitRoot="$(_hello_git_root)" || return 1

    # Determine if the terminal supports interactive mode
    local tty=()
    [[ -t 0 && -t 1 ]] && tty=(-it)

    local userArgs="--userns=keep-id"
    [[ ${CONTAINER_BIN} == docker ]] && \
        userArgs="--user "$(id -u):$(id -g)""

    set -x
    "${CONTAINER_BIN}" run --rm "${tty[@]}" \
        ${userArgs} \
        -v "${gitRoot}:/workspaces" \
        -w /workspaces \
        "$@"
    { set +x; } 2> /dev/null
}


function hello_build_image() {
    local gitRoot
    gitRoot="$(_hello_git_root)" || return 1

    set -x
    "${CONTAINER_BIN}" build \
        -t "${HELLO_IMAGE}" \
        -f "${gitRoot}/scripts/hello.Dockerfile" \
        "${gitRoot}/scripts"
    { set +x; } 2> /dev/null

    echo "Built image: ${HELLO_IMAGE}"
    "${CONTAINER_BIN}" images --filter "reference=${HELLO_IMAGE}"
}


function hello_push_image() {
    set -x
    "${CONTAINER_BIN}" push "${HELLO_IMAGE}"
    { set +x; } 2> /dev/null
}


function hello_build_project() {
    _hello_docker_run "${HELLO_IMAGE}" \
        bash -c "cmake -S /workspaces -B /workspaces/build && cmake --build /workspaces/build"
    echo "Built project, run hello_run_cxx to execute the C++ binary"
}

function hello_run_py() {
    _hello_docker_run -p 4840:4840 "${HELLO_IMAGE}" \
        python3 -m hello.main "$@"
}

function hello_run_cxx() {
    _hello_docker_run "${HELLO_IMAGE}" \
        /workspaces/build/hello "${@:-/workspaces/src/hello.xml}"
}


if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  echo_red "This is a library of functions. Source it instead of executing it."
  exit 1
else
  echo "Type 'hello_' and tabulate to discover new functions"
fi
