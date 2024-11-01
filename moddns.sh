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

# Terminal width
TERM_WIDTH=$(tput cols)

# UI Helper Functions
print_header() {
    local text="$1"
    local padding=$(( (TERM_WIDTH - ${#text} - 2) / 2 ))
    echo
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    printf "%${padding}s$BOLD$BLUE %s $NC%${padding}s\n" "" "$text" ""
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    echo
}

print_section() {
    local text="$1"
    echo -e "\n${BOLD}${CYAN}▶ ${text}${NC}"
    echo -e "${DIM}$(printf '%.s─' $(seq 1 $TERM_WIDTH))${NC}"
}

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

show_spinner() {
    local pid=$1
    local text=$2
    local spin='-\|/'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r${ITALIC}%-50s${NC} ${BLUE}[${spin:$i:1}]${NC}" "$text"
        sleep .1
    done
    printf "\r%-50s${GREEN}[✓]${NC}\n" "$text"
}

# Enhanced version of find_fastest_dns
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
}

# Enhanced version of test_configuration
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

# Main script execution with improved UI
main() {
    clear
    print_header "DNS Configuration Utility"
    
    # Check root with better UI
    print_section "Checking Prerequisites"
    if [ "$EUID" -ne 0 ]; then
        print_status "Root Privileges" "FAIL"
        echo -e "${RED}Please run this script as root or with sudo${NC}"
        exit 1
    fi
    print_status "Root Privileges" "OK"
    
    # Detect OS with better UI
    detect_os &
    show_spinner $! "Detecting Operating System"
    
    # Install requirements with progress
    print_section "Installing Required Packages"
    install_requirements &
    show_spinner $! "Installing Dependencies"
    
    # Network detection with better UI
    print_section "Network Configuration"
    get_active_connection &
    show_spinner $! "Detecting Network Interfaces"
    
    # Find fastest DNS with progress bar
    find_fastest_dns
    
    # Configure DNS with status updates
    print_section "Applying DNS Configuration"
    configure_dns &
    show_spinner $! "Updating DNS Settings"
    
    setup_dnsmasq &
    show_spinner $! "Configuring DNSMasq"
    
    setup_stubby &
    show_spinner $! "Setting up DNS-over-TLS"
    
    # Test configuration with detailed results
    test_configuration
    
    print_header "Configuration Complete"
    echo -e "${GREEN}DNS configuration has been successfully completed!${NC}\n"
}

# Run main function
main "$@"
