#!/bin/bash
# This script only works on Debian, and only Debian 10 and Debian 9 are tested.

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

payload="payload_trojan_gfw.zip"
green " ========================================================== "
green "  Enter the domain name which point to this machine's ip    "
green " ========================================================== "
read -p "Enter the domain name here: " domain
trojan_dir="/etc/trojan"
payload_dir="/tmp/trojan_payload"

function isIpMatch(){

    if [ -n $1 ]; then
        configNetworkRealIp=`ping $1 -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
        # ipconfig.io
        configNetworkLocalIp=`curl -s v4.ident.me`

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

isIpMatch "$domain"

apt update
apt upgrade -y
apt install curl wget unzip tar gnupg2 ca-certificates lsb-release jq -y

function download_github_release(){
    TOKEN="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"
    repo_api_url="https://api.github.com/repos/tdl3/trojan-helper/releases"
    parser=".[0].assets | map(select(.name == \"$payload\"))[0].id"
    assest_id=$(
        curl -sH 'Authorization: token '$TOKEN -L $repo_api_url \
        | jq "$parser"
    )
    curl \
    -H 'Authorization: token '$TOKEN \
    -H 'Accept: application/octet-stream' \
    -o $payload \
    -L "$repo_api_url/assets/$assest_id"
}
download_github_release

unzip -d $payload_dir $payload


blue "Install the latest stable version of nginx."
# Set up the apt repository for stable nginx packages
echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
# Set up repository pinning to prefer our packages over distribution-provided ones
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | tee /etc/apt/preferences.d/99nginx
# Next, import an official nginx signing key so apt could verify the packages authenticity. Fetch the key
curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key
# Verify that the downloaded file contains the proper key
gpg --dry-run --quiet --import --import-options import-show /tmp/nginx_signing.key

yellow "The output should contain the full fingerprint 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 as follows"
green "
pub   rsa2048 2011-08-19 [SC] [expires: 2024-06-14]
      573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
uid                      nginx signing key <signing-key@nginx.com>
"
# Finally, move the key to apt trusted key storage (note the "asc" file extension change)
mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc
apt update
apt install nginx -y

blue "Config nginx."
mkdir -p /var/www/html
unzip -d /var/www/html $payload_dir/trojan.zip
chown -R nginx:nginx /var/www


blue "Install certbot."
# Install this after nginx is necessary because python-certbot-nginx depends on nginx.
apt install certbot python3-certbot-nginx -y
blue "Obtain tls certificate from Let's Encrypt."
systemctl start nginx
certbot certonly --nginx -d $domain --register-unsafely-without-email --agree-tos


blue "Install trojan-gfw."
source $payload_dir/trojan_update.sh
cp $payload_dir/trojan_update.sh $trojan_dir


blue "Update configs"
sed -i "s/SERVERNAME/$domain/g" $payload_dir/config.json
sed -i "s/SERVERNAME/$domain/g" $payload_dir/trojan.conf
green " ============================== "
green "   Setting trojan password   "
green " ============================== "
read -p "Enter trojan password here: " password
sed -i "s/PASSWORD/$password/" $payload_dir/config.json

blue "Config Services."
cp $payload_dir/trojan* /etc/systemd/system/
cp $payload_dir/config.json $trojan_dir
cp $payload_dir/trojan.conf /etc/nginx/conf.d/
# Rename default conf after we obtained a certificate, we need nginx running to get the certificate.
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.bak

blue "Enable BBR"
if [[ $(lsmod | grep tcp_bbr]) == "" ]]; then
    yellow "bbr mod not running, enabling."
    source $payload_dir/enable_bbr.sh
else 
    green "bbr mod appears running."
fi

blue "Enable services."
systemctl enable nginx trojan trojan-update.timer
systemctl restart nginx
systemctl start trojan trojan-update.timer
systemctl status nginx | head -10
systemctl status trojan | head -10
lsmod | grep tcp_bbr
green "trojan-gfw installation finished."
