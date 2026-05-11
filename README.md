# FlowBit

FlowBit is a high-performance NetFlow / sFlow / IPFIX collector and exporter. It is the data-plane ingestor for [NETINSIGHT](https://github.com/dkg-netinsight/netinsight).

## What it does

- Decodes NetFlow v5 / NetFlow v9 / IPFIX / sFlow v5 traffic on UDP listeners.
- Emits flow records as JSON, protobuf, plain text, or binary via pluggable transports (file, Kafka, NATS, custom).
- Exposes Prometheus metrics under the `flowbit_*` namespace.
- Supports a `-mapping=...` configuration for non-standard / vendor-specific template fields.

## Usage

```bash
# Canonical NETINSIGHT install — NetFlow v9 / IPFIX on UDP/2055, sFlow on UDP/6343:
$ flowbit -listen "netflow://:2055,sflow://:6343"
```

FlowBit writes flow records to stdout (JSON by default) and exposes Prometheus metrics on the address passed via `-addr`. NETINSIGHT runs FlowBit under three systemd units: `flowbit-collector.service`, `flowbit-listener@<flow>-<port>.service` (templated, one instance per listener port), and `flowbit.service` (the MySQL bridge that consumes FlowBit's JSON output).

For the complete deployment path see the NETINSIGHT `INSTALL.md`.

## Building

```bash
$ make build       # CGO_ENABLED=0 go build -trimpath ./cmd/flowbit
$ make docker      # build the FlowBit container image
```

## License

BSD 3-Clause. See `LICENSE`.
