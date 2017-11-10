# PaceMaker

## Prerequisits
### Servers
* First node:
    * Hostname: ts01-dvms007.nocompanytest.com
    * IP Address: 10.97.69.118
    * User with ssh and sudo access: yyovkov-c
    * Second raw HDD "/dev/sda3"
* Second node:
    * Hostname: ts01-dvms008.nocompanytest.com
    * IP Address: 10.97.71.9
    * User with ssh and sudo access: yyovkov-c
    * Second raw HDD "/dev/sda3"

### Install and Configure Shared Disk (DRBD)
* NOTE: Download below packages from ELRepo to 'drbd' directory on your computer
    * http://mirror.imt-systems.com/elrepo/elrepo/el7/x86_64/RPMS/drbd90-utils-9.1.0-1.el7.elrepo.x86_64.rpm
    * http://mirror.imt-systems.com/elrepo/elrepo/el7/x86_64/RPMS/kmod-drbd90-9.0.9-1.el7_4.elrepo.x86_64.rpm
    * http://mirror.imt-systems.com/elrepo/elrepo/el7/x86_64/RPMS/drbd90-utils-sysvinit-9.1.0-1.el7.elrepo.x86_64.rpm
* NOTE: Update "/etc/hosts" with records for cluster parties
    * 10.97.69.118	TS01-DVMS007
    * 10.97.71.9	TS01-DVMS008

* Copy packages to both nodes:
```bash 
$ scp -r drbd ts01-dvms007.nocompanytest.com:
$ scp -r drbd ts01-dvms008.nocompanytest.com:
```

### Execute on both machines:
* Add user to sudoers
```bash
$ echo "yyovkov-c    ALL=(ALL)         NOPASSWD: ALL" > /etc/sudoers.d/yyovkov
```

* Create /dev/sda3 partition on the dirve
I am doing this by hand for now, as this should be much easier and straigth-forward in normal environment.

## NOTES:
All commands below are executed on ts01-dvms007, unsled otherwise specified.

### Exchange user authentications on both hosts
NOTE: This part includes manual action, as we do not want to share the password in clear text
```bash
$ ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ""
$ ssh-copy-id ts01-dvms008

$ ssh -t ts01-dvms008 'ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ""'
$ ssh -t ts01-dvms008 'ssh-copy-id ts01-dvms007'
```

