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
# ~~~~~~~~~~~~~~~~~~~~~ Script to Configure the Splunk Forwarder with the Splunk server ~~~~~~~~~~~~~ #

# Create a splunk user to run the Splunk Forwarder
sudo useradd -m $SPLUNK_USER

# Set ownership of the Splunk Forwarder installation
sudo chown -R $SPLUNK_USER:$SPLUNK_USER $SPLUNK_INSTALL_DIR

# Start and configure Splunk Forwarder
sudo -u $SPLUNK_USER $SPLUNK_INSTALL_DIR/bin/splunk start --accept-license --answer-yes --no-prompt
sudo -u $SPLUNK_USER $SPLUNK_INSTALL_DIR/bin/splunk enable boot-start

# Set the admin password
sudo -u $SPLUNK_USER $SPLUNK_INSTALL_DIR/bin/splunk edit user admin -password $SPLUNK_PASSWORD -role admin -auth admin:changeme

# Configure the Splunk Forwarder to send data to the Splunk Server
sudo -u $SPLUNK_USER $SPLUNK_INSTALL_DIR/bin/splunk add forward-server $SPLUNK_SERVER_IP:$SPLUNK_SERVER_PORT -auth admin:$SPLUNK_PASSWORD

# Add a log to monitor (e.g., /var/log/syslog or /var/log/messages)
sudo -u $SPLUNK_USER $SPLUNK_INSTALL_DIR/bin/splunk add monitor $MONITORED_LOG

# Restart the Splunk Forwarder to apply changes
sudo -u $SPLUNK_USER $SPLUNK_INSTALL_DIR/bin/splunk restart
echo "Splunk Forwarder installed and configured to send logs to $SPLUNK_SERVER_IP:$SPLUNK_SERVER_PORT"
echo "Splunk Forwarder configuration completed successfully!" > success.txt


