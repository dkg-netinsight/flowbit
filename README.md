# FlowBit

FlowBit is a NetFlow / sFlow / IPFIX collector and exporter, used as the data-plane ingestor for [NETINSIGHT](https://github.com/dkg-netinsight/netinsight).

## Fork attribution

FlowBit is a hard fork of [`netsampler/goflow2`](https://github.com/netsampler/goflow2) at tag `v2.2.4` (commit `c538a96`). All upstream copyright remains with NetSampler and the upstream contributors under the BSD 3-Clause License (see `LICENSE`).

Rebrand scope (this fork) — purely identifier / branding changes; flow-decoding semantics, wire formats, transport plug-ins, and CLI flags are unchanged:

- Go module path: `github.com/netsampler/goflow2/v2` → `github.com/dkg-netinsight/flowbit/v2`
- Main command: `cmd/goflow2/` → `cmd/flowbit/`
- Binary name: `goflow2` → `flowbit` (installed to `/usr/sbin/flowbit` by the NETINSIGHT `.deb`)
- Version banner: `GoFlow2 <ver>` → `FLOWBIT <ver>`
- Prometheus metric namespace: `goflow2_*` → `flowbit_*`
- Proto `go_package` options: rewritten to point at this fork

The upstream `goflow2` toolchain remains the reference implementation. FlowBit tracks the rebrand surface only; any future upstream feature pull-ins go via `git fetch upstream && git merge --no-ff upstream/main` followed by re-applying the rebrand sed pass.

## Usage

```bash
# NetFlow v9 / IPFIX on UDP/2055 + sFlow on UDP/6343 (canonical NETINSIGHT install):
$ flowbit -listen "netflow://:2055,sflow://:6343"
```

FlowBit emits flow records to stdout (JSON by default) and exposes Prometheus metrics under namespace `flowbit_*`. NETINSIGHT runs FlowBit under three systemd units: `flowbit-collector.service`, `flowbit-listener@<flow>-<port>.service` (templated), and `flowbit.service` (the MySQL bridge that consumes FlowBits JSON output).

For the complete deployment path see the NETINSIGHT `INSTALL.md`.

## Features (inherited from goflow2)

- NetFlow v5 / NetFlow v9 / IPFIX / sFlow v5 decoding
- Pluggable transports: file, Kafka, NATS, custom
- Pluggable formats: JSON, protobuf, plain text, binary
- Prometheus metrics
- `-mapping=…` for non-standard / vendor template fields

Full upstream documentation lives under [`docs/`](docs/) — it has been rebrand-swept to use the `flowbit` binary name but otherwise reads as the original goflow2 docs.

## Building

```bash
$ make build       # CGO_ENABLED=0 go build -trimpath ./cmd/flowbit
$ make docker      # build the FlowBit container image
```

## License

BSD 3-Clause (see `LICENSE`). Upstream copyright lines preserved verbatim per the license terms. See `NOTICE.flowbit-fork` for the FlowBit-specific attribution notice.
