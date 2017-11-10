## Create Configuration Files
```bash
$ sudo mkdir /etc/registry/nginx
```

# Create password file for docker repository
```bash
$ docker run --rm --entrypoint htpasswd registry:2 -bn testuser testpassword > /etc/registry/htpasswd
```

## Generate self-signed certificates to be used with repostiry
```bash
$ cd /etc/registry/certs
$ sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${hostname -s}.key -out ${hostname -s}.pem
```

## Create Docker Compose File
```bash
$ cd /etc/registry
$ sudo tee docker-compose.yml << 'EOF'
nginx:
  image: "nginx:1.9"
  ports:
    - 443:443
  links:
    - registry:registry
  volumes:
    - /etc/registry/certs/registry.crt:/etc/nginx/conf.d/registry.crt
    - /etc/registry/certs/registry.key:/etc/nginx/conf.d/registry.key
    - /etc/registry/nginx/htpasswd:/etc/nginx/conf.d/htpasswd
    - /etc/registry/nginx/nginx.conf:/etc/nginx/nginx.conf:ro

registry:
  image: registry:2
  ports:
    - 127.0.0.1:5000:5000
  volumes:
    - /var/lib/registry:/var/lib/registry
EOF
```

## Start Docker Registry
```bash
$ cd /etc/registry
$ docker-compose up
```

## Enable self-signed certificates for docker nodes
All the nodes the nodes that are going to use that repository should have installed
self-signed certificate generated above
```bash
$ sudo mkdir /etc/docker/certs.d/registry.castle.yyovkov.net
$ sudo cp /etc/registry/certs/registry.crt /etc/docker/certs.d/registry.castle.yyovkov.net
```

## Test registry login:
```bash
$ docker login -u=testuser -p=testpassword registry.castle.yyovkov.net
Login Succeeded
```

## Push image to repository
```bash
$ docker tag hello-world registry.castle.yyovkov.net/hello-world:1
$ docker push registry.castle.yyovkov.net/hello-world:1
The push refers to a repository [registry.castle.yyovkov.net/hello-world]
98c944e98de8: Pushed
1: digest: sha256:2075ac87b043415d35bb6351b4a59df19b8ad154e578f7048335feeb02d0f759 size: 524
```
