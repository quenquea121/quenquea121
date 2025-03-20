#!/bin/bash

# LayerEdge Light Node Setup Script with Interactive Menu for Ubuntu 24.04.2 LTS
# This script provides a menu-driven interface for installing and managing LayerEdge Light Node

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
HOME_DIR=$HOME
LAYEREDGE_DIR="$HOME_DIR/light-node"
ENV_FILE="$LAYEREDGE_DIR/.env"
LOG_DIR="/var/log/layeredge"

# Function to print colored messages
print_message() {
    echo -e "${BLUE}[LayerEdge Setup]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Success]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[Warning]${NC} $1"
}

print_error() {
    echo -e "${RED}[Error]${NC} $1"
}

# Check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root or with sudo"
        exit 1
    fi
}

# Create directories
create_directories() {
    mkdir -p $LOG_DIR
    chmod 755 $LOG_DIR
}

# Update system and install basic dependencies
update_system() {
    print_message "Updating system and installing basic dependencies..."
    apt-get update && apt-get upgrade -y
    apt-get install -y build-essential curl wget git pkg-config libssl-dev jq ufw
    print_success "System updated and dependencies installed"
}

# Install Go
install_go() {
    print_message "Installing Go 1.18+..."
    wget https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.bashrc
    source ~/.bashrc
    rm go1.22.5.linux-amd64.tar.gz
    print_success "Go installed successfully"
}

# Check if Go is installed
check_go() {
    if ! command -v go &>/dev/null; then
        install_go
    else
        go_version=$(go version | awk '{print $3}' | sed 's/go//')
        if [ "$(echo -e "1.18\n$go_version" | sort -V | head -n1)" != "1.18" ]; then
            print_warning "Go version is less than 1.18. Updating..."
            install_go
        else
            print_success "Go version $go_version is already installed"
        fi
    fi
}

# Install Rust
install_rust() {
    print_message "Installing Rust 1.81.0+..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    print_success "Rust installed successfully"
}

# Check if Rust is installed
check_rust() {
    if ! command -v rustc &>/dev/null; then
        install_rust
    else
        rust_version=$(rustc --version | awk '{print $2}')
        if [ "$(echo -e "1.81.0\n$rust_version" | sort -V | head -n1)" != "1.81.0" ]; then
            print_warning "Rust version is less than 1.81.0. Updating..."
            rustup update
        else
            print_success "Rust version $rust_version is already installed"
        fi
    fi
}

# Install Risc0 toolchain
install_risc0() {
    print_message "Installing Risc0 toolchain..."
    curl -L https://risczero.com/install | bash
    source ~/.bashrc
    rzup install
    print_success "Risc0 toolchain installed successfully"
}

# Clone LayerEdge Light Node repository
clone_repo() {
    print_message "Cloning LayerEdge Light Node repository..."
    cd $HOME_DIR
    if [ -d "$LAYEREDGE_DIR" ]; then
        print_warning "The 'light-node' directory already exists. Updating..."
        cd $LAYEREDGE_DIR
        git pull
    else
        git clone https://github.com/Layer-Edge/light-node.git
        cd $LAYEREDGE_DIR
    fi
    print_success "Repository cloned successfully"
}

# Setup environment variables
setup_env() {
    print_message "Setting up environment variables..."

    # Check if .env file exists
    if [ -f "$ENV_FILE" ]; then
        print_warning ".env file already exists. Would you like to overwrite it? (y/n)"
        read -r overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            print_message "Keeping existing .env file"
            return
        fi
    fi

    # Creating new .env file
    cat >$ENV_FILE <<EOF
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
EOF

    # Ask for private key
    read -p "Enter your CLI node private key without '0x' (or press Enter to set it later): " private_key
    if [ ! -z "$private_key" ]; then
        echo "PRIVATE_KEY=$private_key" >>$ENV_FILE
        print_success "Private key added"
    else
        print_warning "Private key was not set. You will need to set it manually in .env file"
    fi

    # Set proper permissions
    chmod 644 $ENV_FILE
    print_success "Environment variables configured"
}

# Build Merkle service
build_merkle() {
    print_message "Building Risc0 Merkle service..."
    cd $LAYEREDGE_DIR/risc0-merkle-service
    source $HOME/.cargo/env
    cargo build
    print_success "Merkle service built successfully"
}

