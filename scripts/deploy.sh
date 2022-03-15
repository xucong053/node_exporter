#!/bin/bash
#
# Deploy monitor agent.
#
# This script should be run via curl:
# $ curl -fsSL script | bash
#
set -e

function echoError() {
    echo -e "\033[31m✘ $1\033[0m"
}
export -f echoError

function echoInfo() {
    echo -e "\033[32m✔ $1\033[0m"
}
export -f echoInfo

function get_mac_uuid() {
    system_profiler SPHardwareDataType | awk '/Hardware UUID/ {print $2}' FS=:
}

function get_linux_uuid() {
    if [[ -f /sys/class/dmi/id/product_uuid ]]; then
        cat /sys/class/dmi/id/product_uuid
    elif which dmidecode; then
        dmidecode -s system-uuid
    elif [[ -f /etc/machine-id ]]; then
        cat /etc/machine-id
    else
        echoError "[error] failed to get linux uuid !!!"
        exit 1
    fi
}

LOCAL_IP=$(ifconfig en0 | grep "inet " | awk '{ print $2}')

PUSHGATEWAY="$IP:$PORT"

OS_TYPE=$(uname -s)
case $OS_TYPE in
    Darwin)
        UUID=$(get_mac_uuid)
        if [[ $(uname -m) == "arm64" ]];then
            MONITOR_AGENT_DARWIN_DOWNLOAD_URL=${1:-"https://github.com/xucong053/node_exporter/releases/download/v1.3.2-alpha/node_exporter-v1.3.2-alpha-darwin-arm64.tar.gz"}
        else
            MONITOR_AGENT_DARWIN_DOWNLOAD_URL=${1:-"https://gtfstorage.byteoversea.com/mostRecent/node_exporter-darwin-amd64"}
        fi
        ;;
    Linux)
        UUID=$(get_linux_uuid)
        if [[ $(uname -m) == "arm64" ]];then
            MONITOR_AGENT_LINUX_DOWNLOAD_URL=${1:-"https://github.com/xucong053/node_exporter/releases/download/v1.3.2-alpha/node_exporter-v1.3.2-alpha-linux-arm64.tar.gz"}
        else
            MONITOR_AGENT_LINUX_DOWNLOAD_URL=${1:-"https://github.com/xucong053/node_exporter/releases/download/v1.3.2-alpha/node_exporter-v1.3.2-alpha-linux-amd64.tar.gz"}
        fi
        ;;
esac

case $OS_TYPE in
    Darwin)
        DESCRIPTION="DESCRIPTION_DARWIN"
        MONITOR_AGENT_DOWNLOAD_URL=$MONITOR_AGENT_DARWIN_DOWNLOAD_URL
        ;;
    Linux)
        DESCRIPTION="DESCRIPTION_LINUX"
        MONITOR_AGENT_DOWNLOAD_URL=$MONITOR_AGENT_LINUX_DOWNLOAD_URL
        ;;
esac

MONITOR_AGENT_BIN=./node_exporter
MONITOR_AGENT_GZ=./node_exporter-*.tar.gz

if [ -f "$MONITOR_AGENT_DOWNLOAD_URL" ]; then
    echo "copy task worker to space"
    echo "$ cp $MONITOR_AGENT_DOWNLOAD_URL $MONITOR_AGENT_GZ"
    cp "$MONITOR_AGENT_DOWNLOAD_URL" "$MONITOR_AGENT_GZ"
else
    echo "download task worker $MONITOR_AGENT_DOWNLOAD_URL"
    wget "$MONITOR_AGENT_DOWNLOAD_URL"
fi

tar -zxvf $MONITOR_AGENT_GZ

echo "$ chmod +x $MONITOR_AGENT_BIN"
chmod +x "$MONITOR_AGENT_BIN"
echo

./node_exporter --pushgateway.listen-address=$PUSHGATEWAY --instance=$LOCAL_IP-$OS_TYPE-$UUID
