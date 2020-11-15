# trojan-helper
<hr>

[trojan]: https://github.com/trojan-gfw/trojan
[trojan-go]: https://github.com/p4gefau1t/trojan-go
[trojan-r]: https://github.com/p4gefau1t/trojan-r

## Please Note:
**These scripts only works on Debian, and only Debian 10 and Debian 9 are tested.**

## About
This is a collection of scripts to automate the installation of [trojan-go], [trojan-r], and more implementations to be added. all implementations are installed with maximum compatibility with the original [trojan] protocal as cdn support and other extra features are disabled.

## Features
1. Install trojan and enable auto restart on failure or reboot.
2. install auto update services to automatically check updates once a week by deafult.
3. Auto enable bbr algorithm

## Usage
### trojan-go
```bash
curl -O https://raw.githubusercontent.com/TDL3/trojan-helper/main/Trojan-go/install.sh?token=PUT_YOUR_TOKEN_HERE && chmod +x ./install.sh && ./install.sh
```
### trojan-r
Waitting for [trojan-r] to enter beta