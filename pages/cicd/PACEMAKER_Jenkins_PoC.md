# PACEMAKER Jenkins PoC

## Prerequisits
### Servers
* First node:
    * Hostname: node-a
    * IP Address: 192.168.2.114
    * User with ssh and sudo access: yyovkov
    * Second raw HDD "/dev/vdb"
* Second node:
    * Hostname: node-b
    * IP Address: 192.168.2.115
    * User with ssh and sudo access: yyovkov
    * Second raw HDD "/dev/vdb"


## NOTES:
All commands are executed on node-a, unsled otherwise specified.

## Installation and Setup
### Exchange user authentications on both hosts
NOTE: This part includes manual action, as we do not want to share the password in clear text
```bash
$ ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ""
$ ssh-copy-id node-b

$ ssh -t node-b 'ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ""'
$ ssh -t node-b 'ssh-copy-id node-a'
```

### Update and Install Required Software
```bash
$ sudo lvextend -L +512M /dev/vg_$(hostname -s)/lv_var
$ sudo xfs_growfs /dev/vg_$(hostname -s)/lv_var
$ sudo yum -y install epel-release
$ sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
$ screen -md sudo yum -y update

$ ssh -t node-b 'sudo lvextend -L +512M /dev/vg_$(hostname -s)/lv_var'
$ ssh -t node-b 'sudo xfs_growfs /dev/vg_$(hostname -s)/lv_var'
$ ssh -t node-b 'sudo yum -y install epel-release'
$ ssh -t node-b 'sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm'
$ ssh -t node-b 'sudo yum -y install epel-release'
$ ssh -t node-b 'screen sudo yum -y update'

$ ssh -t node-b 'sudo reboot'
$ sudo reboot
```

### Setting up Firewall
```bash
$ sudo firewall-cmd --permanent --add-service=high-availability
$ sudo firewall-cmd --permanent --add-service=http
$ sudo firewall-cmd --permanent --add-service=https
$ sudo firewall-cmd --permanent --add-port=7789/tcp
$ sudo firewall-cmd --reload

$ ssh -t node-b 'sudo firewall-cmd --permanent --add-service=high-availability'
$ ssh -t node-b 'sudo firewall-cmd --permanent --add-service=http'
$ ssh -t node-b 'sudo firewall-cmd --permanent --add-service=https'
$ ssh -t node-b 'sudo firewall-cmd --permanent --add-port=7789/tcp'
$ ssh -t node-b 'sudo firewall-cmd --reload'
```

### Allow WebServer to access network
```bash
$ sudo setsebool httpd_can_network_connect 1 -P

$ ssh -t node-b 'sudo setsebool httpd_can_network_connect 1 -P'
```


### Install and Configure Shared Disk (DRBD)
```bash
$ sudo yum -y install drbd90-utils drbd90-utils-sysvinit kmod-drbd90
$ sudo yum -y install policycoreutils-python
$ sudo semanage permissive -a drbd_t
$ sudo sed -i -e "s/write_cache_state.*/write_cache_state = 0/" /etc/lvm/lvm.conf
$ echo "resource jenkins {
        net {
            protocol C;
            after-sb-0pri discard-zero-changes;
            after-sb-1pri discard-secondary;
            after-sb-2pri disconnect;
        }
        meta-disk internal;
        device /dev/drbd0 ;
        disk /dev/vdb;
        on node-a { address 192.168.2.114:7789; }
        on node-b { address 192.168.2.115:7789; }
}" | sudo tee /etc/drbd.d/jenkins.res
$ sudo drbdadm create-md jenkins
$ sudo systemctl disable drbd

$ ssh -t node-b 'sudo yum -y install drbd90-utils drbd90-utils-sysvinit kmod-drbd90'
$ ssh -t node-b 'sudo yum -y install policycoreutils-python'
$ ssh -t node-b 'sudo semanage permissive -a drbd_t'
$ ssh -t node-b 'sudo sed -i -e "s/write_cache_state.*/write_cache_state = 0/" /etc/lvm/lvm.conf'
$ ssh -t node-b 'echo "resource jenkins {
        net { 
            protocol C;
            after-sb-0pri discard-zero-changes;
            after-sb-1pri discard-secondary;
            after-sb-2pri disconnect;
        }
        meta-disk internal;
        device /dev/drbd0 ;
        disk /dev/vdb;
        on node-a { address 192.168.2.114:7789; }
        on node-b { address 192.168.2.115:7789; }
}" | sudo tee /etc/drbd.d/jenkins.res'
$ ssh -t node-b 'sudo drbdadm create-md jenkins'
$ ssh -t node-b 'sudo systemctl disable drbd'
```

