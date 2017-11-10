# PACEMAKER Learning
[Pacemaker Documentation|http://clusterlabs.org/doc/en-US/Pacemaker/1.1-pcs/html/Clusters_from_Scratch/index.html]

## Prerequisites:
### Servers:
    * First node:
        * Hostname: node-a
        * IP Address: 192.168.2.114
        * User with ssh and sudo access: yyovkov
    * Second node:
        * Hostname: node-b
        * IP Address: 192.168.2.115
        * User with ssh and sudo access: yyovkov

## Node Setup
Execute below steps on each node
### Update Linux Installation
```bash
$ screen
$ sudo lvextend -L +512M /dev/vg_$(hostname -s)/lv_var
$ sudo xfs_growfs /dev/vg_$(hostname -s)/lv_var
$ sudo yum -y update
$ sudo reboot
```

### Exchange user authentications
```bash
$ ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ""
$ ssh-copy-id node-a # $ ssh-copy-id node-b
```

### Install Require Software
```bash
$ sudo yum -y install epel-release
$ sudo yum -y install git pacemaker pcs resource-agents
```

### Setup Nodes Security
```bash
$ sudo firewall-cmd --permanent --add-service=high-availability
$ sudo firewall-cmd --reload
# $ sudo setenforce 0
# $ sed -i.bak "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config
# $ sudo ssh-copy-id yyovkov@node-b # On node-b, the destination node should be "node-a"
# $ sudo cp ~/.ssh/authorized_keys /root/.ssh/authorized_keys
# $ sudo sed -i.bak "s/PermitRootLogin no/PermitRootLogin yes/g" /etc/ssh/sshd_config
# $ sudo systemctl restart sshd
# $ sudo usermod -a -G sshaccess root
```

### Setting Up PCSD daemon
```bash
# $ sudo ssh-keygen -t dsa -f ~/.ssh/id_dsa -N ""
$ echo CHANGEME | sudo passwd --stdin hacluster
# $ sudo usermod -a -G sshaccess hacluster
$ sudo systemctl enable pcsd
$ sudo systemctl start pcsd
```

## Configuring Cluster
#### Initial configuration
```bash
$ sudo pcs cluster auth node-a node-b
$ sudo pcs cluster setup --name jenkins_ha --start --enable node-a node-b
$ sudo pcs cluster start --all
```

### Disable temporary STONITH
```bash
$ sudo pcs property set stonith-enabled=false
$ sudo pcs property set no-quorum-policy=ignore
```

### Configure cluster ip address
```bash
$ sudo pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=192.168.2.201 cidr_netmask=32 op monitor interval=30s
```

################################################################################
# Experiment with NGINX
################################################################################
## Setup Jenkins in Cluster
### Install NGINX
```bash
$ sudo yum -y install nginx
$ sudo firewall-cmd --permanent --add-service=http
$ sudo firewall-cmd --permanent --add-service=https
$ sudo firewall-cmd --reload
$ sudo setsebool httpd_can_network_connect 1 -P

$ ssh -t node-b 'sudo yum -y install nginx'
$ ssh -t node-b 'sudo firewall-cmd --permanent --add-service=http'
$ ssh -t node-b 'sudo firewall-cmd --permanent --add-service=https'
$ ssh -t node-b 'sudo firewall-cmd --reload'
$ ssh -t node-b 'sudo setsebool httpd_can_network_connect 1 -P'
```

### Setup NGINX
```bash
$ sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/.orig-index.html
$ echo "<html>
    <meta http-equiv=\"refresh\" content=\"5\" />
    <body><br><center><b>My Test Site - $(hostname)</b></center></body>
</html>" | sudo tee /usr/share/nginx/html/index.html
$ echo "location /server-status {
    stub_status on;
    access_log   off;
    allow all;
    deny all;
}" | sudo tee /etc/nginx/default.d/status_page.conf

$ ssh -t node-b 'sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/.orig-index.html'
$ ssh -t node-b 'echo "<html>
    <meta http-equiv=\"refresh\" content=\"5\" />
    <body><br><center><b>My Test Site - $(hostname)</b></center></body>
</html>" | sudo tee /usr/share/nginx/html/index.html'
$ ssh -t node-b ' echo "location /server-status {
    stub_status on;
    access_log   off;
    allow all;
    deny all;
}" | sudo tee /etc/nginx/default.d/status_page.conf'
```

### Setup NGINX Cluster Resource
```bash
$ sudo pcs resource create WebProxy ocf:heartbeat:nginx configfile=/etc/nginx/nginx.conf op monitor timeout="5s" interval="5s"
$ sudo pcs constraint colocation add WebProxy virtual_ip INFINITY
$ sudo pcs constraint order virtual_ip then WebProxy
$ sudo pcs constraint location WebProxy prefers test01=50
$ sudo pcs cluster stop --all; sudo pcs cluster start --all
```


################################################################################
# Experiment with Jenkins
################################################################################
# Setup Jenkins in Cluster
### Setup Jenkins LVM
```bash
$ sudo lvcreate -L +5G -n lv_jenkins vg_$(hostname -s)
$ sudo mkfs.xfs /dev/vg_$(hostname -s)/lv_jenkins
$ sudo mkdir /var/lib/jenkins
$ echo -e "/dev/vg_$(hostname -s)/lv_jenkins /var/lib/jenkins\t\txfs\tdefaults\t1 2" | sudo tee -a /etc/fstab
$ sudo mount -a

$ ssh -t node-b 'sudo lvcreate -L +5G -n lv_jenkins vg_$(hostname -s)'
$ ssh -t node-b 'sudo mkfs.xfs /dev/vg_$(hostname -s)/lv_jenkins'
$ ssh -t node-b 'sudo mkdir /var/lib/jenkins'
$ ssh -t node-b 'echo -e "/dev/vg_$(hostname -s)/lv_jenkins /var/lib/jenkins\t\txfs\tdefaults\t1 2" | sudo tee -a /etc/fstab'
```

### Install Jenkins
```bash
$ sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
$ sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
$ sudo yum -y install jenkins java-1.8.0-openjdk
$ sudo systemctl disable jenkins

$ ssh -t node-b 'sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo'
$ ssh -t node-b 'sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key'
$ ssh -t node-b 'sudo yum -y install jenkins java-1.8.0-openjdk'
$ ssh -t node-b 'sudo systemctl disable jenkins'
```

### Configure NGINX redirection
```bash
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

### Add Jenkins to the cluster:
```bash
$ sudo pcs resource list lsb
$ sudo pcs resource create jenkins-service lsb:jenkins
$ sudo pcs constraint colocation add jenkins-service with WebProxy INFINITY
```


################################################################################
# Experiment with DRBD
################################################################################
## Experiment with DRBD
[Example Doc|http://www.learnitguide.net/2016/07/integrate-drbd-with-pacemaker-clusters.html]|
[Another Doc]|http://ittroubleshooter.in/setting-drbd-centosrhel-7-3/
### Install
```bash
$ sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
$ sudo yum -y install drbd90-utils drbd90-utils-sysvinit kmod-drbd90
$ sudo modprobe drbd
$ sudo firewall-cmd --permanent --add-port=7789/tcp
$ sudo firewall-cmd --reload

$ ssh -t node-b 'sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm'
$ ssh -t node-b 'sudo yum -y install drbd90-utils drbd90-utils-sysvinit kmod-drbd90'
$ ssh -t node-b 'sudo modprobe drbd'
$ ssh -t node-b 'sudo firewall-cmd --permanent --add-port=7789/tcp'
$ ssh -t node-b 'sudo firewall-cmd --reload'
```

### SELinux setup
```bash
# $ semanage permissive -a drbd_t
```

### Configure DRBD
```bash
$ sudo lvcreate -L 10G -n lv_drbd vg_$(hostname -s)
$ sudo cp /etc/drbd.d/global_common.conf /etc/drbd.d/.orig-global_common.conf
$ sudo vim /etc/drbd.d/testdata1.res
$ sudo drbdadm create-md testdata1
$ sudo systemctl enable drbd
$ sudo systemctl start drbd

$ ssh -t node-b 'sudo lvcreate -L 10G -n lv_drbd vg_$(hostname -s)'
$ ssh -t node-b 'sudo cp /etc/drbd.d/global_common.conf /etc/drbd.d/.orig-global_common.conf'
$ scp /etc/drbd.d/testdata1.res node-b:/tmp/testdata1.res
$ ssh -t node-b 'sudo cp /tmp/testdata1.res /etc/drbd.d/testdata1.res'
$ ssh -t node-b 'sudo drbdadm create-md testdata1'
$ ssh -t node-b 'sudo systemctl enable drbd'
$ ssh -t node-b 'sudo systemctl start drbd'

$ sudo drbdadm primary testdata1 --force
$ sudo mkfs.xfs /dev/drbd0
```

### Setting up Shared Drive
```bash
$ sudo cp /etc/lvm/lvm.conf /etc/lvm/.orig-lvm.conf
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
        on node-a {
            address 192.168.2.114:7789;
            disk /dev/vg_node-a/lv_jenkins ;
        }
        on node-b {
            address 192.168.2.115:7789;
            disk /dev/vg_node-b/lv_jenkins ;
        }
}" | sudo tee /etc/drbd.d/jenkins.res
$ sudo lvcreate -L 15G -n lv_jenkins vg_$(hostname -s)
$ sudo drbdadm create-md jenkins
$ sudo systemctl start drbd
$ sudo systemctl disable drbd
$ sudo drbdadm primary jenkins --force
$ sudo drbdadm secondary jenkins --force
# $ echo -e "/dev/drbd0 /var/lib/jenkins\t\txfs\tdefaults\t1 2" | sudo tee -a /etc/fstab
$ pcs resource describe ocf:linbit:drbd
$ sudo pcs resource create jenkins-drbd ocf:linbit:drbd drbd_resource=jenkins
$ sudo pcs resource master master-jenkins-drbd jenkins-drbd master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
$ sudo pcs resource cleanup jenkins-drbd

