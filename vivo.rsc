# Bridge
/interface bridge
add igmp-snooping=yes name=bridge

# VLAN
/interface vlan
add interface=ether1 name="Internet" vlan-id=10
add interface=ether1 name="IPTV" vlan-id=20

# PPPoE
/interface pppoe-client
add add-default-route=yes disabled=no interface="Internet" name="Vivo" use-peer-dns=yes user=cliente@cliente password=cliente

# DNS IPTV
/ip dhcp-server option
add code=6 name="STB" value="'177.16.30.67''177.16.30.7'"

# DNS
/ip dns
set allow-remote-requests=yes

# DHCP
/ip pool
add name=dhcp ranges=192.168.10.2-192.168.10.254
/ip dhcp-server
add address-pool=dhcp disabled=no interface=bridge lease-time=30m name=dhcp
/ip address
add address=192.168.10.1/24 interface=bridge network=192.168.10.0
/ip dhcp-server network
add address=192.168.10.0/24 gateway=192.168.10.1

# Ethernet Ports
/interface bridge port
add bridge=bridge fast-leave=yes interface=ether2
add bridge=bridge fast-leave=yes interface=ether3
add bridge=bridge fast-leave=yes interface=ether4
add bridge=bridge fast-leave=yes interface=ether5

# Interface Members
/interface list member
add interface=ether1 list=WAN
add interface=bridge list=LAN

# Discovery
/ip neighbor discovery-settings
set discover-interface-list=LAN
/interface detect-internet
set detect-interface-list=all

# DHCP Client
/ip dhcp-client
add add-default-route=no disabled=no interface=IPTV
add add-default-route=no interface=ether1 use-peer-dns=no use-peer-ntp=no

# Firewall List
/ip firewall address-list
add address=172.28.0.0/14 list=IPTV
add address=201.0.52.0/23 list=IPTV
add address=200.161.71.0/24 list=IPTV
add address=177.16.0.0/16 list=IPTV
add address=239.0.0.0/8 list=IPTV
add address=224.0.0.0/4 list=IPTV
add address=237.0.0.0/8 list=IPTV
add address=192.168.10.0/24 list=LAN
add address=0.0.0.0 list=WAN

# Firewall Config
/ip firewall filter
add action=drop chain=input comment="Drop all not coming from LAN" in-interface=!LAN protocol=tcp
add action=accept chain=input comment="Allow IPTV Addresses" in-interface=IPTV src-address-list=IPTV disabled=no
add action=accept chain=input comment="Allow IGMP" in-interface=IPTV protocol=igmp disabled=no

# Mangle   
/ip firewall mangle
add action=mark-connection chain=prerouting dst-address-list=WAN new-connection-mark=HairPin passthrough=yes src-address-list=LAN

# NAT
/ip firewall nat
add action=masquerade chain=srcnat comment="NAT Internet" out-interface=Vivo
add action=masquerade chain=srcnat comment="NAT HairPin" connection-mark=HairPin
add action=masquerade chain=srcnat comment="NAT IPTV" out-interface=IPTV

# Static Routes
/ip route
add disabled=no dst-address=177.16.30.0/23 gateway=10.197.128.1
add disabled=no dst-address=172.28.0.0/14 gateway=10.197.128.1
add check-gateway=ping disabled=no distance=1 dst-address=201.0.52.0/23 gateway=10.197.128.1 scope=30 target-scope=10
add check-gateway=ping disabled=no distance=1 dst-address=200.161.71.40/30 gateway=10.197.128.1 scope=30 target-scope=10
add check-gateway=ping disabled=no distance=1 dst-address=200.161.71.48/31 gateway=10.197.128.1 scope=30 target-scope=10
add check-gateway=ping disabled=no distance=1 dst-address=200.161.71.46/31 gateway=10.197.128.1 scope=30 target-scope=10

# IGMP Proxy (multicast package required)
/routing igmp-proxy
set query-interval=10s quick-leave=yes
/routing igmp-proxy interface
add alternative-subnets=177.16.0.0/14 interface=IPTV upstream=yes
add interface=bridge

# Time
/system clock
set time-zone-name=America/Sao_Paulo
/system ntp client 
set enabled=yes primary-ntp=br.pool.ntp.org

# Scripts
/system scheduler
add interval=30s name=public-ip on-event=\
    ":local IP [/ip address get [find interface=Vivo] value-name=address]\r\
    \n/ip firewall address-list set [find where list=\"WAN\"] address=\$IP" policy=read,write

# Tool
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN

# Logs
#/system logging 
#add topics=dhcp
