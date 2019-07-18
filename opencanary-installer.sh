#!/bin/sh

# Get the device name to use for the canary
read -p 'What hostname do you want to use? [A-Z,a-z]: ' hs

# Check whether the hostname input is empty
if test -z "$hs"
then
      # If the hostname is empty, do nothing. Set the hostname variable to use
      echo "Not changing hostname"
      hs=$(hostname)
else
# Validate the hostname provided matches the required pattern
while [[ ! "$hs" =~ '[A-Za-z ]' ]]; do
    read -p "Wrong hostname format. Re-enter using only A-Z, or a-z: " hs
done

# Reset the hostname
echo "$hs" > /etc/hostname
cat >/etc/hosts <<EOL
127.0.0.1   localhost
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
127.0.1.1   $hs
EOL
hostnamectl set-hostname "$hs"
fi

# Get the IP address for the syslog server
read -p 'What is the IP address for your syslog server? ' syslogip

# Get the port to use for the syslog server
read -p 'What port is your syslog server listening on? ' syslogport

# Update the OS
apt update && apt full-upgrade -y

# Install dependencies
apt install -y unattended-upgrades build-essential libssl-dev libffi-dev python-dev python-pip python-virtualenv

# Set up unattended-upgrades file
cat >/etc/apt/apt.conf.d/50unattended-upgrades <<EOL
Unattended-Upgrade::Allowed-Origins {
	"\${distro_id}:\${distro_codename}";
	"\${distro_id}:\${distro_codename}-security";
	"\${distro_id}ESM:\${distro_codename}";
	"\${distro_id}:\${distro_codename}-updates";
}
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:38";
EOL

# Enable unattended upgrades
cat >/etc/apt/apt.conf.d/20auto-upgrades <<EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOL

# Create a python virtualenv
virtualenv env/

# Activate the virtualenv
. env/bin/activate

# Install OpenCanary dependencies
yes | pip install rdpy
yes | pip install scapy pcapy

# Install OpenCanary
yes | pip install OpenCanary

# Generate a new config file
cat >opencanary.conf <<EOL
{
    "device.node_id": "$hs",
    "git.enabled": false,
    "git.port" : 9418,
    "ftp.enabled": true,
    "ftp.port": 21,
    "ftp.banner": "FTP server ready",
    "http.banner": "Apache/2.2.22 (Ubuntu)",
    "http.enabled": true,
    "http.port": 80,
    "http.skin": "nasLogin",
    "http.skin.list": [
        {
            "desc": "Plain HTML Login",
            "name": "basicLogin"
        },
        {
            "desc": "Synology NAS Login",
            "name": "nasLogin"
        }
    ],
    "httpproxy.enabled" : false,
    "httpproxy.port": 8080,
    "httpproxy.skin": "squid",
    "httproxy.skin.list": [
        {
            "desc": "Squid",
            "name": "squid"
        },
        {
            "desc": "Microsoft ISA Server Web Proxy",
            "name": "ms-isa"
        }
    ],
    "logger": {
        "class": "PyLogger",
        "kwargs": {
            "formatters": {
                "plain": {
                    "format": "%(message)s"
                }
            },
            "handlers": {
                "console": {
                    "class": "logging.StreamHandler",
                    "stream": "ext://sys.stdout"
                },
                "syslog-unix": {
                    "class": "logging.handlers.SysLogHandler",
                    "address": [
                        "$syslogip",
                        $syslogport
                    ],
                    "socktype": "ext://socket.SOCK_DGRAM"
                },
                "file": {
                    "class": "logging.FileHandler",
                    "filename": "/var/tmp/opencanary.log"
                }
            }
        }
    },
    "portscan.enabled": false,
    "portscan.logfile":"/var/log/kern.log",
    "portscan.synrate": 5,
    "portscan.nmaposrate": 5,
    "portscan.lorate": 3,
    "smb.auditfile": "/var/log/samba-audit.log",
    "smb.enabled": false,
    "mysql.enabled": false,
    "mysql.port": 3306,
    "mysql.banner": "5.5.43-0ubuntu0.14.04.1",
    "ssh.enabled": false,
    "ssh.port": 22,
    "ssh.version": "SSH-2.0-OpenSSH_5.1p1 Debian-4",
    "redis.enabled": false,
    "redis.port": 6379,
    "rdp.enabled": false,
    "rdp.port": 3389,
    "sip.enabled": false,
    "sip.port": 5060,
    "snmp.enabled": false,
    "snmp.port": 161,
    "ntp.enabled": false,
    "ntp.port": "123",
    "tftp.enabled": false,
    "tftp.port": 69,
    "tcpbanner.maxnum":10,
    "tcpbanner.enabled": false,
    "tcpbanner_1.enabled": false,
    "tcpbanner_1.port": 8001,
    "tcpbanner_1.datareceivedbanner": "",
    "tcpbanner_1.initbanner": "",
    "tcpbanner_1.alertstring.enabled": false,
    "tcpbanner_1.alertstring": "",
    "tcpbanner_1.keep_alive.enabled": false,
    "tcpbanner_1.keep_alive_secret": "",
    "tcpbanner_1.keep_alive_probes": 11,
    "tcpbanner_1.keep_alive_interval":300,
    "tcpbanner_1.keep_alive_idle": 300,
    "telnet.enabled": true,
    "telnet.port": "23",
    "telnet.banner": "",
    "telnet.honeycreds": [
        {
            "username": "admin",
            "password": "\$pbkdf2-sha512\$19000$bG1NaY3xvjdGyBlj7N37Xw\$dGrmBqqWa1okTCpN3QEmeo9j5DuV2u1EuVFD8Di0GxNiM64To5O/Y66f7UASvnQr8.LCzqTm6awC8Kj/aGKvwA"
        },
        {
            "username": "admin",
            "password": "admin1"
        }
    ],
    "mssql.enabled": false,
    "mssql.version": "2012",
    "mssql.port":1433,
    "vnc.enabled": false,
    "vnc.port":5000
}
EOL

# Replace the default created opencanary conf file
cp -f opencanary.conf /root/.opencanary.conf

wd=$PWD
user=`whoami`

# Create a systemd service file
cat >/etc/systemd/system/opencanary.service <<EOL
[Unit]
Description=OpenCanary honeypot
After=syslog.target
After=network.target

[Service]
User=$user
Restart=always
Environment=VIRTUAL_ENV=/home/pi/env/
Environment=PATH=\$VIRTUAL_ENV/bin:/usr/bin:\$PATH
WorkingDirectory=$wd/env/bin
ExecStart=$wd/env/bin/opencanaryd --dev

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd services
systemctl daemon-reload

# Enable and start the new systemd service
systemctl enable opencanary.service
systemctl start opencanary.service

# Reboot the canary
reboot