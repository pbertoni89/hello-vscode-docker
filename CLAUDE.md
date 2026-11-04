# CLAUDE.md

This repo is a **template** for running other projects in VS Code Dev Containers.
Keep changes generic and reusable; project-specific values are marked with `// TODO` in `.devcontainer/devcontainer.json`.

## Layout

- `scripts/Containerfile`: recipe for the image `docker.io/pbertoni/hello-vscode-docker:latest` (Debian bookworm, C++ toolchain, Python built from source + venv in `/opt/venv`).
- `scripts/hello.sh`: helper functions. It must be **sourced**, not executed: `source scripts/hello.sh && hello_build_image`.
- `.devcontainer/devcontainer.json`: uses the prebuilt image (`"image"`), not a `"build"` section.

## Container runtime

- The host runs **rootless Podman** (`CONTAINER_BIN="podman"` in `hello.sh`), not Docker. Docker is kept only as a fallback.
- The image runs as `root`. The scripts run it with `--userns=keep-id`, so files written to the mounts are owned by the host user.
- The Dev Container bind-mounts the whole `/home/r4p` at the same path, and the workspace folder at its host path, so paths and IntelliSense match the host exactly. Don't move it back under `/workspaces`.

## Claude Code in the Dev Container

- Team spec: the image must **not** bundle Claude Code. Don't add it to `scripts/Containerfile`.
- It is installed at container creation with `postCreateCommand` (native installer, `curl` is in the image) into `/root/.local/bin`, which `remoteEnv` adds to `PATH`.
- Config and login persist in the `claude-code-config` volume mounted at `/root/.claude` (`CLAUDE_CONFIG_DIR`).
- **Don't use Dev Container `features`** (including `ghcr.io/anthropics/devcontainer-features/claude-code`). On this host they fail: the CLI builds them with `podman buildx` + `RUN --mount=type=bind` from a context in `/tmp`, which is a `tmpfs` with `nosuid,nodev`, and rootless buildah gets EPERM remounting it read-only (`flags: 0x5021: operation not permitted`).

## Commit messages

Follow the style of `git log`:
- Plain sentences, no `type:` / `feat:` prefixes, no emoji.
- Describe what changed and why, in a conversational tone. A short summary line, optionally followed by a blank line and a few lines of context.
- Wrap file, function and setting names in backticks.
- Never mention `CLAUDE.md` in commit messages.
