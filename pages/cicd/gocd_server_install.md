## Install and configure NGINX proxy
### Install Software
```bash
$ sudo yum install epel-release
$ sudo yum install nginx
```

### Configure nginx
```bash
$ tee /etc/nginx/conf.d/gocd.castle.yyovkov.net.conf << 'EOF'
server {
  # Redirect any http requests to https
  listen         80;
  server_name    gocd.castle.yyovkov.net;
  return 301     https://gocd.castle.yyovkov.net$request_uri;
}

server {
  listen                    443 ssl;
  server_name               gocd.castle.yyovkov.net;

  ssl_certificate           /etc/pki/tls/certs/gocd.castle.yyovkov.net.chained.pem;
  ssl_certificate_key       /etc/pki/tls/private/gocd.castle.yyovkov.net.key;

  # Proxy everything over to the GoCD server
  location / {
    proxy_pass              http://localhost:8153;
    proxy_set_header        Host            $host;
    proxy_set_header        X-Real-IP       $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto $scheme;
  }
}
EOF
```

### Configure SELinux
```bash
$ sudo setsebool -P httpd_can_network_connect=1
```

### Generate self-signed certificate
```bash
$ sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/gocd.castle.yyovkov.net.key -out /etc/pki/tls/certs/gocd.castle.yyovkov.net.chained.pem
```

## Setup Firewall
```bash
$ sudo firewall-cmd --add-port=8154/tcp
$ sudo firewall-cmd --add-service=http
$ sudo firewall-cmd --add-service=https
$ sudo firewall-cmd --runtime-to-permanent
```

## Install Support Software for GoCD
```bash
$ sudo yum -y install git
```
