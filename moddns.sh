#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# DNS Server pools
declare -A DNS_SERVERS=(
    ["Google1"]="8.8.8.8"
    ["Google2"]="8.8.4.4"
    ["Cloudflare1"]="1.1.1.1"
    ["Cloudflare2"]="1.0.0.1"
    ["Quad91"]="9.9.9.9"
    ["Quad92"]="149.112.112.112"
    ["OpenDNS1"]="208.67.222.222"
    ["OpenDNS2"]="208.67.220.220"
    ["AdGuard1"]="94.140.14.14"
    ["AdGuard2"]="94.140.15.15"
)

# New Features Configuration
DNS_CACHE_SIZE="1024M"
ENABLE_IPV6=true
ENABLE_DNS_OVER_TLS=true
ENABLE_DNSSEC=true
ENABLE_SECURITY_SCAN=true
ENABLE_VPN_CHECK=true
ENABLE_BANDWIDTH_TEST=true
LOG_FILE="/var/log/dns_optimizer.log"

# Function to setup logging
setup_logging() {
    touch "$LOG_FILE"
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    echo "$(date): Starting DNS Optimizer Script" >> "$LOG_FILE"
}

# Function to check for DNS leaks
check_dns_leaks() {
    echo -e "${YELLOW}Checking for DNS leaks...${NC}"
    local leak_found=false
    
    # Test multiple DNS leak checking services
    local test_domains=("dnsleak.com" "ipleak.net" "dnsleaktest.com")
    
    for domain in "${test_domains[@]}"; do
        if dig +short "$domain" | grep -q "^[0-9]"; then
            echo -e "${RED}Potential DNS leak detected through $domain${NC}"
            leak_found=true
        fi
    done
    
    if [ "$leak_found" = false ]; then
        echo -e "${GREEN}No DNS leaks detected${NC}"
    fi
}

# Function to implement DNS caching
setup_dns_cache() {
    echo -e "${YELLOW}Setting up DNS cache...${NC}"
    
    # Install and configure DNSMasq
    pacman -Sy --noconfirm dnsmasq
    
    cat > /etc/dnsmasq.conf << EOF
cache-size=10000
neg-ttl=3600
local-ttl=3600
dns-forward-max=1024
min-cache-ttl=3600
max-cache-ttl=86400
EOF

    systemctl enable dnsmasq
    systemctl restart dnsmasq
}

# Function to setup DNS over TLS
setup_dns_over_tls() {
    if [ "$ENABLE_DNS_OVER_TLS" = true ]; then
        echo -e "${YELLOW}Setting up DNS over TLS...${NC}"
        
        # Install and configure Stubby
        pacman -Sy --noconfirm stubby
        
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
    fi
}

# Function to implement DNSSEC
setup_dnssec() {
    if [ "$ENABLE_DNSSEC" = true ]; then
        echo -e "${YELLOW}Setting up DNSSEC...${NC}"
        
        cat >> /etc/systemd/resolved.conf << EOF
[Resolve]
DNSSEC=true
DNSOverTLS=yes
Cache=yes
DNS=$PRIMARY_DNS $SECONDARY_DNS
FallbackDNS=$TERTIARY_DNS $QUATERNARY_DNS
EOF

        systemctl restart systemd-resolved
    fi
}

# Function to monitor DNS performance
monitor_dns_performance() {
    echo -e "${YELLOW}Starting DNS performance monitoring...${NC}"
    
    # Create monitoring directory
    mkdir -p /var/log/dns_monitor
    
    # Create monitoring script
    cat > /usr/local/bin/dns_monitor.sh << EOF
#!/bin/bash
while true; do
    date >> /var/log/dns_monitor/performance.log
    dig @$PRIMARY_DNS google.com | grep "Query time" >> /var/log/dns_monitor/performance.log
    sleep 300
done
EOF

    chmod +x /usr/local/bin/dns_monitor.sh
    
    # Create systemd service for monitoring
    cat > /etc/systemd/system/dns-monitor.service << EOF
[Unit]
Description=DNS Performance Monitor
After=network.target

[Service]
ExecStart=/usr/local/bin/dns_monitor.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable dns-monitor
    systemctl start dns-monitor
}