### Install and configure DRBD
* Install DRBD packages
```bash
$ cd /home/nocompanytest.com/yyovkov-c/drbd
$ sudo yum -y localinstall drbd90-utils-9.1.0-1.el7.elrepo.x86_64.rpm drbd90-utils-sysvinit-9.1.0-1.el7.elrepo.x86_64.rpm kmod-drbd90-9.0.9-1.el7_4.elrepo.x86_64.rpm
$ ssh -t ts01-dvms008 'cd drbd; sudo yum -y localinstall drbd90-utils-9.1.0-1.el7.elrepo.x86_64.rpm drbd90-utils-sysvinit-9.1.0-1.el7.elrepo.x86_64.rpm kmod-drbd90-9.0.9-1.el7_4.elrepo.x86_64.rpm'
```
* Configure LVM
```bash
$ sudo cp /etc/lvm/lvm.conf /etc/lvm/.orig-lvm.conf
$ sudo sed -i -e "s/write_cache_state.*/write_cache_state = 0/" /etc/lvm/lvm.conf

$ ssh -t ts01-dvms008 'sudo cp /etc/lvm/lvm.conf /etc/lvm/.orig-lvm.conf'
$ ssh -t ts01-dvms008 'sudo sed -i -e "s/write_cache_state.*/write_cache_state = 0/" /etc/lvm/lvm.conf'

$ sudo ex -sc "%s/use_lvmetad = 1/use_lvmetad = 0/g|x" /etc/lvm/lvm.conf
$ sudo ex -sc "%s/# volume_list.*$/volume_list = \[ \"centos\" \]/g|x" /etc/lvm/lvm.conf

$ ssh -t ts01-dvms008 'sudo ex -sc "%s/use_lvmetad = 1/use_lvmetad = 0/g|x" /etc/lvm/lvm.conf'
$ ssh -t ts01-dvms008 'sudo ex -sc "%s/# volume_list.*$/volume_list = \[ \"centos\" \]/g|x" /etc/lvm/lvm.conf'

$ sudo systemctl disable lvm2-lvmetad.service
$ ssh -t ts01-dvms008 'sudo systemctl disable lvm2-lvmetad.service'
```
* Configure DRBD shared disk resource
```bash
$ echo "resource jenkins {
        net {
            protocol C;
            after-sb-0pri discard-zero-changes;
            after-sb-1pri discard-secondary;
            after-sb-2pri disconnect;
        }
        meta-disk internal;
        device /dev/drbd0 ;
        disk /dev/sda3;
        on ts01-dvms007 { address 10.97.69.118:7789; }
        on ts01-dvms008 { address 10.97.71.9:7789; }
}" | sudo tee /etc/drbd.d/jenkins.res
$ sudo drbdadm create-md jenkins
$ sudo systemctl disable drbd

$ ssh -t ts01-dvms008 'echo "resource jenkins {
        net {
            protocol C;
            after-sb-0pri discard-zero-changes;
            after-sb-1pri discard-secondary;
            after-sb-2pri disconnect;
        }
        meta-disk internal;
        device /dev/drbd0 ;
        disk /dev/sda3;
        on ts01-dvms007 { address 10.97.69.118:7789; }
        on ts01-dvms008 { address 10.97.71.9:7789; }
}" | sudo tee /etc/drbd.d/jenkins.res'
$ ssh -t ts01-dvms008 'sudo drbdadm create-md jenkins'
$ ssh -t ts01-dvms008 'sudo systemctl disable drbd'
```
* Start up shared drive
```bash
$ sudo systemctl start drbd
$ ssh -t ts01-dvms008 'sudo systemctl start drbd'
$ sudo drbdadm up jenkins
$ ssh -t ts01-dvms008 'sudo drbdadm up jenkins'
$ sudo drbdadm primary jenkins --force
```
* Create LVM layout and sync the drive
```
$ sudo pvcreate /dev/drbd/by-res/jenkins/0
$ sudo vgcreate vg_jenkins /dev/drbd/by-res/jenkins/0
$ for lv in lv_lib lv_log lv_cache lv_opt; do sudo lvcreate -L2G -n $lv vg_jenkins; sudo mkfs.xfs /dev/vg_jenkins/$lv; done
$ sudo vgchange -an vg_jenkins
$ sudo drbdadm secondary jenkins
```
* Stop DRBD
```bash
$ ssh -t ts01-dvms008 'sudo systemctl stop drbd'
$ sudo systemctl stop drbd
```

## Install and Configure Cluster Software
### Install cluster software
```bash
$ sudo yum -y install pacemaker pcs resource-agents
$ echo CHANGEME | sudo passwd --stdin hacluster
$ sudo systemctl enable pcsd
$ sudo systemctl start pcsd

$ ssh -t ts01-dvms008 'sudo yum -y install pacemaker pcs resource-agents'
$ ssh -t ts01-dvms008 'echo CHANGEME | sudo passwd --stdin hacluster'
$ ssh -t ts01-dvms008 'sudo systemctl enable pcsd'
$ ssh -t ts01-dvms008 'sudo systemctl start pcsd'
```
### Configure Jenkins Cluster
```bash
$ sudo pcs cluster auth -u hacluster -p CHANGEME ts01-dvms007 ts01-dvms008
$ sudo pcs cluster setup --name jenkins_ha --start --enable --encryption 1 ts01-dvms007 ts01-dvms008
$ sudo pcs property set no-quorum-policy=ignore
```
### Disable STONITH during cluster setup
```bash
$ sudo pcs property set stonith-enabled=false
```

