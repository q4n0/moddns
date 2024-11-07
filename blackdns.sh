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
    echo '                                            █████                 '
    echo '                                           ██████                 '
    echo '                                          ███████                 '
    echo '                                         ████████                 '
    echo '                                        █████████                 '
    echo '                                       ██████████                 '
    echo '                                      ███████████                 '
    echo '                                     ████████████                 '
    echo '                                    █████████████                 '
    echo '                                   ██████████████                 '
    echo '                                  ███████████████                 '
    echo '                                 ████████████████                 '
    echo '                                █████████████████                 '
    echo '                               ██████████████████                 '
    echo '                              ███████████████████                 '
    echo '                             ████████████████████                 '
    echo '                            █████████████████████                 '
    echo '                           ██████████████████████                 '
    echo '                          ███████████████████████                 '
    echo '                         ████████████████████████                 '
    echo '                        ████████████████████████████             '
    echo -e "${BOLD}${WHITE}"
    echo '                        A R C H   L I N U X   D N S             '
    echo -e "${NC}"
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    echo -e "${BOLD}${PURPLE}                           DNS Configuration Utility${NC}"
    echo -e "${DIM}                               Version 1.2.0 - 2024${NC}"
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    echo
    echo -e "${BOLD}${CYAN}System Information:${NC}"
    
    # Get system information
    local os_name=$(cat /etc/os-release | grep "^NAME" | cut -d= -f2 | tr -d '"')
    local kernel=$(uname -r)
    local arch=$(uname -m)
    local hostname=$(hostname)
    
    echo -e "${BOLD}${WHITE}  • Distribution:${NC} $os_name"
    echo -e "${BOLD}${WHITE}  • Kernel:${NC} $kernel"
    echo -e "${BOLD}${WHITE}  • Architecture:${NC} $arch"
    echo -e "${BOLD}${WHITE}  • Hostname:${NC} $hostname"
    echo
    echo -e "${DIM}An advanced DNS configuration utility optimized for Arch-based systems${NC}"
    echo -e "${DIM}Automatically configures and optimizes DNS settings for enhanced performance${NC}"
    printf "%${TERM_WIDTH}s\n" | tr ' ' '═'
    echo
}

[Rest of the script remains unchanged...]
