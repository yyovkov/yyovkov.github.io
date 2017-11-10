# ZABBIX PoC HST

## Install Zabbix on Server in Containers
### Upload images to Artifactory
```bash
$ docker tag zabbix/zabbix-web-nginx-pgsql:alpine-3.4.1 artifactory.localdockerrepo.net:5000/zabbix/zabbix-web-nginx-pgsql:alpine-3.4.1
$ docker push artifactory.localdockerrepo.net:5000/zabbix/zabbix-web-nginx-pgsql:alpine-3.4.1
$ docker tag zabbix/zabbix-server-pgsql:alpine-3.4.1 artifactory.localdockerrepo.net:5000/zabbix/zabbix-server-pgsql:alpine-3.4.1
$ docker push artifactory.localdockerrepo.net:5000/zabbix/zabbix-server-pgsql:alpine-3.4.1
$ docker tag zabbix/zabbix-proxy-sqlite3:alpine-3.4.1 artifactory.localdockerrepo.net:5000/zabbix/zabbix-proxy-sqlite3:alpine-3.4.1
$ docker push artifactory.localdockerrepo.net:5000/zabbix/zabbix-proxy-sqlite3:alpine-3.4.1
$ docker tag zabbix/zabbix-java-gateway:alpine-3.4.1 artifactory.localdockerrepo.net:5000/zabbix/zabbix-java-gateway:alpine-3.4.1
$ docker push artifactory.localdockerrepo.net:5000/zabbix/zabbix-java-gateway:alpine-3.4.1
$ docker tag zabbix/zabbix-snmptraps:ubuntu-3.4-latest artifactory.localdockerrepo.net:5000/zabbix/zabbix-snmptraps:ubuntu-3.4-latest
$ docker push artifactory.localdockerrepo.net:5000/zabbix/zabbix-snmptraps:ubuntu-3.4-latest
$ docker tag postgres:9.5.9 artifactory.localdockerrepo.net:5000/postgres:9.5.9
$ docker push artifactory.localdockerrepo.net:5000/postgres:9.5.9
$ docker tag busybox artifactory.localdockerrepo.net:5000/busybox
$ docker push artifactory.localdockerrepo.net:5000/busybox
```

### On the server in HST
* Copy to the server files from reposiroty "https://github.com/yyovkov/zabbix-docker.git"
```bash
$ cd /home/nocompanytest.com/yyovkov-c/zabbix-docker/zabbix-server
$ cat .env 
# Mind the trailing slash after "VOLUME_DIR"
VOLUME_DIR=/var/data/zabbix/
IMAGE_POSTGRESQL=artifactory.localdockerrepo.net:5000/postgres:9.5.9
IMAGE_VOLUMES=artifactory.localdockerrepo.net:5000/busybox
IMAGE_ZABBIX_SERVER=artifactory.localdockerrepo.net:5000/zabbix/zabbix-server-pgsql:alpine-3.4.1
IMAGE_ZABBIX_WEB=artifactory.localdockerrepo.net:5000/zabbix/zabbix-web-nginx-pgsql:alpine-3.4.1
IMAGE_ZABBIX_PROXY_SQLITE3=artifactory.localdockerrepo.net:5000/zabbix/zabbix-proxy-sqlite3:alpine-3.4.1
IMAGE_ZABBIX_JAVA_GATEWAY=artifactory.localdockerrepo.net:5000/zabbix/zabbix-java-gateway:alpine-3.4.1
```

### Run Docker Compose
```bash
$ docker-compose -f  zabbix-server-full.yml up -d
```

## Install Zabbix agents on Jenkins PoC masters
### Download and install
```bash
$ wget http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-agent-3.4.3-1.el7.x86_64.rpm
$ sudo yum -y localinstall zabbix-agent-3.4.3-1.el7.x86_64.rpm
```

### Setup Zabbix agents on Jenkins PoC masters
```bash
$ cd /etc/zabbix
$ sudo cp zabbix_agentd.conf .orig-zabbix_agentd.conf
$ export ZABBIX_SERVER=ts01-dvms009.nocompanytest.com
$ sudo sed -i "s/^Server=.*/Server=${ZABBIX_SERVER}/g" zabbix_agentd.conf
$ sudo sed -i '/^ServerActive=/s/^/#\ /g' zabbix_agentd.conf
$ sudo sed -i '/^Hostname=/s/^/#\ /g' zabbix_agentd.conf
```

### Start Zabbix Agent
```bash
$ sudo systemctl enable zabbix-agent
$ sudo systemctl start zabbix-agent
```
