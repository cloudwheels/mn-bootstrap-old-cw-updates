# Docker network info

General info on configuring Docker network bridge, port forwarding etc.


### Enable forwarding from Docker containers to the outside world
By default, traffic from containers connected to the default bridge network is not forwarded to the outside world. To enable forwarding, you need to change two settings. These are not Docker commands and they affect the Docker host’s kernel.

Configure the Linux kernel to allow IP forwarding.

?require sudo

```
$ sudo sysctl net.ipv4.conf.all.forwarding=1
```

Change the policy for the iptables FORWARD policy from DROP to ACCEPT.

```
$ sudo iptables -P FORWARD ACCEPT
```
These settings do not persist across a reboot, so you may need to add them to a start-up script.

The default config file path on Linux is /etc/docker/daemon.json but it doesn't exist by default.

`sudo nano /etc/docker/daemon.json`

Configure the default bridge network
To configure the default bridge network, you specify options in daemon.json. Here is an example daemon.json with several options specified. Only specify the settings you need to customize.



Sample:
```
{
  "bip": "192.168.1.5/24",
  "fixed-cidr": "192.168.1.5/25",
  "fixed-cidr-v6": "2001:db8::/64",
  "mtu": 1500,
  "default-gateway": "10.20.1.1",
  "default-gateway-v6": "2001:db8:abcd::89",
  "dns": ["10.20.1.2","10.20.1.3"]
}
```

Restart Docker for the changes to take effect.

`sudo systemctl restart docker`

### Docker networking references

https://docs.docker.com/v17.09/engine/userguide/networking/default_network/container-communication/#communication-between-containers
