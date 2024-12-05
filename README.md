# ModDNS: Universal Network Performance Optimizer

## 🌐 Overview

ModDNS is an advanced, cross-platform DNS configuration and network optimization utility designed to enhance your system's network performance, security, and reliability. This powerful tool automatically selects the fastest DNS servers, configures network parameters, and provides comprehensive network diagnostics across multiple Linux distributions.

## ✨ Key Features

- **Cross-Platform Compatibility**: Supports Debian, Ubuntu, Fedora, CentOS, Arch Linux, Manjaro, and OpenSUSE
- **Intelligent DNS Selection**: Automatically identifies and configures the fastest DNS servers
- **Network Performance Optimization**: Applies advanced TCP/UDP and network core performance tweaks
- **Comprehensive Logging**: Detailed logging with timestamped, categorized messages
- **Robust Error Handling**: Comprehensive checks and fallback mechanisms
- **Security-Focused**: Configures DNS with multiple redundant servers
- **Easy-to-Use**: Single command execution with minimal user intervention

## 🚀 Prerequisites

- Linux-based operating system
- Root/sudo privileges
- Internet connection
- Supported package managers (apt, dnf, pacman, zypper)

## 📦 Installation

### Method 1: Direct Download
```bash
wget https://github.com/q4n0/moddns/raw/main/moddns.sh
chmod +x moddns.sh
```

### Method 2: Git Clone
```bash
git clone https://github.com/q4n0/moddns.git
cd moddns
chmod +x moddns.sh
```

## 🔧 Usage

### Basic Usage
```bash
sudo ./moddns.sh
```

### Advanced Options (Future Implementations)
- `-v, --verbose`: Increase logging verbosity
- `--reset`: Reset to default network configurations
- `--test`: Run network performance diagnostics without applying changes

## 🔍 What ModDNS Does

1. **OS Detection**: Automatically identifies your Linux distribution
2. **Dependency Check**: Installs required network utilities
3. **DNS Performance Testing**: 
   - Pings multiple DNS providers
   - Selects the fastest, most responsive DNS server
4. **Network Configuration**:
   - Updates `/etc/resolv.conf`
   - Configures NetworkManager
   - Applies network performance optimizations
5. **Comprehensive Testing**:
   - Verifies DNS resolution for multiple domains
   - Logs all actions and potential issues

## 🛡️ Security Considerations

- DNS servers are selected based on performance and reliability
- Configuration prevents potential DNS leaks
- Immutable resolv.conf prevents unauthorized modifications
- Detailed logging for auditing and troubleshooting

## 📋 Logging

Detailed logs are maintained at `/var/log/dns_optimizer.log`, providing:
- Timestamp of actions
- Action types (INFO, WARN, ERROR, SUCCESS)
- Specific details about network configuration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a pull request

## 🐛 Reporting Issues

Please report issues on our GitHub repository, including:
- Your Linux distribution
- Output of the script
- Contents of `/var/log/dns_optimizer.log`

## 🌟 Disclaimer

ModDNS is provided "as-is" without warranties. Always review and understand the script before running, and maintain backups of critical system configurations.

---

**Created by [B0URN3]**  
*Enhancing network performance, one configuration at a time.*
