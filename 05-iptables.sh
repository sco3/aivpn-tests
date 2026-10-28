#!/usr/bin/env bash
set -euo pipefail

# Detect the primary external network interface
EXT_IFACE=$(ip route show default | awk '{print $5}' | head -n1)

if [ -z "$EXT_IFACE" ]; then
    echo "Error: Could not detect the default external network interface." >&2
    exit 1
fi

echo "Detected external interface: $EXT_IFACE"

# Enable IPv4 packet forwarding
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-aivpn-forward.conf

# Clean up any existing conflicting rules if needed, then insert/append fresh rules
# 1. Allow forwarding for dynamic TUN interfaces out to the external interface
iptables -C FORWARD -i tun+ -o "$EXT_IFACE" -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i tun+ -o "$EXT_IFACE" -j ACCEPT
iptables -C FORWARD -i "$EXT_IFACE" -o tun+ -m conntrack --ctstate RELATED,ESTABLISHED 2>/dev/null || iptables -I FORWARD 2 -i "$EXT_IFACE" -o tun+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# 2. Enable TCPMSS clamping to prevent MTU/fragmentation issues
iptables -C FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || iptables -I FORWARD 3 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# 3. Configure NAT (MASQUERADE) for the VPN subnet (10.0.0.0/24)
iptables -t nat -C POSTROUTING -s 10.0.0.0/24 -o "$EXT_IFACE" -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o "$EXT_IFACE" -j MASQUERADE

echo "AIVPN firewall and routing rules successfully applied."