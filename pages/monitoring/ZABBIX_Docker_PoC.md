# ZABBIX_Docker_PoC

## Configure Zabbix Agent
### Download and Install Zabbix Agent for CentOS
```bash
$ wget http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-agent-3.4.3-1.el7.x86_64.rpm
$ sudo yum -y localinstall zabbix-agent-3.4.3-1.el7.x86_64.rpm
```

### Configure Zabbix Passive Agent
```bash
$ cd /etc/zabbix
$ sudo cp zabbix_agentd.conf .orig-zabbix_agentd.conf
$ sudo vim zabbix_agentd.conf
```
Setup below values:
* Server=ms01-jenknfs01.nocompanymgmt.com
Comment Out below:
* # ServerActive=127.0.0.1
* # Hostname=Zabbix server

### Start Zabbix Agent
```bash
$ sudo systemctl enable zabbix-agent
$ sudo systemctl start zabbix-agent
```
