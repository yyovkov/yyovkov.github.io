## RsysLog Server Setup
```bash
# rsyslog-server configuration file
#### MODULES ####
$ModLoad immark.so
$ModLoad imuxsock.so
# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

#### GLOBAL DIRECTIVES ####
# Use default timestamp format
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$FileOwner root
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022

#### RULES ####
$template TmplMesg, "/var/log/%HOSTNAME%/messages"
$template TmplSecr, "/var/log/%HOSTNAME%/secure"
$template TmplMail, "/var/log/%HOSTNAME%/maillog"
$template TmplCron, "/var/log/%HOSTNAME%/cron"
$template TmplSpoo, "/var/log/%HOSTNAME%/spooler"

*.info;mail.none;authpriv.none;cron.none                ?TmplMesg
authpriv.*                                              ?TmplSecr
mail.*                                                  -?TmplMail
cron.*                                                  ?TmplCron
uucp,news.crit                                          ?TmplSpoo
local7.*                                                ?TmplLoc7
```
