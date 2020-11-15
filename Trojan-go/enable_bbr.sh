#!/bin/bash
echo net.core.default_qdisc=fq >> /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
# 如果结果是这样 
# sysctl net.ipv4.tcp_available_congestion_control
# net.ipv4.tcp_available_congestion_control = bbr cubic reno
# 就开启了。 执行 lsmod | grep bbr ，以检测 BBR 是否开启。