### Add Cluster Resource for Shared Disk
```bash
$ sudo pcs resource create jenkins-drbd ocf:linbit:drbd drbd_resource=jenkins
$ sudo pcs resource master master-jenkins-drbd jenkins-drbd master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
$ sudo pcs resource cleanup jenkins-drbd
$ sudo pcs resource create jenkins-vg ocf:heartbeat:LVM volgrpname=vg_jenkins exclusive=true

$ sudo pcs resource create jenkins-fs-cache ocf:heartbeat:Filesystem device=/dev/vg_jenkins/lv_cache directory=/var/cache/jenkins fstype=xfs
$ sudo pcs resource create jenkins-fs-lib ocf:heartbeat:Filesystem device=/dev/vg_jenkins/lv_lib directory=/var/lib/jenkins fstype=xfs
$ sudo pcs resource create jenkins-fs-log ocf:heartbeat:Filesystem device=/dev/vg_jenkins/lv_log directory=/var/log/jenkins fstype=xfs
$ sudo pcs resource create jenkins-fs-opt ocf:heartbeat:Filesystem device=/dev/vg_jenkins/lv_opt directory=/opt/jenkins fstype=xfs

$ sudo chown service-jenkins: /var/cache/jenkins /var/lib/jenkins /var/log/jenkins /opt/jenkins
```

### Add Clouster Resource for Virtual IP Address
```bash
#  devops-vip.nocompanytest.com - 10.97.71.110
$ sudo pcs resource create jenkins-ip ocf:heartbeat:IPaddr2 ip=10.97.71.110 cidr_netmask=32 op monitor interval=30s
```

## Install Jenkins:
### Install software
```bash
$ sudo yum -y install jenkins java-1.8.0-openjdk
$ ssh -t ts01-dvms008 'sudo yum -y install jenkins java-1.8.0-openjdk'

$ sudo mkdir /opt/jenkins/etc /opt/jenkins/lib
$ sudo mkdir /opt/jenkins/etc/init.d
$ sudo cp /tmp/jenkins.war /opt/jenkins/lib/
$ sudo cp /tmp/initd-jenkins /opt/jenkins/etc/init.d/jenkins
```
### Add resource to the cluster
```bash
# $ sudo pcs resource create jenkins-service lsb:/opt/jenkins/etc/init.d/jenkins 
$ sudo pcs resource create jenkins-service lsb:jenkins
```


### Install and Configure NGINX proxy
```bash
$ sudo yum -y install nginx
$ ssh -t ts01-dvms008 'sudo yum -y install nginx'
$ echo "location /server-status {
    stub_status on;
    access_log   off;
    allow all;
    deny all;
}" | sudo tee /etc/nginx/default.d/status_page.conf
$ echo "proxy_buffers 16 64k;
proxy_buffer_size 128k;

location / {
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    proxy_redirect off;

    proxy_pass  http://127.0.0.1:8080;
    proxy_set_header    Host            \$host;
    proxy_set_header    X-Real-IP       \$remote_addr;
    proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto http;
}" | sudo tee /etc/nginx/default.d/jenkins.conf
$ sudo sed -e "/.*location\ \//,+2d" -i /etc/nginx/nginx.conf

$ ssh -t ts01-dvms008 ' echo "location /server-status {
    stub_status on;
    access_log   off;
    allow all;
    deny all;
}" | sudo tee /etc/nginx/default.d/status_page.conf'
$ ssh -t ts01-dvms008 'echo "proxy_buffers 16 64k;
proxy_buffer_size 128k;

location / {
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    proxy_redirect off;

    proxy_pass  http://127.0.0.1:8080;
    proxy_set_header    Host            \$host;
    proxy_set_header    X-Real-IP       \$remote_addr;
    proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto http;
}" | sudo tee /etc/nginx/default.d/jenkins.conf'
$ ssh -t ts01-dvms008 'sudo sed -e "/.*location\ \//,+2d" -i /etc/nginx/nginx.conf'
```

### Configure cluster resource for NGINX
```bash
# $ sudo pcs resource create jenkins-proxy  ocf:heartbeat:nginx configfile=/etc/nginx/nginx.conf op monitor timeout="5s" interval="5s"
```

###  Creating Cluster Resource Group
```bash
$ sudo pcs resource group add jenkins jenkins-vg jenkins-fs-cache jenkins-fs-lib jenkins-fs-opt jenkins-fs-log jenkins-ip jenkins-service jenkins-proxy
$ sudo pcs constraint colocation add jenkins master-jenkins-drbd INFINITY with-rsc-role=Master
$ sudo pcs constraint order promote master-jenkins-drbd then start jenkins
```

### Cleanup Error
```bash
$ sudo pcs resource cleanup --node ts01-dvms007
$ sudo pcs resource cleanup --node ts01-dvms008
```
