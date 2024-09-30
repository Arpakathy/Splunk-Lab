cat << EOF >> userdata_forwarder.sh
#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~ Script to install the Splunk Forwarder ~~~~~~~~~~~~~~~~~~~~~ #
cd /opt
# Download the Splunk Universal Forwarder package
sudo wget -O splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz "https://download.splunk.com/products/universalforwarder/releases/9.0.4/linux/splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz"
# Extract the package
sudo tar -xvzf splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz -C /opt
sudo rm -f splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz
# ~~~~~~~~~~~~~~~~~~~~~ Script to Configure the Splunk Forwarder with the Splunk server ~~~~~~~~~~~~~ #
# Variables - Modify these based on your environment
#Variables
SPLUNK_INSTALL_DIR="/opt/splunkforwarder"
SPLUNK_SERVER_IP= ${splunk-server-ip}  # Change this to your Splunk server's IP or hostname
SPLUNK_SERVER_PORT="8000"  # The default receiving port for Splunk forwarders
MONITORED_LOG="/var/log/syslog"  # Change this to the log you want to monitor
SPLUNK_USER="splunk"  # User for running Splunk Forwarder
SPLUNK_PASSWORD="abcd1234"  # Password for the Splunk Forwarder

EOF