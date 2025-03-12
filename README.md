# WireGuard-Telegram-Notifier
Bash script that sands telegram notification every time one user connects to wireguard vpn

First of all format your wireguard configuration file in the followinf way:

```

[Peer]
PublicKey = the peer's publick key
AllowedIPs = 172.16.1.2/32
# username

```
the "username" will be sent in the telegram message

Just copy the scripts in "/usr/local/bin/"

add on crontab following entry:
```
* * * * * /usr/local/bin/keep_running_wg0-notify.sh
```
all the settings are present in the header of the `wg0-notify.sh` script



