# OpenCanary Installation and Configuration Wrapper

[OpenCanary](https://github.com/thinkst/opencanary) is a configurable open-source honeypot solution provided by Thinkst. This wrapper script helps install and configure your OpenCanary appliance using sane defaults, including:

- Setting the device's hostname
- Updating the OS
- Configuring unattended upgrades for OS and application patches
- Installing dependencies
- Installing and configuring the canary
- Creating a systemd unit file to launch OpenCanary as a service

## Pre-requisites
- Ubuntu or Debian based Linux distribution with Systemd
- Network connection

## Installation Instructions

For more detailed installation instructions, see [my post](https://smnbkly.co/blog/opencanary-free-flexible-distributed-honeypot).

1. Copy or download the 'opencanary-installer.sh' to your home directory
2. Modify the permissions of the file to allow execution using `sudo chmod +x opencanary-installer.sh`
3. Run the installer using `sudo ./opencanary-installer.sh`
4. After the script automatically triggers a reboot, your device should be operating as a Canary

## Troubleshooting
1. Confirm the Canary service is running by entering `systemctl status opencanary`. You should see a returned value that includes `Active: active (running)`
2. Ensure your configuration file at \~/opencanary.conf is valid
3. Look for error messages at `/var/tmp/opencanary.log`