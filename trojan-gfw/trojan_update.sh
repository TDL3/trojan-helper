#!/bin/bash
#This script automatically updates trojan-gfw

if [ "$EUID" != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
bold(){
    echo -e "\033[1m\033[01m$1\033[0m"
}

if [[ -z "$trojan_dir" ]]; then
# change this to where trojan-gfw is located, do not put a trailing slash in it
    trojan_dir="/etc/trojan"
    yellow "trojan_dir variable not set, defaults to "$trojan_dir
fi

url=$(
curl -s https://api.github.com/repos/trojan-gfw/trojan/releases \
| grep "browser_download_url.*linux-amd64.tar.xz" \
| head -1 \
| cut -d '"' -f 4)
blue "Download url is "$url
filename=$(basename "$url")

# This regex matches version strings like x.x.x 
regex="[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"
# If |& is used, the standard error of command is connected to command2's standard input through the pipe.
# Why trojan-gfw output vesion info to stderr, why? why? why?
local_version=$($trojan_dir/trojan --version |& head -1 | grep -oP $regex)
if [[ -z "$local_version" ]]; then
    red "Can not get local version of trojan"
    local_version="0.0.0"
fi
remote_version=$(echo $url | grep -oP $regex | tail -1)
blue "Local version: "$local_version
blue "Remote version: "$remote_version

temp_dir=$trojan_dir/temp/$remote_version

if [ $local_version != $remote_version ]; then
    blue "Update found"
else
    red "No update found"
    exit 1
fi

blue "Creating directories"
mkdir -p $temp_dir
blue "$temp_dir created"

# check if the file needs download already existed
if [[ ! -f $temp_dir/$filename ]]; then
    blue "Downloading trojan-gfw v"$remote_version
    wget -P $temp_dir $url
    if [ $? != 0 ] ; then
        red "Download failed"
        exit -1
    else
        blue "Download completed"
    fi
fi

blue "Extracting archive"
tar -xf $temp_dir/$filename -C $temp_dir
blue "Extraction completed"

blue "Stopping trojan-gfw service"
systemctl stop trojan
blue "trojan-gfw service stopped"

blue "Updating files"
cp -f $temp_dir/trojan/trojan ${trojan_dir}
blue "Files updated"

blue "Starting trojan-gfw service"
systemctl start trojan | head -10
systemctl status trojan | head -10
blue "trojan-gfw service started"
blue "UPDATE COMPLETED"