$ ssh -t node-b 'sudo cp /etc/lvm/lvm.conf /etc/lvm/.orig-lvm.conf'
$ ssh -t node-b 'sudo sed -i -e "s/write_cache_state.*/write_cache_state = 0/" /etc/lvm/lvm.conf'
```







































### Hints:
```bash
$ sudo pcs resource move virtual_ip node-a
$ sudo pcs cluster start --all
```

################################################################################
# OLD Materials
################################################################################
# Learn PaceMaker
Following this [Documentation|http://clusterlabs.org/doc/en-US/Pacemaker/1.1-pcs/html/Clusters_from_Scratch/index.html]

# PaceMaker for Jenkins
[Jenkins HA"http://www.voleg.info/jenkins-ha-cluster-centos-drbd-pacemaker-kvm.html]

## Install prerequsites
## Execute on both machines
```bash
$ sudo firewall-cmd --permanent --add-service=high-availability
$ sudo firewall-cmd --reload
$ sudo yum -y install pacemaker pcs resource-agents
$ echo CHANGEME | sudo passwd --stdin hacluster
$ sudo systemctl enable pcsd
$ sudo systemctl start pcsd
```


## List of the available resource standard
```bash
$ sudo pcs resource standards
ocf
lsb
service
systemd
```

## List of the available OCF resource providers
```bash
$ sudo pcs resource providers
heartbeat
openstack
pacemaker
```

## All the resource agents available for a specific OCF provider
```bash
$ sudo pcs resource agents ocf:heartbeat
CTDB
Filesystem
IPaddr
IPaddr2
IPsrcaddr
...
nfsnotify
nfsserver
nginx
oracle
oralsnr
pgsql
postfix
..
```

## Setup VIP Resource
```bash
$ sudo pcs resource create ClusterIP ocf:heartbeat:IPaddr2 ip=192.168.2.201 \
    cidr_netmask=32 op monitor interval=30s
