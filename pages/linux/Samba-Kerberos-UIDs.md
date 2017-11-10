# Setup RID mapping
## Documentation of used backend
* [Idmap config rid](https://wiki.samba.org/index.php/Idmap_config_rid "Samba Documentation")

## Install required software
```bash
$ yum -y install samba-winbind-clients
```
## Stop winbind service
```sh
$ sudo systemctl stop winbind
```

## Update samba config
Append to the [global] section below lines
```sh
workgroup = WORK
   realm = WORKGROUP.COM
   security = ads
   idmap config * : range = 16777216-33554431
   idmap config HSM : backend = rid           # NOTE That line
   idmap config HSM : range = 10000-99999     # NOTE That line
   idmap config HSM : base_rid = 1000             # NOTE That line
   winbind cache time = 1
   template homedir = /home/workgroup.com/%U
   template shell = /bin/bash
   kerberos method = secrets only
   winbind use default domain = true
   winbind offline logon = false
```

## Start winbind
```sh
$ #smbcontrol all reload-config
$ net cache flush
$ sudo systemctl start winbind
```

## Another proposal
```sh
   idmap config * : backend = rid
   idmap config * : base_rid = 0
   winbind cache time = 1
```

## How to calculate Unix ID for a RID and vice versa
```sh
ID = RID - BASE_RID + LOW_RANGE_ID
RID = ID + BASE_RID - LOW_RANGE_ID
```

# Remove samba database
```sh
$ rm -f /var/lib/samba/*.tdb
```
