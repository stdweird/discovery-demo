#!/bin/bash

exec >/tmp/discovery.log 2>&1

#
# Run verbose
#
set -x

function helloworld {
    fqdn=$(hostname --fqdn)
    ips=$(hostname --all-ip-addresses | tr '\n' ' ')
    echo "HOST $fqdn $ips" | tee /dev/console
}

helloworld

#
# Set discovery env variables from kernel args
#   should be key=value, matching the prefix
#
KERNEL_PREFIX='discovery'
for disc in $(cat /proc/cmdline | sed "s/ /\n/g" | grep "$KERNEL_PREFIX"); do
    echo "Setting $disc"
    eval $disc
done


# Requires
# - network (wait_for_network?)
#   - set it in unitfile to wait for network
# - rpms
#   initscripts
#
# Start remote logging quattor/aii style
#
logport=517
deflogserver=$(ip route |grep default | cut -d ' ' -f 3 | tail -1)
logserver=${discovery_logserver:-$deflogserver}

# Send messages to tcp syslog server via bash /dev/tcp
(tail -f /tmp/discovery.log | awk '{print "<190>DISCOVERY: "$0; fflush(); system("usleep 1000 >& /dev/null");}' > /dev/tcp/$logserver/$logport) &
sleep 10
drainsleep=120


# make some space, move to /tmp (which is tmpfs)
for dir in /var/cache/yum /usr/lib; do
    mkdir -p $dir
    mv $dir /tmp
    ln -s /tmp/$(basename $dir) $(dirname $dir)
done

# some more debugging
systemctl restart sshd.service
systemctl status sshd.service
journalctl -u sshd.service

yum clean all
yum install -y OpenIPMI ipmitool lldpd
systemctl start ipmi

# hardware discovery

lspci -v

ip link
ip address
ip route

lldpctl -f keyvalue


for i in `ls /sys/class/net`; do
    ethtool -i $i
    biosdevname -i $i
done

ipmitool lan print
ipmitool bmc info


lsblk
df -h
mount

dmidecode

dmesg | head -1000
dmesg | tail -1000

helloworld

sleep 10

# custom codes

if [ ! -z $discovery_update_firmware ]; then
    yum install -y update-firmware-ugent
    update-system-firmware.sh
fi

if [ ! -z $discovery_mellanox_firmware ]; then
    yum install -y mstflint
    wget -O firmware "$discovery_mellanox_firmware"
    for pciid in $(lspci |grep Mellanox | sed "s/ .*//"); do
        mstflint -d $pciid q
        mstflint -d $pciid -y -i firmware b
    done
fi

if [ ! -z $discovery_conrep ]; then
    yum-config-manager --enable hp*
    yum install -y hp-health hp-scripting-tools
    wget -O conrep.new "$discovery_conrep"
    conrep -s -f conrep.old
    diff -u conrep.old conrep.new
    conrep -l -f conrep.new
fi

if [ ! -z $discovery_run_script ]; then
    wget -O script "$discovery_run_script"
    chmod +x script
    ./script
fi


# very last
helloworld
sleep $drainsleep
