# WireGuard-Telegram-Notifier
Bash script that sands telegram notification every time one user connects to wireguard vpn

First of all format your wireguard configuration file in this way:
```

[Peer]
PublicKey = the peer's publick key
AllowedIPs = 172.16.1.2/32
# username

```
Add a comment after each peer with the associated user or application.
The "username" will be sent in the telegram message.

Copy the script in `/usr/local/bin/` and assign executable permissions
copy the service in `/etc/systemd/system/` and assign executable permissions

Then:
```
sudo systemctl daemon-reload
sudo systemctl enable wg0-notify.service
sudo systemctl start wg0-notify.service
```
all the settings are present in the header of the `wg0-notify.sh` script



