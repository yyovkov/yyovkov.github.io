# CHEF databag examples
## Generate encryption keys
### Generate Databag
```bash
$ export DATABAG_NAME="keys"
$ export DATABAGS_ROOT="${HOME}/.kitchen/settings"
$ mkdir -p ${DATABAGS_ROOT}
$ cd ${DATABAGS_ROOT}
$ knife data bag create ${DATABAG_NAME} -z -d
$ tee data_bags/${DATABAG_NAME}/linux_admin.json << 'EOF'
{
  "id": "linux_admin",
  "keyfile": "/tmp/kitchen/data_bags/test_db_enc_key"
}
EOF
$ tee data_bags/${DATABAG_NAME}/admin.json << 'EOF'
{
  "id": "admin",
  "keyfile": "C:/Users/vagrant/AppData/Local/Temp/kitchen/data_bags/test_db_enc_key"
}
EOF
```
### Create Encryption file
```bash
$ openssl rand -base64 512 > data_bags/test_db_enc_key
```


## Add SSH Key to Chef Databag
### Generate SSH RSA key pair adn put them in Data Bag
```bash
$ export DATABAGS_ROOT="${HOME}/.kitchen/settings"
$ export DATABAG_NAME="pw"
$ export DATABAG_ID="signing_keys"
$ export CHEF_ENVIRONMENTS="_default hsm_prod hsm_test hsm_dr"
$ declare -a SSH_PRIVATE_KEY_
$ mkdir -p ${DATABAGS_ROOT}
$ cd ${DATABAGS_ROOT}
```

### Generate databag content
```bash
$ knife data bag create ${DATABAG_NAME} -z -d
$ tee data_bags/${DATABAG_NAME}/${DATABAG_ID}.json << EOF
{
  "id": "${DATABAG_ID}",
EOF
$ for my_env in $(echo ${CHEF_ENVIRONMENTS})
do
    ssh-keygen -t rsa -C "test@my-test-env.com" -N "" -q -f /tmp/${my_env}_rsa
    declare "SSH_PRIVATE_KEY_${my_env}=$(cat /tmp/${my_env}_rsa | sed 's/$/\\n/g'| tr -d '\r\n')"
    key_name=SSH_PRIVATE_KEY_${my_env}
    tee -a data_bags/${DATABAG_NAME}/${DATABAG_ID}.json << EOF
    "${my_env}": { 
        "jenkins_builduser_ssh_key": "${!key_name}"
    },
EOF
    rm /tmp/${my_env}_rsa /tmp/${my_env}_rsa.pub
done
$ sed '$ s/,$//' data_bags/${DATABAG_NAME}/${DATABAG_ID}.json > data_bags/${DATABAG_NAME}/.temp_${DATABAG_ID}.json
$ mv data_bags/${DATABAG_NAME}/.temp_${DATABAG_ID}.json data_bags/${DATABAG_NAME}/${DATABAG_ID}.json
$ tee -a data_bags/${DATABAG_NAME}/${DATABAG_ID}.json << 'EOF'
}
EOF
```
### Encrypt data bag
```bash
$ knife data bag from file ${DATABAG_NAME} ${DATABAG_ID}.json --secret-file data_bags/test_db_enc_key -z
```


## Create password databs
### Setup Environment
```bash
$ export DATABAGS_ROOT="${HOME}/.kitchen/settings"
$ export DATABAG_NAME="pw"
$ export DATABAG_ID="serviceusers"
$ export CHEF_ENVIRONMENTS="_default hsm_prod hsm_test hsm_dr"
$ export JENKINS_NODE_USER_PASSWORD="SomeVeryStrongPassword123!@#"
$ export JENKINS_SERVICE_USER_PASSWORD="1qAz2wSx3eDc"
$ mkdir -p ${DATABAGS_ROOT}
$ cd ${DATABAGS_ROOT}
```

### Generate databag content
```bash
$ tee data_bags/${DATABAG_NAME}/${DATABAG_ID}.json << EOF
{
  "id": "${DATABAG_ID}",
EOF
$ for my_env in $(echo ${CHEF_ENVIRONMENTS})
do
    tee -a data_bags/${DATABAG_NAME}/${DATABAG_ID}.json << EOF
    "${my_env}": { 
        "service_jenkins_node_password": "${JENKINS_NODE_USER_PASSWORD}",
        "service_builduser": "${JENKINS_SERVICE_USER_PASSWORD}"
    },
EOF
done
$ sed '$ s/,$//' data_bags/${DATABAG_NAME}/${DATABAG_ID}.json > data_bags/${DATABAG_NAME}/.temp_${DATABAG_ID}.json
$ mv data_bags/${DATABAG_NAME}/.temp_${DATABAG_ID}.json data_bags/${DATABAG_NAME}/${DATABAG_ID}.json
$ tee -a data_bags/${DATABAG_NAME}/${DATABAG_ID}.json << 'EOF'
}
EOF
```

### Encrypt data bag
```bash
$ knife data bag from file ${DATABAG_NAME} ${DATABAG_ID}.json --secret-file data_bags/test_db_enc_key -z
```


## Generate SSL certificates data bag
### Setup Environment
```bash
$ export DATABAGS_ROOT="${HOME}/.kitchen/settings"
$ export DATABAG_NAME="pw"
$ export DATABAG_ID="serviceusers"
$ export CHEF_ENVIRONMENTS="_default hsm_prod hsm_test hsm_dr"
$ export JENKINS_NODE_USER_PASSWORD="SomeVeryStrongPassword123!@#"
$ export JENKINS_SERVICE_USER_PASSWORD="1qAz2wSx3eDc"
$ mkdir -p ${DATABAGS_ROOT}
$ cd ${DATABAGS_ROOT}
```

## Useful Commands related to data bags
### List encrypted databag content:
```bash
$ knife data bag list -z
$ knife data bag show pw -z
$ knife data bag show pw signing_keys --secret-file data_bags/test_db_enc_key -z
```

### Enforce SSH to use 'ssh-rsa' algorithm.
```bash
$ ssh -o HostKeyAlgorithms=ssh-rsa ms01-jenkent01