# LayerEdge Light Node Manager

A comprehensive, menu-driven installation and management script for LayerEdge Light Nodes on Ubuntu.

![LayerEdge Banner](https://github.com/TheyCallMeSecond/Layeredge-CLI-manager/blob/main/250320_00h11m58s_screenshot.png?raw=true)

## Overview

LayerEdge Light Node Manager simplifies the process of setting up, configuring, and managing your LayerEdge Light Node on Ubuntu servers. This script provides an interactive menu system that guides you through the installation process and offers ongoing management capabilities.

## Features

- **Interactive Menu System** with color-coded interface
- **Complete Installation Process** for all required components
- **Service Management** for starting, stopping, and monitoring services
- **Logging and Monitoring** tools for troubleshooting
- **Configuration Management** for updating private keys and environment variables
- **Dashboard Integration** guidance for connecting to the LayerEdge dashboard

## Prerequisites

- Ubuntu 24.04.2 LTS (or compatible Linux distribution)
- Root or sudo access
- Internet connection

## Quick Start Guide

### Installation

1. Download the script:
```bash
wget https://raw.githubusercontent.com/TheyCallMeSecond/Layeredge-CLI-manager/refs/heads/main/layeredge-cli.sh
```

2. Make it executable:
```bash
chmod +x layeredge-cli.sh
```

3. Run the script with sudo:
```bash
sudo ./layeredge-cli.sh
```

4. Select option 1 from the menu for a full installation

### Post-Installation

After the installation completes:

1. Navigate to the LayerEdge dashboard at [dashboard.layeredge.io](https://dashboard.layeredge.io)
2. Connect your wallet
3. Link your CLI node Public Key
4. Monitor your node's performance and earned points

## Menu Options

### Installation Options
- **Full Installation**: Complete setup of all components
- **Update Repository**: Pull the latest code from the repository
- **Build/Rebuild Services**: Compile the Merkle service and Light Node

### Service Management
- **Start Services**: Begin running the LayerEdge node services
- **Stop Services**: Halt the running services
- **Restart Services**: Stop and restart services
- **View Service Status**: Check the current status of services

### Monitoring & Configuration
- **Check Node Status**: View the current operational status
- **View Logs**: Access various log files for troubleshooting
- **Update Private Key**: Change your node's private key
- **Dashboard Connection Info**: View instructions for connecting to the dashboard

## System Components

The LayerEdge Light Node consists of two main components:

1. **Merkle Service**: A Rust-based service for generating zero-knowledge proofs
2. **Light Node**: A Go-based application that communicates with the LayerEdge network

## Requirements

The script will install and configure the following dependencies:

- Go (version 1.18+)
- Rust (version 1.81.0+)
- Risc0 Toolchain
- Required system packages (git, curl, build-essential, etc.)

## Directory Structure

```
~/light-node/              # Main directory
├── risc0-merkle-service/  # Merkle service component
├── .env                   # Environment configuration
└── light-node             # Compiled Light Node binary

/var/log/layeredge/        # Log directory
├── merkle.log             # Merkle service logs
├── merkle-error.log       # Merkle service error logs
├── node.log               # Light Node logs
└── node-error.log         # Light Node error logs

/etc/systemd/system/       # Systemd service definitions
├── layeredge-merkle.service
└── layeredge-node.service
```

## Troubleshooting

If you encounter issues:

1. Check the logs using menu option 9
2. Verify your private key is correctly set
3. Ensure the Merkle service is running before the Light Node
4. Check network connectivity to the LayerEdge gRPC endpoint

## Security Considerations

- Keep your private key secure and never share it
- Regularly update your node from the official repository
- Follow standard server security practices

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- LayerEdge Team for their excellent documentation
- All contributors to this management script

## Disclaimer

This is an unofficial management tool for LayerEdge Light Nodes. Please refer to the official LayerEdge documentation for authoritative information.
