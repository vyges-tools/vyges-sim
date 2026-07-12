# vyges-sim — reproducible Verilator + cocotb simulation substrate.
#
# Single, PACKAGE-PINNED image (apt Verilator + pip cocotb) — no source build.
# Unlike vyges-openroad / vyges-klayout (built from source because those tools are
# not adequately packaged), Verilator is a normal apt package and is version-tolerant
# for our use (any 5.x produces the FST/VCD our readers consume), so this distro pins
# the Ubuntu package + pip version rather than a git commit. cocotb is the house test
# harness; there is no separate simulator-only image (YAGNI — split later if ever needed).
#
# Versions live in exactly two roles: (1) INSTALL PINS — build-args below, the single
# source of truth for what we install (mirrored in upstream.yaml); (2) the REPORTED
# descriptor — generated at build time by *querying the installed tools*, so it can
# never drift from what is actually in the image. Nothing is version-hardcoded twice.

# Base pinned by digest for reproducibility (ubuntu:26.04, resolved 2026-07-12).
FROM ubuntu:26.04@sha256:b7f48194d4d8b763a478a621cdc81c27be222ba2206ca3ca6bc42b49685f3d9e
ENV DEBIAN_FRONTEND=noninteractive

# --- install pins (the one place versions are declared) --------------------------
ARG VERILATOR_APT=5.032-1        # ubuntu:26.04 candidate (upstream Verilator 5.032)
ARG COCOTB_PIP=1.9.2             # house-pinned coroutine testbench framework
ARG VYGES_SIM_VERSION=2026.07.1  # Vyges distro date-release (a Vyges label, not a tool version)

# Verilator (pinned) + the C++ toolchain it needs at RUNTIME (it compiles the C++ it
# generates), plus Python for cocotb.
RUN apt-get update && apt-get install -y --no-install-recommends \
      verilator=${VERILATOR_APT} g++ make perl python3 python3-pip python3-dev ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir --break-system-packages cocotb==${COCOTB_PIP}

# Build gate: the tools must be present + importable, or the image fails to build.
RUN verilator --version \
 && python3 -c "import cocotb, sys; print('cocotb', cocotb.__version__, '| python', sys.version.split()[0])"

# vyges-tool-descriptor/1.1 — REPORTED component versions are LOOKED UP from the
# installed tools (not hardcoded), so the descriptor always matches the image.
RUN set -eu; \
    v="$(verilator --version | grep -oE '[0-9]+\.[0-9]+' | head -1)"; \
    c="$(python3 -c 'import cocotb; print(cocotb.__version__)')"; \
    p="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"; \
    mkdir -p /opt/vyges; \
    printf '{\n  "schema": "vyges-tool-descriptor/1.1",\n  "kind": "tool",\n  "tool": "sim",\n  "version": { "kind": "tag", "value": "%s" },\n  "components": [\n    { "name": "verilator", "version": { "kind": "tag", "value": "%s" }, "kind": "simulator" },\n    { "name": "cocotb",    "version": { "kind": "tag", "value": "%s" }, "kind": "framework" },\n    { "name": "python",    "version": { "kind": "tag", "value": "%s" }, "kind": "runtime" }\n  ],\n  "capabilities": ["simulate", "trace", "cocotb-driven", "dynamic-testbench", "python-runtime"]\n}\n' \
      "$VYGES_SIM_VERSION" "$v" "$c" "$p" > /opt/vyges/vyges-tool.json; \
    cat /opt/vyges/vyges-tool.json

LABEL org.opencontainers.image.title="vyges-sim" \
      org.opencontainers.image.source="https://github.com/vyges-tools/vyges-sim" \
      org.opencontainers.image.description="Reproducible Verilator + cocotb simulation substrate (VCD/FST activity generation), pinned by Vyges." \
      org.opencontainers.image.licenses="Apache-2.0" \
      com.vyges.tool="sim" \
      com.vyges.tool.version="${VYGES_SIM_VERSION}" \
      com.vyges.tool.descriptor="/opt/vyges/vyges-tool.json"