### Initialize drbd drive
```bash
$ sudo systemctl start drbd
$ ssh -t node-b 'sudo systemctl start drbd'
$ sudo drbdadm up jenkins
$ ssh -t node-b 'sudo drbdadm up jenkins'
$ sudo drbdadm primary jenkins --force

$ sudo pvcreate /dev/drbd/by-res/jenkins/0
$ sudo vgcreate vg_jenkins /dev/drbd/by-res/jenkins/0
$ for lv in lv_lib lv_log lv_cache; do sudo lvcreate -L2G -n $lv vg_jenkins; sudo mkfs.xfs /dev/vg_jenkins/$lv; done
$ sudo vgchange -an vg_jenkins
$ sudo drbdadm secondary jenkins
$ ssh -t node-b 'sudo systemctl stop drbd'
$ sudo systemctl stop drbd
```

### Install and configure Cluster Software (pacemaker)
```bash
$ sudo yum -y install pacemaker pcs resource-agents
$ echo CHANGEME | sudo passwd --stdin hacluster
$ sudo systemctl enable pcsd
$ sudo systemctl start pcsd

$ ssh -t node-b 'sudo yum -y install pacemaker pcs resource-agents'
$ ssh -t node-b 'echo CHANGEME | sudo passwd --stdin hacluster'
$ ssh -t node-b 'sudo systemctl enable pcsd'
$ ssh -t node-b 'sudo systemctl start pcsd'
```

### Configure Jenkins Cluster
```bash
$ sudo pcs cluster auth -u hacluster -p CHANGEME node-a node-b
$ sudo pcs cluster setup --name jenkins_ha --start --enable --encryption 1 node-a node-b
$ sudo pcs property set no-quorum-policy=ignore
```

### Disable STONITH during cluster setup
```bash
$ sudo pcs property set stonith-enabled=false
```

### Setup LVM staff:
TODO: Automate this configuration
```bash
$ sudo ex -sc "%s/use_lvmetad = 1/use_lvmetad = 0/g|x" /etc/lvm/lvm.conf
$ sudo ex -sc "%s/# volume_list.*$/volume_list = \[ \"vg_$(hostname -s)\" \]/g|x" /etc/lvm/lvm.conf

$ ssh -t node-b 'sudo ex -sc "%s/use_lvmetad = 1/use_lvmetad = 0/g|x" /etc/lvm/lvm.conf'
$ ssh -t node-b 'sudo ex -sc "%s/# volume_list.*$/volume_list = \[ \"vg_$(hostname -s)\" \]/g|x" /etc/lvm/lvm.conf'

$ sudo systemctl disable lvm2-lvmetad.service
$ ssh -t node-b 'sudo systemctl disable lvm2-lvmetad.service'
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
```

### Add Clouster Resource for Virtual IP Address
```bash
$ sudo pcs resource create jenkins-ip ocf:heartbeat:IPaddr2 ip=192.168.2.201 \
    cidr_netmask=32 op monitor interval=30s
```

### Install Jenkins and Create Cluster Resource jenkins-service
```bash
$ sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
$ sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
$ sudo yum -y install jenkins java-1.8.0-openjdk
$ sudo systemctl disable jenkins

$ ssh -t node-b 'sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo'
$ ssh -t node-b 'sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key'
$ ssh -t node-b 'sudo yum -y install jenkins java-1.8.0-openjdk'
$ ssh -t node-b 'sudo systemctl disable jenkins'

$ sudo pcs resource create jenkins-service lsb:jenkins
```

### Install and Configure NGINX
```bash
$ sudo yum -y install nginx
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

$ ssh -t node-b 'sudo yum -y install nginx'
$ ssh -t node-b ' echo "location /server-status {
    stub_status on;
    access_log   off;
    allow all;
    deny all;
}" | sudo tee /etc/nginx/default.d/status_page.conf'
$ ssh -t node-b 'echo "proxy_buffers 16 64k;
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
$ ssh -t node-b 'sudo sed -e "/.*location\ \//,+2d" -i /etc/nginx/nginx.conf'
```

### Setup NGINX Cluster resource jenkins-proxy
```bash
$ sudo pcs resource create jenkins-proxy  ocf:heartbeat:nginx configfile=/etc/nginx/nginx.conf op monitor timeout="5s" interval="5s"
```

###  Creating Cluster Resource Group
```bash
$ sudo pcs resource group add jenkins jenkins-vg jenkins-fs-cache jenkins-fs-lib jenkins-fs-log jenkins-ip jenkins-service jenkins-proxy
$ sudo pcs constraint colocation add jenkins master-jenkins-drbd INFINITY with-rsc-role=Master
$ sudo pcs constraint order promote master-jenkins-drbd then start jenkins
```

### Cleanup Error
```bash
$ sudo pcs resource cleanup --node node-a
$ sudo pcs resource cleanup --node node-b
```