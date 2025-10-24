#!/bin/bash
screen -S minecraft -d -m bash -c '

while true
do
    java -Xms6G -Xmx8G -Dlog4j.configurationFile=log4j2.xml -jar fabric-server-mc.1.21.4-loader.0.16.10-launcher.1.0.1.jar nogui

    echo "Server stopped! Restarting automatically in 10 seconds (press Ctrl + C to cancel)"
    sleep 10
done
'

echo "Minecraft server is running in a screen session named 'minecraft'."
echo "You can reattach to it by running: screen -r minecraft"