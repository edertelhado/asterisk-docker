## ADD REDE VIRTUAL
```bash
sudo ip link add asterisk-mv link eth0 type macvlan mode bridge
sudo ip addr add 192.168.1.200/24 dev asterisk-mv
sudo ip link set asterisk-mv up

docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=enp3s0 lan_net
```# asterisk-docker
