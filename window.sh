#!/bin/bash

echo "Updating system..."
apt update -y

echo "Installing KVM & virtualization packages..."
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst bridge-utils

systemctl enable libvirtd
systemctl start libvirtd

echo "Checking virtualization support..."
egrep -c '(vmx|svm)' /proc/cpuinfo

echo "Creating Windows disk..."
qemu-img create -f qcow2 /root/win10.qcow2 120G

echo "Starting Windows 10 VM installer..."
virt-install \
--name win10 \
--memory 16384 \
--vcpus 8 \
--cpu host \
--disk path=/root/win10.qcow2,size=120 \
--cdrom /root/Win10.iso \
--os-variant win10 \
--network network=default \
--graphics vnc,listen=0.0.0.0 \
--boot uefi

echo "Setting up RDP port forwarding..."
VM_IP=$(virsh domifaddr win10 | grep ipv4 | awk '{print $4}' | cut -d/ -f1)

iptables -t nat -A PREROUTING -p tcp --dport 3389 -j DNAT --to-destination $VM_IP:3389
iptables -t nat -A POSTROUTING -j MASQUERADE

echo "Done!"
echo "After Windows installation:"
echo "Enable Remote Desktop inside Windows."
echo "Then connect via RDP using:"
echo "YOUR_VPS_PUBLIC_IP:3389"
