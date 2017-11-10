# Vagrant box creating


## Linux VirtualBox guest name =  centos-7.3.hs 
### Create box from virtual machine
```bash
$ vagrant package --output centos-7.3.hs.box --base centos-7.3.hs
```

### Add box to Vagrant
```bash
$ vagrant box remove bento/centos-7.3.hs
$ vagrant box add bento/centos-7.3.hs centos-7.3.hs.box
```


# Windows BoxCutter Vagrant box
### Download Windows 2012r2 Image from Microsoft
* [Follow this link|https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2012-r2]

### Check sha1sum of downloaded iso image
```bash
$ shasum 9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.iso 
849734f37346385dac2c101e4aacba4626bb141c  9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.iso
```

### Create Make.local file
```bash
# Makefile.local
CM := chef
EVAL_WIN2012R2_X64 := file:///Users/yyovkov-c/Projects/Vagrant/Boxcutter/isos/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.iso
EVAL_WIN2012R2_X64_CHECKSUM := 849734f37346385dac2c101e4aacba4626bb141c
```

### Make Command
```bash
$ cd <boxcutter>/window
$ make virtualbox/eval-win2012r2-standard
```
