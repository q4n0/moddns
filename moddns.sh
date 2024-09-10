#!/bin/bash

# Get the network connection name from the user
read -p "Enter the network connection name: " CONNECTION

# Static IP settings
IP_ADDRESS="192.168.0.9/24"
GATEWAY="192.168.0.1"
DNS_SERVERS="8.8.8.8 8.8.4.4"

# Apply the network settings
nmcli connection modify "$CONNECTION" ipv4.addresses "$IP_ADDRESS"
nmcli connection modify "$CONNECTION" ipv4.gateway "$GATEWAY"
nmcli connection modify "$CONNECTION" ipv4.dns "$DNS_SERVERS"
nmcli connection modify "$CONNECTION" ipv4.method manual

# Restart the network connection
nmcli connection down "$CONNECTION"
nmcli connection up "$CONNECTION"

echo "Network settings for $CONNECTION have been successfully applied."