$ sudo pcs status 
```

## Test Resource Migration
```bash
$ sudo pcs resource move ClusterIP node-b
$ sudo pcs status
$ sudo pcs resoruce move ClusterIP node-a
```

## Configure Cluster from Scratch
### Install Apache
```bash
$ sudo yum install -y httpd wget
$ sudo firewall-cmd --permanent --add-service=http
$ sudo firewall-cmd --reload
$ ssh -t node-b -- sudo yum install -y httpd
$ ssh -t node-b -- sudo firewall-cmd --permanent --add-service=http
$ ssh -t node-b -- sudo firewall-cmd --reload
```

### Create simple webpage
```bash
$ echo "<html>
 <body>My Test Site - $(hostname -s)</body>
 </html>" | sudo tee /var/www/html/index.html
# Do the same on node-b
```

### Enable Apache status URL
```bash
$ echo "<Location /server-status>
    SetHandler server-status
    Require local
 </Location>" | sudo tee /etc/httpd/conf.d/status.conf
# Do the same on node-b
```

### Configure Cluster
```bash
$ sudo pcs resource create WebSite ocf:heartbeat:apache  \
      configfile=/etc/httpd/conf/httpd.conf \
      statusurl="http://localhost/server-status" \
      op monitor interval=1min
$ sudo pcs resource op defaults timeout=240s
$ sudo pcs resource op defaults
$ sudo pcs status # Might need some time to appear
``` 

### Ensure resources Running on the same node
We will instruct the cluster that WebSite can only run on the host that ClusterIP is active on.
```bash
$ sudo pcs constraint colocation add WebSite with ClusterIP INFINITY
$ sudo pcs constraint
```

### Ensure Resources Start and Stop in Order
```bash
$ sudo pcs constraint order ClusterIP then WebSite
```

### Prefer One Node Over Another
```bash
$ sudo pcs constraint location WebSite prefers pcmk-1=50
$ sudo pcs constraint
$ crm_simulate -sL
```

### Move Resources Manually
```bash
$ sudo pcs constraint location WebSite prefers node-b=INFINITY
$ sudo pcs constraint
# Return to normal situation
$ sudo pcs constraint --full
$ sudo pcs constraint remove location-WebSite-node-b-INFINITY
```