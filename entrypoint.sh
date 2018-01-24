#!/bin/bash

if [ "$DEBUG" == "True" ] || [ "$DEBUG" == "true" ]; then
    set -xe
    sed -i 's/LogLevel.*/LogLevel = 10/g' "$SINUS_DIR/config.ini"
fi

if [ ! -z "$LOGPATH" ]; then
    echo "-> Setting Sinusbot log file location to \"$LOGPATH\" ..."
    grep -q '^LogFile' "$SINUS_DIR/config.ini" && sed -i 's#^LogFile.*#LogFile = "'"$LOGPATH"'"#g' "$SINUS_DIR/config.ini" \
        || echo "LogFile = \"$LOGPATH\"" >> "$SINUS_DIR/config.ini"
    echo "=> Sinusbot logging to \"$LOGPATH\"."
fi

echo "-> Updating sinusbot user and group id if necessary ..."
if [ "$SINUS_USER" != "3000" ]; then
    usermod -u "$SINUS_USER" sinusbot
fi
if [ "$SINUS_GROUP" != "3000" ]; then
    groupmod -g "$SINUS_GROUP" sinusbot
fi

echo "-> Correcting file and mount point permissions ..."
chown -fR sinusbot:sinusbot "$SINUS_DATA" "$SINUS_DATA_SCRIPTS"
echo "=> Corrected mount point permissions."

echo "-> Checking if scripts directory is empty"
if [ ! -f "$SINUS_DATA_SCRIPTS/.docker-sinusbot-installed" ]; then
    echo "-> Copying original sinusbot scripts to volume ..."
    cp -af "$SINUS_DATA_SCRIPTS-orig/"* "$SINUS_DATA_SCRIPTS"
    touch "$SINUS_DATA_SCRIPTS/.docker-sinusbot-installed"
    echo "=> Sinusbot scripts copied."
else
    echo "=> Scripts directory is marked that scripts got copied. Nothing to do."
fi

echo "-> Checking for old data location ..."
if [ -d "/data" ]; then
    rm -rf "$SINUS_DATA"
    ln -s /data "$SINUS_DATA"
    echo "=> !! WARNING !! Please change your volume mounts from \"/data\" to the new location at \"$SINUS_DATA\"."
else
    echo "=> You are good to go! You are already using the new data directory, located at \"$SINUS_DATA\"."
fi
echo "=> Updating Youtube-dl..."
$YTDL_BIN -U
echo "=> Updated youtube-dl with exit code $?"

echo "=> Checking network connection"
ping -c1 sinusbot.com
if [ $? -eq 0 ]
then
    echo "=> Updating Sinusbot"
    cd /sinusbot
    wget https://www.sinusbot.com/dl/sinusbot.current.tar.bz2
    tar -xjvf sinusbot.current.tar.bz2
    cp plugin/libsoundbot_plugin.so TeamSpeak3-Client-linux_amd64/plugins/
    chown -R sinusbot /sinusbot
    echo "=> Done"
fi
echo "=> Starting SinusBot (https://sinusbot.com) by Michael Friese ..."
exec sudo -u sinusbot -g sinusbot "$SINUS_DIR/sinusbot" "$@"
