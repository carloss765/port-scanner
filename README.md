# Port Scanner in Go

A fast and efficient concurrent port scanner built with Go.

## What is a Port Scanner?

A **Port Scanner** is a tool used to explore and identify open ports on a networked device (like a computer, server, or router). In networking, a "port" is a communication endpoint for specific services (e.g., HTTP uses port 80, SSH uses port 22).

By scanning these ports, you can:
- **Identify running services**: See what applications are listening for connections.
- **Security Auditing**: Discover potentially vulnerable or unnecessary open ports.
- **Network Troubleshooting**: Verify if a service is accessible over the network.

## Features

- **High Performance**: Uses Go's goroutines (workers) to scan multiple ports simultaneously.
- **Configurable**: Easily adjust the target host, port range, and number of concurrent workers.
- **Lightweight**: Zero external dependencies, using only the Go standard library.

## Prerequisites

- [Go](https://golang.org/dl/) (version 1.23+ recommended)

## Installation

Clone the repository:

```bash
git clone https://github.com/carloss765/port-scanner.git
cd port-scanner
```

## How to Use

You can run the scanner directly using `go run`:

```bash
go run main.go -host 127.0.0.1 -start 1 -end 1024 -workers 100
```

### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `-host` | The IP address or domain to scan | `127.0.0.1` |
| `-start` | The starting port of the range | `1` |
| `-end` | The ending port of the range | `1024` |
| `-workers` | Number of concurrent goroutines to use | `100` |

### Example Outputs

**Scanning localhost:**
```bash
go run main.go -host 127.0.0.1 -start 20 -end 100
# Output:
# Escaneando...
# Puerto 22 esta abierto
# Puerto 80 esta abierto
# Tiempo total: 1.002s
```

## How it Works

1. **Workers**: The program spawns a specified number of "workers" (goroutines).
2. **Channel Distribution**: The port range is sent through a `ports` channel.
3. **TCP Connection**: Each worker picks a port and tries to establish a TCP connection using `net.DialTimeout`.
4. **Results**: If the connection is successful, the port is marked as open and sent to the `results` channel.
5. **Efficiency**: By using workers, the scanner doesn't wait for one port to timeout before checking the next one.
