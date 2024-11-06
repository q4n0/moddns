#!/usr/bin/env bash

# Enhanced color scheme
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# DNS Servers
PRIMARY_DNS="8.8.8.8"
SECONDARY_DNS="8.8.4.4"
TERTIARY_DNS="1.1.1.1"
QUATERNARY_DNS="1.0.0.1"

# Terminal width
TERM_WIDTH=$(tput cols)

# Print tool header with author info
print_banner() {
    clear
    echo
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    echo -e "${BOLD}${BLUE}"
    echo '                    ____  _   _ ____    ____             __ _       '
    echo '                   |  _ \| \ | / ___|  / ___|___  _ __  / _(_) __ _ '
    echo '                   | | | |  \| \___ \ | |   / _ \| '\''_ \| |_| |/ _` |'
    echo '                   | |_| | |\  |___) || |__| (_) | | | |  _| | (_| |'
    echo '                   |____/|_| \_|____/  \____\___/|_| |_|_| |_|\__, |'
    echo '                                                               |___/ '
    echo -e "${NC}"
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    echo -e "${BOLD}${PURPLE}                          Advanced DNS Configuration Utility${NC}"
    echo -e "${DIM}                               Version 1.2.0 - 2024${NC}"
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    echo
    echo -e "${BOLD}${CYAN}Developer Info:${NC}"
    echo -e "${BOLD}${WHITE}  • Author:${NC}    b0urn3"
    echo -e "${BOLD}${WHITE}  • GitHub:${NC}    github.com/q4n0"
    echo -e "${BOLD}${WHITE}  • Twitter:${NC}   @byt3s3c"
    echo -e "${BOLD}${WHITE}  • Instagram:${NC} @onlybyhive"
    echo -e "${BOLD}${WHITE}  • Email:${NC}     q4n0@proton.me"
    echo
    echo -e "${DIM}An advanced DNS configuration utility for enhanced network optimization${NC}"
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    echo
}

# Print section headers
print_section() {
    local text="$1"
    echo -e "\n${BOLD}${CYAN}▶ ${text}${NC}"
    echo -e "${DIM}$(printf '%.s─' $(seq 1 $TERM_WIDTH))${NC}"
}

# Print status with icons
print_status() {
    local text="$1"
    local status="$2"
    printf "${ITALIC}%-50s" "$text"
    case $status in
        "OK")     echo -e "${GREEN}[✓] OK${NC}" ;;
        "FAIL")   echo -e "${RED}[✗] Failed${NC}" ;;
        "WARN")   echo -e "${YELLOW}[!] Warning${NC}" ;;
        "INFO")   echo -e "${BLUE}[i] Info${NC}" ;;
        *)        echo -e "${PURPLE}[*] $status${NC}" ;;
    esac
}

# Show progress bar
show_progress() {
    local text="$1"
    local current="$2"
    local total="$3"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r${ITALIC}%-30s${NC} [" "$text"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] ${BOLD}%3d%%${NC}" $percentage
}

# Show spinner animation
show_spinner() {
    local pid=$1
    local text=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i + 1) % 10 ))
        printf "\r${ITALIC}%-50s${NC} ${BLUE}[${spin:$i:1}]${NC}" "$text"
        sleep .1
    done
    printf "\r%-50s${GREEN}[✓]${NC}\n" "$text"
}

# Check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_status "Root Privileges" "FAIL"
        echo -e "${RED}Please run as root or with sudo${NC}"
        exit 1
    fi
    print_status "Root Privileges" "OK"
}

# Detect OS
detect_os() {
    if [ -f /etc/debian_version ]; then
        OS="debian"
        PM="apt-get"
        PM_INSTALL="$PM install -y"
        PM_UPDATE="$PM update"
    elif [ -f /etc/fedora-release ]; then
        OS="fedora"
        PM="dnf"
        PM_INSTALL="$PM install -y"
        PM_UPDATE="$PM update -y"
    elif [ -f /etc/arch-release ]; then
        OS="arch"
        PM="pacman"
        PM_INSTALL="$PM -S --noconfirm"
        PM_UPDATE="$PM -Sy"
    else
        print_status "OS Detection" "FAIL"
        echo -e "${RED}Unsupported operating system${NC}"
        exit 1
    fi
    print_status "OS Detection" "OK"
    echo -e "${DIM}Detected: $OS${NC}"
}

# Function to check if a package is installed
check_package() {
    local package="$1"
    case $OS in
        debian)
            dpkg -l "$package" >/dev/null 2>&1
            ;;
        fedora)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        arch)
            pacman -Qi "$package" >/dev/null 2>&1
            ;;
    esac
    return $?
}

# Install required packages
install_requirements() {
    print_section "Installing Required Packages"
    
    local packages=(
        "dnsutils" "bc" "mtr" "speedtest-cli" "net-tools" "network-manager"
        "resolvconf" "dnsmasq" "stubby" "bind9-utils" "iputils-ping"
    )
    
    # Update package manager
    echo -e "${DIM}Updating package manager...${NC}"
    $PM_UPDATE >/dev/null 2>&1
    
    for package in "${packages[@]}"; do
        if ! check_package "$package"; then
            echo -e "${DIM}Installing $package...${NC}"
            $PM_INSTALL "$package" >/dev/null 2>&1 || true
        fi
    done
    
    print_status "Package Installation" "OK"
}

# Disable metered connections
disable_metered_connections() {
    print_section "Metered Connection Management"
    
    if ! command -v nmcli >/dev/null 2>&1; then
        print_status "NetworkManager" "WARN"
        echo -e "${DIM}NetworkManager not installed - installing...${NC}"
        $PM_INSTALL network-manager >/dev/null 2>&1
    fi
    
    # Get all connections
    local connections=$(nmcli -t -f UUID,NAME,TYPE c show)
    
    while IFS=: read -r uuid name type; do
        if [ ! -z "$uuid" ]; then
            local metered=$(nmcli -g connection.metered connection show "$uuid" 2>/dev/null)
            if [ "$metered" = "yes" ]; then
                echo -e "${DIM}Disabling metered connection: $name${NC}"
                nmcli connection modify "$uuid" connection.metered no
            fi
        fi
    done <<< "$connections"
    
    print_status "Metered Connections" "OK"
}

# Configure network optimization
optimize_network() {
    print_section "Network Optimization"
    
    # Optimize sysctl parameters
    cat > /etc/sysctl.d/99-network-performance.conf << EOF
# TCP optimization
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 87380 16777216

# UDP optimization
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# Network core optimization
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096

# IPv4 optimization
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
EOF

    # Apply sysctl changes
    sysctl -p /etc/sysctl.d/99-network-performance.conf >/dev/null 2>&1
    
    print_status "Network Parameters" "OK"
}

# Configure DNS
configure_dns() {
    print_section "DNS Configuration"
    
    # Backup original resolv.conf
    cp /etc/resolv.conf /etc/resolv.conf.backup
    
    # Configure new resolv.conf
    cat > /etc/resolv.conf << EOF
nameserver $PRIMARY_DNS
nameserver $SECONDARY_DNS
nameserver $TERTIARY_DNS
nameserver $QUATERNARY_DNS
options edns0 trust-ad
EOF
    
    # Configure DNSMasq
    cat > /etc/dnsmasq.conf << EOF
# DNS servers
server=$PRIMARY_DNS
server=$SECONDARY_DNS

# Basic configuration
listen-address=127.0.0.1
cache-size=1000
neg-ttl=60
dns-forward-max=150

# Performance optimization
dns-forward-max=150
cache-size=1000
min-cache-ttl=3600
EOF

    # Start services
    systemctl enable dnsmasq >/dev/null 2>&1
    systemctl restart dnsmasq >/dev/null 2>&1
    
    print_status "DNS Configuration" "OK"
}

# Test network performance
test_network() {
    print_section "Network Performance Test"
    
    echo -e "${DIM}Testing network performance...${NC}"
    
    # Test DNS resolution
    local dns_time=$(dig google.com | grep "Query time:" | awk '{print $4}')
    echo -e "DNS Resolution Time: ${BOLD}${dns_time}ms${NC}"
    
    # Test connection speed if speedtest-cli is available
    if command -v speedtest-cli >/dev/null 2>&1; then
        echo -e "\n${DIM}Running speed test...${NC}"
        speedtest-cli --simple
    fi
    
    print_status "Network Test" "OK"
}

# Main function
main() {
    print_banner
    check_root
    detect_os
    install_requirements
    disable_metered_connections
    optimize_network
    configure_dns
    test_network
    
    echo -e "\n${GREEN}Network optimization completed successfully!${NC}"
}

# Run main function
main "$@"
