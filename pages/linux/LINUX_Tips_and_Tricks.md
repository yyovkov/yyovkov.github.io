# Linux Tips and Tricks
---

## Color the MOTD slogan
```bash
sudo yum -y install figlet
echo -e "\e[1;31m" | sudo tee /etc/motd
# For green color: $ echo -e "\e[1;32m" | sudo tee /etc/motd
figlet $(hostname -s) | sudo tee -a /etc/motd
echo -e "HOSTNAME: $(hostname -f)" | sudo tee -a /etc/motd
echo  -e 'WARNING: This machine is in PRODUCTION state' | sudo tee -a /etc/motd
# For Dev machines: $ echo  -e 'NOTE: This is DEV machine' | sudo tee -a /etc/motd
echo -e "\e[0m" | sudo tee -a /etc/motd
```

## Install docker 17.03.1 on CentOS 7
```bash
$ sudo curl -o /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
$ sudo yum -y install docker-ce
$ sudo systemctl start docker
$ sudo systemctl enable docker
```

## Install docker-compose
```bash
$ export DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/1.12.0/docker-compose-$(uname -s)-$(uname -m)"
$ curl -L ${DOCKER_COMPOSE_URL} | sudo tee /usr/local/bin/docker-compose > /dev/null
$ chmod 754 /usr/local/bin/docker-compose
$ chown root:docker /usr/local/bin/docker-compose
```

## Generate Self Signed Certificate pair
```bash
$ export CERTNAME=$(hostname)
$ export KEYFILE="/etc/pki/tls/private/${CERTNAME}.key"
$ export CERTFILE="/etc/pki/tls/certs/${CERTNAME}.crt"
$ export COMBINEFILE="/etc/pki/tls/private/${CERTNAME}.pem"
$ sudo openssl req -subj '/CN=domain.com/O=My Company Name LTD./C=US' -x509 \
  -nodes -days 365 -newkey rsa:2048 -keyout ${KEYFILE} -out ${CERTFILE}
$ cat ${KEYFILE} ${CERTFILE} | sudo tee ${COMBINEFILE}
```

```bash
$ openssl req -subj '/CN=domain.com/O=My Company Name LTD./C=US' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt
```

## Exit if pipefail
```bash
$ ipaddr=$(host -4 $(hostname) | cut -d' ' -f 4; (exit ${PIPESTATUS[0]} ))
$ GETIPADDR=$?
$ if [[ ${GETIPADDR} -ne 0 ]]; then
  exit ${GETIPADDR}
fi
```


## Create Partition with Parted
```bash
BLOCKDEVICE=sdb
parted="parted -s -a optimal /dev/${BLOCKDEVICE}"

$parted mklabel msdos
$parted mkpart primary xfs 1 100%
$parted align-check optimal 1 || echo "Partition not aligned on /dev/${BLOCKDEVICE}."
```


## _firewall-cmd_ add service
```bash
$ sudo firewall-cmd --permanent --new-service=zabbix
$ sudo firewall-cmd --permanent --service=zabbix --add-port=10051/tcp
$ sudo firewall-cmd --permanent --service=zabbix --add-port=10052/tcp
$ sudo firewall-cmd --permanent --service=zabbix --add-port=10061/tcp
$ sudo firewall-cmd --permanent --zone=public --add-service=zabbix
$ sudo firewall-cmd --reload
```

## _firewall-cmd_
```bash
$ sudo firewall-cmd --permanent --new-zone=special
$ sudo firewall-cmd --permanent --zone=special --add-source=192.168.2.2/32
$ sudo firewall-cmd --permanent --zone=special --add-service=zabbix
$ sudo firewall-cmd --reload
$ sudo firewall-cmd --get-active-zones
```


## Install virtualbox additions to CentOS guest
```sh
$ yum groupinstall "Development Tools"
$ yum install kernel-devel

$ export KERN_DIR="/usr/src/kernel/3.10.0-514.6.1.el7.x86-64/"
$ export KERN_INCL="/usr/include"
```

## SSH Commands
### SSH Host Key in RSA format
```bash
$ ssh -o HostKeyAlgorithms=ssh-rsa ghe.nocompany.net
```
