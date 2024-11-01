#!/bin/bash

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
    echo -e "${DIM}                               Version 1.1.0 - 2024${NC}"
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

# Check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_status "Root Privileges" "FAIL"
        echo -e "${RED}Please run as root or with sudo${NC}"
        exit 1
    fi
    print_status "Root Privileges" "OK"
}

# Install required packages
install_requirements() {
    print_status "Installing Dependencies" "INFO"
    case $OS in
        debian)
            $PM_UPDATE >/dev/null 2>&1
            $PM_INSTALL dnsutils bc mtr speedtest-cli resolvconf dnsmasq stubby >/dev/null 2>&1
            ;;
        fedora)
            $PM_UPDATE >/dev/null 2>&1
            $PM_INSTALL bind-utils bc mtr speedtest-cli systemd-resolved dnsmasq stubby >/dev/null 2>&1
            ;;
        arch)
            $PM_UPDATE >/dev/null 2>&1
            $PM_INSTALL dnsutils bc mtr speedtest-cli systemd-resolved dnsmasq stubby >/dev/null 2>&1
            ;;
    esac
    print_status "Package Installation" "OK"
}

# Get active network connection
get_active_connection() {
    if command -v nmcli >/dev/null 2>&1; then
        CONNECTION=$(nmcli -t -f NAME,DEVICE,STATE c show --active | grep activated | cut -d':' -f1)
    else
        CONNECTION=$(ip route | grep default | awk '{print $5}')
    fi

    if [ -z "$CONNECTION" ]; then
        print_status "Network Detection" "FAIL"
        echo -e "${RED}No active connection found${NC}"
        exit 1
    fi
    print_status "Network Detection" "OK"
    echo -e "${DIM}Active interface: $CONNECTION${NC}"
}

# Find fastest DNS
find_fastest_dns() {
    print_section "Testing DNS Servers"
    local dns_servers=(
        "8.8.8.8;Google DNS Primary"
        "8.8.4.4;Google DNS Secondary"
        "1.1.1.1;Cloudflare Primary"
        "1.0.0.1;Cloudflare Secondary"
    )
    
    local fastest_time=999
    local fastest_dns=""
    local fastest_name=""
    local current=0
    local total=${#dns_servers[@]}
    
    echo -e "${DIM}Testing response times from multiple providers...${NC}\n"
    
    for entry in "${dns_servers[@]}"; do
        IFS=';' read -r dns name <<< "$entry"
        current=$((current + 1))
        
        show_progress "Testing $name" $current $total
        local response_time=$(dig @"$dns" google.com +time=2 +tries=1 2>/dev/null | grep "Query time:" | awk '{print $4}')
        
        if [ ! -z "$response_time" ] && [ "$response_time" -lt "$fastest_time" ]; then
            fastest_time=$response_time
            fastest_dns=$dns
            fastest_name=$name
        fi
        sleep 0.5
    done
    echo -e "\n"
    print_status "Fastest DNS Found" "OK"
    echo -e "${BOLD}${GREEN}► $fastest_name ($fastest_dns) - ${fastest_time}ms${NC}\n"
    PRIMARY_DNS=$fastest_dns
}

# Configure DNS
configure_dns() {
    print_section "Configuring DNS"
    case $OS in
        debian)
            cat > /etc/resolv.conf << EOF
nameserver $PRIMARY_DNS
nameserver $SECONDARY_DNS
nameserver $TERTIARY_DNS
nameserver $QUATERNARY_DNS
options edns0 trust-ad
EOF
            resolvconf -u
            ;;
        fedora|arch)
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
    print_status "DNS Configuration" "OK"
}

# Configure DNSMasq
setup_dnsmasq() {
    print_section "Setting up DNSMasq"
    cat > /etc/dnsmasq.conf << EOF
server=$PRIMARY_DNS
server=$SECONDARY_DNS
cache-size=1000
no-negcache
dns-forward-max=150
no-resolv
EOF
    
    systemctl enable dnsmasq >/dev/null 2>&1
    systemctl restart dnsmasq >/dev/null 2>&1
    print_status "DNSMasq Configuration" "OK"
}

# Configure Stubby
setup_stubby() {
    print_section "Setting up DNS-over-TLS"
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

    systemctl enable stubby >/dev/null 2>&1
    systemctl restart stubby >/dev/null 2>&1
    print_status "DNS-over-TLS Configuration" "OK"
}

# Test configuration
test_configuration() {
    print_section "Testing DNS Configuration"
    
    local test_domains=("google.com" "cloudflare.com" "github.com")
    local total_time=0
    local tests_passed=0
    local total_tests=${#test_domains[@]}
    
    echo -e "${DIM}Validating DNS resolution and performance...${NC}\n"
    
    for domain in "${test_domains[@]}"; do
        printf "${ITALIC}Testing %-20s${NC}" "$domain"
        if response_time=$(dig "$domain" +short | grep -v ";" | head -n 1 | xargs ping -c 1 -W 2 2>/dev/null | grep "time=" | cut -d "=" -f 4 | cut -d " " -f 1); then
            echo -e "${GREEN}[✓] ${response_time}ms${NC}"
            total_time=$(echo "$total_time + $response_time" | bc)
            tests_passed=$((tests_passed + 1))
        else
            echo -e "${RED}[✗] Failed${NC}"
        fi
    done
    
    echo
    if [ $tests_passed -eq $total_tests ]; then
        local avg_time=$(echo "scale=2; $total_time / $total_tests" | bc)
        print_status "Overall DNS Status" "OK"
        echo -e "${BOLD}${GREEN}► Average Response Time: ${avg_time}ms${NC}"
    else
        print_status "Overall DNS Status" "WARN"
        echo -e "${BOLD}${YELLOW}► $tests_passed/$total_tests tests passed${NC}"
    fi
}

# Main function
main() {
    print_banner
    
    # Check if help is requested
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        echo -e "${BOLD}Usage:${NC}"
        echo -e "  sudo ./$(basename $0) [OPTIONS]"
        echo
        echo -e "${BOLD}Options:${NC}"
        echo -e "  -h, --help     Show this help message"
        echo -e "  -v, --version  Show version information"
        echo
        echo -e "${BOLD}Description:${NC}"
        echo "  This tool optimizes your DNS configuration for better"
        echo "  performance and security. It automatically selects the"
        echo "  fastest DNS servers and configures DNS-over-TLS for"
        echo "  encrypted queries."
        echo
        echo -e "${BOLD}For more information and updates, visit:${NC}"
        echo "  https://github.com/q4n0/dns-config"
        echo
        exit 0
    fi

    print_section "Checking Prerequisites"
    check_root
    detect_os
    install_requirements
    get_active_connection
    find_fastest_dns
    configure_dns
    setup_dnsmasq
    setup_stubby
    test_configuration
    
    print_header() {
        printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
        echo -e "${BOLD}${GREEN}                              Configuration Complete${NC}"
        printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
        echo -e "${GREEN}DNS configuration has been successfully completed!${NC}\n"
    }
    
    print_header
}

# Run main function with arguments
main "$@"