# Build Light Node
build_node() {
    print_message "Building LayerEdge Light Node..."
    cd $LAYEREDGE_DIR
    source /etc/profile
    go build
    print_success "Light Node built successfully"
}

# Create systemd services
create_services() {
    print_message "Creating systemd service for Merkle service..."
    cat >/etc/systemd/system/layeredge-merkle.service <<EOF
[Unit]
Description=LayerEdge Merkle Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$LAYEREDGE_DIR/risc0-merkle-service
ExecStart=$HOME/.cargo/bin/cargo run
Restart=on-failure
RestartSec=10
StandardOutput=append:$LOG_DIR/merkle.log
StandardError=append:$LOG_DIR/merkle-error.log

[Install]
WantedBy=multi-user.target
EOF

    print_message "Creating systemd service for Light Node..."
    cat >/etc/systemd/system/layeredge-node.service <<EOF
[Unit]
Description=LayerEdge Light Node
After=layeredge-merkle.service
Requires=layeredge-merkle.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$LAYEREDGE_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$LAYEREDGE_DIR/light-node
Restart=on-failure
RestartSec=10
StandardOutput=append:$LOG_DIR/node.log
StandardError=append:$LOG_DIR/node-error.log

[Install]
WantedBy=multi-user.target
EOF

    # Set proper permissions
    chmod 644 /etc/systemd/system/layeredge-merkle.service
    chmod 644 /etc/systemd/system/layeredge-node.service
    print_success "Systemd services created"
}

# Configure firewall
setup_firewall() {
    print_message "Configuring firewall..."
    ufw allow 22/tcp
    ufw allow 3001/tcp
    ufw allow 8080/tcp
    ufw --force enable
    print_success "Firewall configured"
}

# Enable and start services
start_services() {
    print_message "Enabling and starting services..."
    systemctl daemon-reload
    systemctl enable layeredge-merkle.service
    systemctl enable layeredge-node.service
    systemctl start layeredge-merkle.service
    print_message "Waiting for Merkle service to initialize (30 seconds)..."
    sleep 30
    systemctl start layeredge-node.service

    # Service status check
    if systemctl is-active --quiet layeredge-merkle.service; then
        print_success "Merkle service is running"
    else
        print_error "Merkle service failed to start. Check logs with: journalctl -u layeredge-merkle.service"
    fi

    if systemctl is-active --quiet layeredge-node.service; then
        print_success "Light Node is running"
    else
        print_error "Light Node failed to start. Check logs with: journalctl -u layeredge-node.service"
    fi
}

# Stop services
stop_services() {
    print_message "Stopping LayerEdge services..."
    systemctl stop layeredge-node.service
    systemctl stop layeredge-merkle.service
    print_success "Services stopped"
}

# Create status check script
create_status_script() {
    print_message "Creating status check script..."
    cat >$HOME_DIR/check-layeredge-status.sh <<EOF
#!/bin/bash

echo "===== LayerEdge Services Status ====="
systemctl status layeredge-merkle.service | grep "Active:"
systemctl status layeredge-node.service | grep "Active:"

echo -e "\n===== Last 10 lines of Merkle logs ====="
tail -n 10 $LOG_DIR/merkle.log

echo -e "\n===== Last 10 lines of Node logs ====="
tail -n 10 $LOG_DIR/node.log

echo -e "\n===== Last 10 lines of Error logs ====="
tail -n 10 $LOG_DIR/merkle-error.log
tail -n 10 $LOG_DIR/node-error.log
EOF

    chmod +x $HOME_DIR/check-layeredge-status.sh
    print_success "Status check script created: $HOME_DIR/check-layeredge-status.sh"
}

# View logs
view_logs() {
    echo -e "\n${CYAN}Available Logs:${NC}"
    echo "1) Merkle Service Log"
    echo "2) Light Node Log"
    echo "3) Merkle Error Log"
    echo "4) Light Node Error Log"
    echo "5) Return to Main Menu"

    read -p "Select log to view: " log_choice

    case $log_choice in
    1) less $LOG_DIR/merkle.log ;;
    2) less $LOG_DIR/node.log ;;
    3) less $LOG_DIR/merkle-error.log ;;
    4) less $LOG_DIR/node-error.log ;;
    5) return ;;
    *) print_error "Invalid selection" ;;
    esac
}