# Function to check VPN status
check_vpn_status() {
    if [ "$ENABLE_VPN_CHECK" = true ]; then
        echo -e "${YELLOW}Checking VPN status...${NC}"
        if ip link show | grep -q "tun0\|wg0"; then
            echo -e "${GREEN}VPN connection detected${NC}"
            # Ensure DNS isn't leaking through VPN
            check_dns_leaks
        else
            echo -e "${BLUE}No VPN connection detected${NC}"
        fi
    fi
}

# Function to test bandwidth
test_bandwidth() {
    if [ "$ENABLE_BANDWIDTH_TEST" = true ]; then
        echo -e "${YELLOW}Testing bandwidth...${NC}"
        # Install speedtest-cli if not present
        pacman -Sy --noconfirm speedtest-cli
        speedtest-cli --simple
    fi
}

# Function to implement security scanning
security_scan() {
    if [ "$ENABLE_SECURITY_SCAN" = true ]; then
        echo -e "${YELLOW}Performing security scan...${NC}"
        
        # Check for common vulnerabilities
        echo -e "${BLUE}Checking for common DNS vulnerabilities...${NC}"
        
        # Test for DNS rebinding protection
        if dig +short microsoft.com@$PRIMARY_DNS | grep -q "0.0.0.0"; then
            echo -e "${GREEN}DNS rebinding protection active${NC}"
        else
            echo -e "${RED}DNS rebinding protection not detected${NC}"
        fi
        
        # Test for DNS cache poisoning protection
        if dig +dnssec google.com @$PRIMARY_DNS | grep -q "RRSIG"; then
            echo -e "${GREEN}DNSSEC validation working${NC}"
        else
            echo -e "${RED}DNSSEC validation not detected${NC}"
        fi
    fi
}

# Enhanced main function
main() {
    setup_logging
    check_root
    install_requirements
    find_fastest_dns
    get_active_connection
    get_current_settings
    
    # New feature implementations
    setup_dns_cache
    setup_dns_over_tls
    setup_dnssec
    check_vpn_status
    test_bandwidth
    security_scan
    monitor_dns_performance
    
    optimize_dns
    check_dns_leaks
    
    # Create status report
    generate_report
}

# Function to generate status report
generate_report() {
    local report_file="/var/log/dns_optimizer_report.txt"
    echo -e "${YELLOW}Generating status report...${NC}"
    
    cat > "$report_file" << EOF
DNS Optimizer Report ($(date))
=============================
Primary DNS: $PRIMARY_DNS (${DNS_SERVERS[$PRIMARY_DNS]})
Secondary DNS: $SECONDARY_DNS
Tertiary DNS: $TERTIARY_DNS
Quaternary DNS: $QUATERNARY_DNS

Configuration Status:
-------------------
DNS over TLS: $(systemctl is-active stubby)
DNSSEC: $(if grep -q "DNSSEC=true" /etc/systemd/resolved.conf; then echo "Enabled"; else echo "Disabled"; fi)
DNS Cache: $(systemctl is-active dnsmasq)
VPN Status: $(if ip link show | grep -q "tun0\|wg0"; then echo "Connected"; else echo "Not Connected"; fi)

Performance Metrics:
-----------------
Average Response Time: $(dig @$PRIMARY_DNS google.com | grep "Query time" | awk '{print $4}') ms
Cache Hit Rate: $(journalctl -u dnsmasq | grep -c "cached") requests
Security Status: $(if [ "$ENABLE_SECURITY_SCAN" = true ]; then echo "Scanned"; else echo "Not Scanned"; fi)

Recent DNS Queries:
----------------
$(tail -n 10 /var/log/dns_monitor/performance.log)
EOF

    echo -e "${GREEN}Report generated at $report_file${NC}"
}

# Run the script
main
