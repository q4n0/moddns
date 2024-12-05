#!/usr/bin/env bash

# Universal DNS Optimizer - Cross-Platform Network Configuration Tool
# Version 2.0.0 - 2024

# Enhanced Color Scheme
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

# Default DNS Servers (Prioritized)
DNS_SERVERS=(
    "8.8.8.8;Google Primary"
    "1.1.1.1;Cloudflare Primary"
    "8.8.4.4;Google Secondary"
    "1.0.0.1;Cloudflare Secondary"
)

# Supported Package Managers
declare -A PACKAGE_MANAGERS=(
    ["debian"]="apt-get"
    ["ubuntu"]="apt-get"
    ["fedora"]="dnf"
    ["centos"]="yum"
    ["rhel"]="yum"
    ["arch"]="pacman"
    ["manjaro"]="pacman"
    ["opensuse"]="zypper"
)

# Supported Service Managers
declare -A SERVICE_MANAGERS=(
    ["debian"]="systemctl"
    ["ubuntu"]="systemctl"
    ["fedora"]="systemctl"
    ["centos"]="systemctl"
    ["rhel"]="systemctl"
    ["arch"]="systemctl"
    ["manjaro"]="systemctl"
    ["opensuse"]="systemctl"
)

# Required Packages
REQUIRED_PACKAGES=(
    "dnsutils"
    "bind-utils"
    "network-manager"
    "bc"
    "mtr"
)

# Terminal Configuration
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# Logging
LOG_FILE="/var/log/dns_optimizer.log"
touch "$LOG_FILE"

# Utility Functions
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
    case "$level" in
        "ERROR") echo -e "${RED}[✗] $message${NC}" ;;
        "WARN")  echo -e "${YELLOW}[!] $message${NC}" ;;
        "INFO")  echo -e "${BLUE}[*] $message${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[✓] $message${NC}" ;;
    esac
}

# Detect Operating System
detect_os() {
    local os_release=""
    
    if [ -f /etc/os-release ]; then
        os_release=$(grep -E "^(ID=|NAME=)" /etc/os-release | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/redhat-release ]; then
        os_release=$(cat /etc/redhat-release | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
    fi

    for known_os in "${!PACKAGE_MANAGERS[@]}"; do
        if [[ "$os_release" == *"$known_os"* ]]; then
            echo "$known_os"
            return 0
        fi
    done

    log_message "ERROR" "Unsupported Operating System: $os_release"
    exit 1
}

# Root Check
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR" "This script must be run with root privileges"
        exit 1
    fi
}

# Package Installation
install_dependencies() {
    local os=$(detect_os)
    local package_manager="${PACKAGE_MANAGERS[$os]}"
    
    log_message "INFO" "Installing dependencies for $os"
    
    case "$package_manager" in
        "apt-get")
            apt-get update -q
            apt-get install -y "${REQUIRED_PACKAGES[@]}"
            ;;
        "dnf"|"yum")
            "$package_manager" makecache
            "$package_manager" install -y "${REQUIRED_PACKAGES[@]}"
            ;;
        "pacman")
            pacman -Sy --noconfirm "${REQUIRED_PACKAGES[@]}"
            ;;
        "zypper")
            zypper refresh
            zypper install -y "${REQUIRED_PACKAGES[@]}"
            ;;
        *)
            log_message "ERROR" "Unsupported package manager"
            exit 1
            ;;
    esac
}

# Find Fastest DNS
find_fastest_dns() {
    local fastest_time=999
    local fastest_dns=""
    local fastest_name=""
    
    log_message "INFO" "Testing DNS server performance"
    
    for entry in "${DNS_SERVERS[@]}"; do
        IFS=';' read -r dns name <<< "$entry"
        local response_time=$(dig @"$dns" google.com +time=2 +tries=1 2>/dev/null | grep "Query time:" | awk '{print $4}')
        
        if [[ -n "$response_time" ]] && [[ "$response_time" -lt "$fastest_time" ]]; then
            fastest_time="$response_time"
            fastest_dns="$dns"
            fastest_name="$name"
        fi
    done
    
    if [[ -z "$fastest_dns" ]]; then
        log_message "WARN" "Could not determine fastest DNS. Using default."
        fastest_dns="8.8.8.8"
        fastest_name="Google Primary"
    fi
    
    log_message "SUCCESS" "Fastest DNS: $fastest_name ($fastest_dns) at ${fastest_time}ms"
    echo "$fastest_dns"
}

# Configure DNS
configure_dns() {
    local primary_dns="$1"
    
    log_message "INFO" "Configuring DNS with $primary_dns"
    
    # NetworkManager configuration
    mkdir -p /etc/NetworkManager/conf.d/
    cat > /etc/NetworkManager/conf.d/dns.conf << EOF
[main]
dns=none
EOF

    # Resolv.conf configuration
    cat > /etc/resolv.conf << EOF
nameserver $primary_dns
nameserver 1.1.1.1
nameserver 8.8.4.4
nameserver 1.0.0.1
options edns0 timeout:2 attempts:3
EOF

    # Make resolv.conf immutable
    chattr +i /etc/resolv.conf

    # Restart NetworkManager
    systemctl restart NetworkManager
}

# Network Performance Optimization
optimize_network() {
    log_message "INFO" "Optimizing network performance"
    
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
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096

# IPv4 optimization
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_window_scaling = 1
EOF

    sysctl -p /etc/sysctl.d/99-network-performance.conf >/dev/null 2>&1
}

# Test DNS Configuration
test_dns_configuration() {
    local test_domains=("google.com" "cloudflare.com" "github.com")
    local successful_tests=0
    
    log_message "INFO" "Testing DNS configuration"
    
    for domain in "${test_domains[@]}"; do
        if dig "$domain" +short >/dev/null 2>&1; then
            ((successful_tests++))
            log_message "SUCCESS" "DNS resolution successful for $domain"
        else
            log_message "WARN" "DNS resolution failed for $domain"
        fi
    done
    
    if [[ $successful_tests -eq ${#test_domains[@]} ]]; then
        log_message "SUCCESS" "All DNS tests passed"
        return 0
    else
        log_message "ERROR" "DNS configuration test failed"
        return 1
    fi
}

# Main Function
main() {
    clear
    check_root
    install_dependencies
    
    local fastest_dns=$(find_fastest_dns)
    configure_dns "$fastest_dns"
    optimize_network
    
    if test_dns_configuration; then
        echo -e "${GREEN}DNS Configuration Completed Successfully!${NC}"
        echo -e "Primary DNS: ${BOLD}$fastest_dns${NC}"
        echo -e "Performance optimizations applied."
    else
        echo -e "${RED}DNS Configuration Encountered Issues${NC}"
        echo "Please check the log file at $LOG_FILE for details."
    fi
}

# Execute Main Function
main "$@"