# Check node status
check_status() {
    $HOME_DIR/check-layeredge-status.sh
}

# View service status
view_service_status() {
    echo -e "\n${CYAN}Service Status:${NC}"
    echo "1) Merkle Service Status"
    echo "2) Light Node Service Status"
    echo "3) Return to Main Menu"

    read -p "Select service: " service_choice

    case $service_choice in
    1) systemctl status layeredge-merkle.service ;;
    2) systemctl status layeredge-node.service ;;
    3) return ;;
    *) print_error "Invalid selection" ;;
    esac
}

# Update private key
update_private_key() {
    read -p "Enter your new CLI node private key without '0x': " new_private_key

    if [ -f "$ENV_FILE" ]; then
        # Check if PRIVATE_KEY already exists in .env
        if grep -q "PRIVATE_KEY" "$ENV_FILE"; then
            # Replace existing PRIVATE_KEY
            sed -i "s/PRIVATE_KEY=.*/PRIVATE_KEY=$new_private_key/" $ENV_FILE
        else
            # Add new PRIVATE_KEY
            echo "PRIVATE_KEY=$new_private_key" >>$ENV_FILE
        fi
        print_success "Private key updated"

        # Restart Light Node service
        print_message "Restarting Light Node service to apply changes..."
        systemctl restart layeredge-node.service
    else
        print_error ".env file not found. Please run setup first."
    fi
}

# Dashboard connection info
show_dashboard_info() {
    echo -e "\n${CYAN}======= LayerEdge Dashboard Connection Information =======${NC}"
    echo "1. Navigate to dashboard.layeredge.io"
    echo "2. Connect your wallet"
    echo "3. Link your CLI node Public Key"
    echo "4. Check your points at:"
    echo "   https://light-node.layeredge.io/api/cli-node/points/{your-wallet-address}"
    echo -e "${CYAN}=========================================================${NC}"

    read -p "Press Enter to continue..."
}

# Full installation
install_full() {
    check_root
    create_directories
    update_system
    check_go
    check_rust
    install_risc0
    clone_repo
    setup_env
    build_merkle
    build_node
    create_services
    setup_firewall
    create_status_script
    start_services

    print_message "============================================"
    print_success "LayerEdge Light Node full installation completed!"
    print_message "============================================"
    read -p "Press Enter to continue..."
}

# Display banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║               LayerEdge Light Node Manager               ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Main menu
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}Installation Options:${NC}"
        echo "1) Full Installation"
        echo "2) Update Repository"
        echo "3) Build/Rebuild Services"
        echo ""
        echo -e "${CYAN}Service Management:${NC}"
        echo "4) Start Services"
        echo "5) Stop Services"
        echo "6) Restart Services"
        echo "7) View Service Status"
        echo ""
        echo -e "${CYAN}Monitoring & Configuration:${NC}"
        echo "8) Check Node Status"
        echo "9) View Logs"
        echo "10) Update Private Key"
        echo "11) Dashboard Connection Info"
        echo ""
        echo "12) Exit"
        echo ""
        read -p "Enter your choice: " choice

        case $choice in
        1) install_full ;;
        2)
            check_root
            clone_repo
            read -p "Press Enter to continue..."
            ;;
        3)
            check_root
            build_merkle
            build_node
            read -p "Press Enter to continue..."
            ;;
        4)
            check_root
            start_services
            read -p "Press Enter to continue..."
            ;;
        5)
            check_root
            stop_services
            read -p "Press Enter to continue..."
            ;;
        6)
            check_root
            stop_services
            start_services
            read -p "Press Enter to continue..."
            ;;
        7)
            check_root
            view_service_status
            ;;
        8)
            check_status
            read -p "Press Enter to continue..."
            ;;
        9)
            view_logs
            ;;
        10)
            check_root
            update_private_key
            read -p "Press Enter to continue..."
            ;;
        11)
            show_dashboard_info
            ;;
        12)
            echo "Exiting LayerEdge Light Node Manager. Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please try again."
            read -p "Press Enter to continue..."
            ;;
        esac
    done
}

# Execute main menu
main_menu
