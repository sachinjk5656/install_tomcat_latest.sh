#!/bin/bash

set -e

echo "📦 Installing dependencies..."
sudo apt update
sudo apt install -y curl wget tar openjdk-17-jdk

# Variables
TOMCAT_USER=tomcat
TOMCAT_DIR=/opt/tomcat
TOMCAT_BASE_URL="https://dlcdn.apache.org/tomcat/tomcat-10"

# Fetch the latest stable version
echo "🔍 Fetching latest Tomcat 10 version..."
LATEST_VERSION=$(curl -s https://downloads.apache.org/tomcat/tomcat-10/ | grep -oP 'v10\.\d+\.\d+/' | sort -V | tail -1 | tr -d '/v')

echo "📦 Latest Tomcat version found: $LATEST_VERSION"
TOMCAT_TAR="apache-tomcat-$LATEST_VERSION.tar.gz"
TOMCAT_URL="$TOMCAT_BASE_URL/v$LATEST_VERSION/bin/$TOMCAT_TAR"

# Create tomcat user if not exists
echo "👤 Creating Tomcat user..."
id -u $TOMCAT_USER &>/dev/null || sudo useradd -m -U -d $TOMCAT_DIR -s /bin/false $TOMCAT_USER

# Download and install Tomcat
echo "⬇️ Downloading Tomcat from $TOMCAT_URL..."
cd /tmp
wget $TOMCAT_URL

echo "📁 Extracting and configuring Tomcat..."
sudo mkdir -p $TOMCAT_DIR
sudo tar -xzf $TOMCAT_TAR -C $TOMCAT_DIR --strip-components=1
sudo chown -R $TOMCAT_USER: $TOMCAT_DIR
sudo sh -c "chmod +x $TOMCAT_DIR/bin/*.sh"

# Create systemd service
echo "🛠️ Creating systemd service file..."
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=$TOMCAT_USER
Group=$TOMCAT_USER

Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_PID=$TOMCAT_DIR/temp/tomcat.pid"
Environment="CATALINA_HOME=$TOMCAT_DIR"
Environment="CATALINA_BASE=$TOMCAT_DIR"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.security.egd=file:/dev/./urandom"

ExecStart=$TOMCAT_DIR/bin/startup.sh
ExecStop=$TOMCAT_DIR/bin/shutdown.sh

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload and start Tomcat
echo "🔁 Enabling and starting Tomcat..."
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat

echo "✅ Tomcat $LATEST_VERSION installed and running!"
echo "🌐 Access it at: http://<your-server-ip>:8080"
