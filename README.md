# vyges-sim

A reproducible **Verilator + cocotb** simulation substrate for the
[Vyges](https://vyges.com) toolchain — the runtime that produces the VCD/FST activity
our sign-off engines consume, and where agent-generated testbenches run.

## What's inside

One pinned image (`ubuntu:26.04`):

| Component | Version | Role |
|---|---|---|
| Verilator | 5.032 (apt) | simulator (VCD/FST trace) |
| cocotb | 1.9.2 (pip) | coroutine testbench framework |
| Python | 3.14 | cocotb runtime |

## Why package-pinned (not source-built)

`vyges-openroad` and `vyges-klayout` build their tools from a pinned git commit because
those tools aren't adequately packaged. **Verilator is a normal apt package and is
version-tolerant for our use** — any 5.x produces the FST/VCD our readers handle — so
this distro pins the Ubuntu base image + apt/pip versions instead. Fully reproducible,
no build to maintain. See `upstream.yaml`.

There is no separate simulator-only image: the house harness is cocotb, so the two live
in one layer. (Splitting out a lean Verilator-only image later is a Dockerfile change,
if a real sim-only consumer ever appears.)

## Use

```bash
docker run --rm -v "$PWD:/work" -w /work ghcr.io/vyges-tools/vyges-sim:latest \
  verilator --binary --trace-fst dut_tb.v dut.v && ./obj_dir/Vdut_tb   # -> dump.fst
```

The image advertises itself via `vyges-tool.json` + OCI `com.vyges.tool.*` labels, so the
`vyges` MCP/resolve layer can discover it (`vyges-tool-descriptor/1.1`).

Licensed under Apache-2.0. Verilator (Apache-2.0 / LGPL-3.0) and cocotb (BSD-3-Clause)
are installed from their distributions, unmodified.
