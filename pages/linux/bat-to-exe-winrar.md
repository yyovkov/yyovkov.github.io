## Create configuration file
```bash
Setup=start_windows_slave.bat
TempMode
Silent=1
Overwrite=1
Title=Cloudbees-Slave
Text
{
Starting Cloudbees Slave on Windows.
}
```

## Make exe from bat
```bash
rar a -r -z"C:\Jenkins Cloudbees\temp\xfs.conf" cloudbees-slave start_windows_slave.bat
rar s cloudbees-slave.rar cloudbees-slave.exe
del *.rar *.conf *.bat
```

## Create Service
```bash
sc create cloudbees-slave binPath="c:\Jenkins Cloudbees\temp\cloudbees-slave.exe" start="auto"
```

## Some helpful commands:
```bash
tasklist /v /fo csv | findstr /i "slave-jenkins"
```

https://wiki.jenkins-ci.org/pages/viewpage.action?pageId=66847778:
sc.exe create JenkinsSlave binPath= "C:\WINDOWS\system32\java.exe -jar C:\jenkins\slave.jar
-jnlpUrl http://SERVER:PORT/computer/MACHINE/slave-agent.jnlp" start= auto


C:\Users\vagrant\Desktop>sc create JenkinsBlaBla binPath= "C:\Jenkins Cloudbees\service\jenkins-slave.exe" start= auto
[SC] CreateService SUCCESS
