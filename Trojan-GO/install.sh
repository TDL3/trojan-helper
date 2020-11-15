#!/bin/bash
# This script only works on Debian, Debian 10 and Debian 9 are tested.

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

payload="/home/tdl3/1.zip"
green " ========================================================== "
green "  Enter the domain name which point to this machine's ip    "
green " ========================================================== "
read -p "Enter the domain name here: " domain
trojan_dir="/etc/trojan-go"
payload_dir="$(dirname "$payload")/trojan_payload"

function compareRealIpWithLocalIp(){

    if [ -n $1 ]; then
        configNetworkRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
        # ipconfig.io
        configNetworkLocalIp=`curl v4.ident.me`

        green " ================================================== "
        green "    Domain relvoles to ${configNetworkRealIp}       "
        green "    This machine's ip is ${configNetworkLocalIp}    "
        green " ================================================== "

        if [[ ${configNetworkRealIp} == ${configNetworkLocalIp} ]] ; then
            green " ================================================== "
            green "      DNS records matches!                          "
            green " ================================================== "
        else
            green " ================================================== "
            red "      DNS records do not match!                       "
            red "      Does your dns record points to the right ip?    "
            green " ================================================== "
            exit -1
        fi
    else
        exit -1
    fi
}

compareRealIpWithLocalIp "$domain"

apt update
apt upgrade -y
apt install curl wget unzip gnupg2 ca-certificates lsb-release -y
unzip -d $payload_dir $payload


blue "Install the latest stable version of nginx."
echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
apt-key fingerprint ABF5BD827BD9BF62
apt update
apt install nginx -y

blue "Config nginx."
mkdir -p /var/www/html
unzip -d /var/www/html $payload_dir/trojan.zip


blue "Install certbot."
# Install this after nginx is necessary because python-certbot-nginx depends on nginx.
apt install certbot python-certbot-nginx -y
blue "Obtain tls certificate from Let's Encrypt."
systemctl start nginx
certbot certonly --nginx -d $domain --register-unsafely-without-email --agree-tos


blue "Install Trojan-GO."
source $payload_dir/trojan_go_update.sh
cp $payload_dir/trojan_go_update.sh $trojan_dir


blue "Update configs"
sed -i "s/SERVERNAME/$domain/g" $payload_dir/config.json
sed -i "s/SERVERNAME/$domain/g" $payload_dir/trojan.conf
green " ============================== "
green "   Setting trojan-go password   "
green " ============================== "
read -p "Enter trojan-go password here: " password
sed -i "s/PASSWORD/$password/" $payload_dir/config.json

blue "Config Services."
cp $payload_dir/trojan-go* /etc/systemd/system/
cp $payload_dir/config.json $trojan_dir
cp $payload_dir/trojan.conf /etc/nginx/conf.d/
# Rename default conf after we obtained a certificate, we need nginx running to get the certificate.
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak

blue "Enable BBR"
if [[ $(lsmod | grep tcp_bbr]) == "" ]]; then
    yellow "bbr mod not running, enabling."
    echo net.core.default_qdisc=fq >> /etc/sysctl.conf
    echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
    sysctl -p
    sysctl net.ipv4.tcp_available_congestion_control
else 
    green "bbr mod appears running."
fi

blue "Enable services."
systemctl enable nginx trojan-go trojan-go-update.timer
systemctl restart nginx
systemctl start trojan-go trojan-go-update.timer
systemctl status nginx 
systemctl status trojan-go
lsmod | grep tcp_bbr
bold "Trojan-GO installation finished."