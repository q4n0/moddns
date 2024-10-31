#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# DNS Servers
PRIMARY_DNS="8.8.8.8"
SECONDARY_DNS="8.8.4.4"
TERTIARY_DNS="1.1.1.1"
QUATERNARY_DNS="1.0.0.1"

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
        echo -e "${RED}Unsupported operating system${NC}"
        exit 1
    fi
    echo -e "${GREEN}Detected OS: $OS${NC}"
}

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: Please run as root${NC}"
        exit 1
    fi
}

# Install requirements based on OS
install_requirements() {
    echo -e "${YELLOW}Installing required packages...${NC}"
    case $OS in
        debian)
            $PM_UPDATE
            $PM_INSTALL dnsutils bc mtr speedtest-cli resolvconf dnsmasq stubby
            ;;
        fedora)
            $PM_UPDATE
            $PM_INSTALL bind-utils bc mtr speedtest-cli systemd-resolved dnsmasq stubby
            ;;
        arch)
            $PM_UPDATE
            $PM_INSTALL dnsutils bc mtr speedtest-cli systemd-resolved dnsmasq stubby
            ;;
    esac
}

# Get active connection
get_active_connection() {
    if command -v nmcli >/dev/null 2>&1; then
        CONNECTION=$(nmcli -t -f NAME,DEVICE,STATE c show --active | grep activated | cut -d':' -f1)
    else
        CONNECTION=$(ip route | grep default | awk '{print $5}')
    fi

    if [ -z "$CONNECTION" ]; then
        echo -e "${RED}No active connection found${NC}"
        exit 1
    fi
    echo -e "${GREEN}Found active connection: $CONNECTION${NC}"
}

# Get current network settings
get_current_settings() {
    CURRENT_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
    CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n 1)
    
    if [ ! -z "$CURRENT_IP" ]; then
        IP_ADDRESS=$CURRENT_IP
    else
        IP_ADDRESS="192.168.0.9/24"
    fi
    
    if [ ! -z "$CURRENT_GATEWAY" ]; then
        GATEWAY=$CURRENT_GATEWAY
    else
        GATEWAY="192.168.0.1"
    fi
}

# Find fastest DNS
find_fastest_dns() {
    echo -e "${YELLOW}Testing DNS servers for optimal speed...${NC}"
    local dns_servers=(
        "8.8.8.8"
        "8.8.4.4"
        "1.1.1.1"
        "1.0.0.1"
        "9.9.9.9"
        "149.112.112.112"
        "208.67.222.222"
        "208.67.220.220"
    )
    
    local fastest_time=999
    local fastest_dns=""
    
    for dns in "${dns_servers[@]}"; do
        echo -e "${BLUE}Testing $dns...${NC}"
        local response_time=$(dig @"$dns" google.com | grep "Query time:" | awk '{print $4}')
        if [ ! -z "$response_time" ] && [ "$response_time" -lt "$fastest_time" ]; then
            fastest_time=$response_time
            fastest_dns=$dns
        fi
    done
    
    PRIMARY_DNS=$fastest_dns
    echo -e "${GREEN}Fastest DNS server: $PRIMARY_DNS (${fastest_time}ms)${NC}"
}

# Configure DNS based on OS
configure_dns() {
    echo -e "${YELLOW}Configuring DNS for $OS...${NC}"
    case $OS in
        debian)
            # Configure resolvconf
            cat > /etc/resolvconf.conf << EOF
nameserver $PRIMARY_DNS
nameserver $SECONDARY_DNS
nameserver $TERTIARY_DNS
nameserver $QUATERNARY_DNS
options edns0 trust-ad
EOF
            resolvconf -u
            ;;
        fedora|arch)
            # Configure systemd-resolved
            cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=$PRIMARY_DNS $SECONDARY_DNS
FallbackDNS=$TERTIARY_DNS $QUATERNARY_DNS
DNSSEC=yes
DNSOverTLS=yes
Cache=yes
DNSStubListener=yes
EOF
            systemctl restart systemd-resolved
            ;;
    esac
}

# Configure DNSMasq
setup_dnsmasq() {
    echo -e "${YELLOW}Setting up DNSMasq...${NC}"
    cat > /etc/dnsmasq.conf << EOF
server=$PRIMARY_DNS
server=$SECONDARY_DNS
cache-size=1000
no-negcache
dns-forward-max=150
no-resolv
EOF
    
    systemctl enable dnsmasq
    systemctl restart dnsmasq
}

# Configure Stubby
setup_stubby() {
    echo -e "${YELLOW}Setting up Stubby...${NC}"
    cat > /etc/stubby/stubby.yml << EOF
resolution_type: GETDNS_RESOLUTION_STUB
dns_transport_list:
  - GETDNS_TRANSPORT_TLS
tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
tls_query_padding_blocksize: 128
edns_client_subnet_private: 1
round_robin_upstreams: 1
idle_timeout: 10000
listen_addresses:
  - 127.0.0.1@53000
  - 0::1@53000
upstream_recursive_servers:
  - address_data: $PRIMARY_DNS
    tls_auth_name: "dns.google"
  - address_data: $SECONDARY_DNS
    tls_auth_name: "dns.google"
EOF

    systemctl enable stubby
    systemctl restart stubby
}

# Test configuration
test_configuration() {
    echo -e "${YELLOW}Testing DNS configuration...${NC}"
    if ping -c 1 google.com &>/dev/null; then
        echo -e "${GREEN}DNS configuration successful!${NC}"
        echo "Primary DNS: $PRIMARY_DNS"
        echo "Secondary DNS: $SECONDARY_DNS"
        
        # Test DNS resolution speed
        local resolution_time=$(dig google.com | grep "Query time:" | awk '{print $4}')
        echo "Current DNS resolution time: ${resolution_time}ms"
    else
        echo -e "${RED}Warning: DNS configuration may have issues${NC}"
    fi
}

# Main function
main() {
    check_root
    detect_os
    install_requirements
    get_active_connection
    get_current_settings
    find_fastest_dns
    configure_dns
    setup_dnsmasq
    setup_stubby
    test_configuration
}

# Run main function
main
