# version
# Press <tab> when the installation dvd boot and append below text after after
# the "vmlinuz line":
# inst.ks=http://castle.yyovkov.net/rhce-01.ks ksdevice=p2p1 ip=192.168.10.121 netmask=255.255.255.0 gateway=192.168.10.1 nameserver=8.8.8.8
# System authorization information
#
# Install Command on KVM Server:
# virt-install --name=LAB_rhce_01__59121 \
# --location=/var/lib/virtpools/system/CentOS/CentOS-7.0-1406-x86_64-DVD.iso \
# --disk "pool=local,size=99,sparse=false,perms=rw" \
# --extra-args="ks=http://castle.yyovkov.net/rhce-01.ks ksdevice=eth0 ip=192.168.10.121 netmask=255.255.255.0 gateway=192.168.10.1 dns=192.168.10.3" \
# --graphics "vnc,listen=0.0.0.0,port=59121" \
# --network bridge=test0 \
# --vcpus=2 --ram=1024 \
# --os-variant=centos7.0
#
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
cdrom
# Use graphical install
graphical
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=vda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
# Firewall Settings
firewall --enabled --port=22:tcp --port=5901:tcp
# Selinux settings
selinux --enforcing
# Reboot after install
reboot

# Network information
network --bootproto=static --device=eth0 --ip=192.168.10.123 --netmask=255.255.255.0 --gateway=192.168.10.1 --nameserver=192.168.10.3 --onboot=yes
network  --hostname=rhce-desktop.example.com

# Root password
# rootpw --iscrypted $6$EIZfaMF0CUAvb0XW$prlyM.NVYXMZk4OiG8nJpFB9qDFKt.m8jofUZHAkowg4g.basgkfmPxMiX45Aoy2brG1zGO7uY5Qte4MZHY8q0
rootpw --plaintext mypassword
# System services
services --enabled="chronyd"
# System timezone
timezone Europe/Sofia --isUtc
user --groups=wheel --name=student --password=mypassword --plaintext --gecos="RHCE Student"
# System bootloader configuration
bootloader --append="crashkernel=auto" --location=mbr --boot-drive=vda
# Partition clearing information
clearpart --all --initlabel --drives=vda
# Disk partitioning information
part /boot --fstype="xfs" --ondisk=vda --size=1024
part swap --fstype="swap" --ondisk=vda --recommended
part pv.01 --fstype="lvmpv" --ondisk=vda --size=1 --grow
volgroup vg_rhce-01 --pesize=4096 pv.01
logvol /  --fstype="xfs" --grow --percent=100 --name=root --vgname=vg_rhce-01

%packages
@^gnome-desktop-environment
@core
vim
chrony
kexec-tools

%end

################################################################################
################################################################################
##                                                                            ##
##                     PostInstall Script                                     ##
##                                                                            ##
################################################################################
################################################################################
%post

################################################################################
# xterm window name change
cat > /etc/sysconfig/bash-prompt-xterm << 'EOF'
# File: /etc/sysconfig/bash-prompt-xterm
# Description:
#   This file changes the name of the window, while xterm is used (for example
#   using ssh connection to the host)
WINDOW_NAME="${USER}@${HOSTNAME}"
echo -ne "\033]0;${WINDOW_NAME}\007"
EOF
chmod +x /etc/sysconfig/bash-prompt-xterm

################################################################################
# Setting ssh-access to the server
#       * Enable ssh forwarding
#       * Disable Root Login
#       * Allow only "sshaccess" group  members to access via ssh
#       * Disable sshd naming resolution
cp /etc/ssh/sshd_config /etc/ssh/.orig-sshd_config
sed -i -e 's/GSSAPIAuthentication\ yes/\#GSSAPIAuthentication\ yes/g' \
    -e '/#X11UseLocalhost yes/a X11UseLocalhost no' \
    /etc/ssh/sshd_config
echo "
UseDNS no
GSSAPIAuthentication no" >> /etc/ssh/sshd_config

%end
