$ curl -o docker-ce-17.0.6.ce-1.el7.centos.x86_64.rpm https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-17.06.0.ce-1.el7.centos.x86_64.rpm
# https://artifactory.nocompany.net/artifactory/centos-docker-remote/
$ yum localinstall docker-ce-17.0.6.ce-1.el7.centos.x86_64.rpm

$ echo 'OPTIONS="-s overlay --storage-opt dm.no_warn_on_loop_devices=true"' | \
  tee /etc/sysconfig/docker

$ systemctl enable docker
$ systemctl enable docker
