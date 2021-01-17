# trojan-helper
<hr>

[trojan]: https://github.com/trojan-gfw/trojan
[trojan-go]: https://github.com/p4gefau1t/trojan-go
[trojan-r]: https://github.com/p4gefau1t/trojan-r

## Please Note:
**These scripts only work on Debian, and only Debian 10 and Debian 9 are tested.**

## About
This is a collection of scripts to automate the deployment of [trojan-go], [trojan-r], and more implementations of [trojan] will be added. all implementations are deployed with maximum compatibility with the original [trojan] protocol, things like CDN support, shadowsocks AEAD, and other extra features are disabled by default.

## Features
1. Deploy trojan and enable auto restart on failure or reboot.
2. Deploy auto-update services to automatically check updates once a week by default.
3. Auto enable tcp-bbr
