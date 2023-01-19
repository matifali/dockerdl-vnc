!#/bin/bash
set -e

# Start VNC server and noVNC web server
vncserver -geometry 1920x1080 -depth 24 :1 -SecurityTypes None

# Start window manager
startxfce4 &
sleep 5

# Start noVNC web server
cd /opt/noVNC/utils

