#!/bin/bash
#This script automatically updates trojan-go

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
# change this to where trojan-go is located, do not put a trailing slash in it
    yellow "trojan_dir variable not set, defaults to /etc/trojan-go"
    trojan_dir="/etc/trojan-go"
fi

if [ "$EUID" != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi


url=$(
curl -s https://api.github.com/repos/p4gefau1t/trojan-go/releases \
| grep "browser_download_url.*trojan-go-linux-amd64.zip" \
| head -1 \
| cut -d '"' -f 4)
blue "Download url is "$url
filename=$(basename "$url")

# This regex matches version strings like x.x.x 
regex="[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}"
local_version=$($trojan_dir/trojan-go --version | head -1 | grep -oP $regex)
remote_version=$(echo $url | grep -oP $regex)
blue "Local version: "$local_version
blue "Remote version: "$remote_version

temp_dir=$trojan_dir/temp/$remote_version

if [[ $local_version != $remote_version ]]; then
    blue "Update found"
else
    red "No update found"
    exit 1
fi

blue "Creating directories"
mkdir -p $temp_dir
blue "$temp_dir created"

# check if the file needs download already existed
if [ ! -f $temp_dir/$filename ]; then
    wget -P $temp_dir $url
    blue "Downloading trojan-go v"$remote_version
    if [ $? != 0 ] ; then
        red "Download failed"
        exit -1
    else
        blue "Download completed"
    fi
fi

blue "Extracting archive"
unzip -o -d $temp_dir $temp_dir/$filename
blue "Extraction completed"

blue "Stopping trojan-go service"
systemctl stop trojan-go
blue "trojan-go service stopped"

blue "Updating files"
cp -f $temp_dir/trojan-go \
$temp_dir/geoip.dat \
$temp_dir/geosite.dat \
${trojan_dir}/
blue "Files updated"

blue "Starting trojan-go service"
systemctl start trojan-go
systemctl status trojan-go
blue "trojan-go service started"
blue "UPDATE COMPLETED"
