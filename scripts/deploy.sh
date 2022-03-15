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
            MONITOR_AGENT_DARWIN_DOWNLOAD_URL=${1:-"https://gtfstorage.byteoversea.com/api/v1/mostRecent/node_exporter-darwin-arm64"}
        else
            MONITOR_AGENT_DARWIN_DOWNLOAD_URL=${1:-"https://gtfstorage.byteoversea.com/api/v1/mostRecent/node_exporter-darwin-amd64"}
        fi
        ;;
    Linux)
        UUID=$(get_linux_uuid)
        if [[ $(uname -m) == "arm64" ]];then
            MONITOR_AGENT_LINUX_DOWNLOAD_URL=${1:-"https://gtfstorage.byteoversea.com/api/v1/mostRecent/node_exporter-linux-arm64"}
        else
            MONITOR_AGENT_LINUX_DOWNLOAD_URL=${1:-"https://gtfstorage.byteoversea.com/api/v1/mostRecent/node_exporter-linux-amd64"}
        fi
        ;;
esac

UUID=$(echo $UUID)

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

MONITOR_AGENT_BIN=node_exporter

if [ -f $MONITOR_AGENT_BIN ]; then
    echo "monitor agent already exists, waiting to be executed"
else
    if [ -f "$MONITOR_AGENT_DOWNLOAD_URL" ]; then
        echo "copy monitor agent to space"
        echo "$ cp $MONITOR_AGENT_DOWNLOAD_URL $MONITOR_AGENT_BIN"
        cp "$MONITOR_AGENT_DOWNLOAD_URL" "$MONITOR_AGENT_BIN"
    else
        echo "download monitor agent $MONITOR_AGENT_DOWNLOAD_URL"
        wget "$MONITOR_AGENT_DOWNLOAD_URL" -O "$MONITOR_AGENT_BIN"
    fi
fi

chmod 777 "$MONITOR_AGENT_BIN"

echo "./node_exporter --pushgateway.listen-address=$PUSHGATEWAY --instance=$OS_TYPE--$LOCAL_IP--$UUID"
./node_exporter --pushgateway.listen-address=$PUSHGATEWAY --instance=$OS_TYPE--$LOCAL_IP--$UUID
