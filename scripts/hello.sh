#!/usr/bin/env bash
# Usage: source scripts/hello.sh && hello_build_image

HELLO_IMAGE="${HELLO_IMAGE:-hello-vscode-docker:latest}"

_hello_git_root() {
    git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel
}

_hello_docker_run() {
    local gitRoot
    gitRoot="$(_hello_git_root)" || return 1

    # Determine if the terminal supports interactive mode
    local tty=()
    [[ -t 0 && -t 1 ]] && tty=(-it)

    set -x
    docker run --rm "${tty[@]}" \
        --user "$(id -u):$(id -g)" \
        -v "${gitRoot}:/workspace" \
        -w /workspace \
        "$@"
    { set +x; } 2> /dev/null
}

hello_build_image() {
    local gitRoot
    gitRoot="$(_hello_git_root)" || return 1

    docker build \
        -t "${HELLO_IMAGE}" \
        -f "${gitRoot}/scripts/hello.Dockerfile" \
        "${gitRoot}/scripts"

    echo "Built image: ${HELLO_IMAGE}"
    docker images --filter "reference=${HELLO_IMAGE}"
}

hello_build_project() {
    _hello_docker_run "${HELLO_IMAGE}" \
        bash -c "cmake -S /workspace -B /workspace/build && cmake --build /workspace/build"
    echo "Built project, run hello_run_cxx to execute the C++ binary"
}

hello_run_py() {
    _hello_docker_run -p 4840:4840 "${HELLO_IMAGE}" \
        python3 -m hello.main "$@"
}

hello_run_cxx() {
    _hello_docker_run "${HELLO_IMAGE}" \
        /workspace/build/hello "${@:-/workspace/src/hello.xml}"
}


if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  echo_red "This is a library of functions. Source it instead of executing it."
  exit 1
else
  echo "Type 'hello_' and tabulate to discover new functions"
fi
