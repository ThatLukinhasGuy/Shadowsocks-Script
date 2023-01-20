#!/bin/bash

## Checar se usuário é root
if [ "$EUID" -ne 0 ]
  then echo "Execute esse Script como Root."
  exit
fi

echo " ################################################################# "
echo "  Script de Instalação do Shadowsocks em VPS Ubuntu (By Lukinhas)  "
echo " ################################################################# "

## Atualizar pacotes
apt-get update -y
apt-get upgrade -y
sleep 1

## Abrir portas para o Shadowsocks
echo "Instalando o Firewalld para abrir a porta necessária do Shadowsocks."
apt-get install firewalld -y
firewall-cmd --permanent --zone=public --add-port=8388/tcp
firewall-cmd --permanent --zone=public --add-port=8388/udp
firewall-cmd --reload
echo "Porta do Shadowsocks abertas com sucesso!"
sleep 1

## Instalação do Shadowsocks
echo "Instalando o Shadowsocks via Snap"
snap install shadowsocks-libev
echo "Shadowsocks instalado com sucesso!"
sleep 1

## Criar diretório da configuração do Shadowsocks
echo "Criando diretório para a configuração do Shadowsocks"
sudo mkdir -p /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
echo "Diretório criado com sucesso!"
sleep 1

## Criar configuração do Shadowsocks
touch /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev
sleep 1

echo "Gerando configuração do Shadowsocks"
arquivo="/var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json"
echo "{" > $arquivo
echo "    \"server\":[\"0.0.0.0\"]," >> $arquivo
echo "    \"server_port\":8388," >> $arquivo
echo "    \"password\":\"Proxy\"," >> $arquivo
echo "    \"method\":\"xchacha20-ietf-poly1305\"," >> $arquivo
echo "}" >> $arquivo
echo "Configuração criada com sucesso!"

## Criar serviço para o Shadowsocks

echo "Criando serviço e iniciando o Shadowsocks"
sudo touch /etc/systemd/system/shadowsocks-libev-server@.service
sleep 1 

echo "[Unit]
Description=Shadowsocks-Libev Custom Server Service for %I
Documentation=man:ss-server(1)
After=network-online.target
Wants=network-online.target
    
[Service]
Type=simple
ExecStart=/usr/bin/snap run shadowsocks-libev.ss-server -c /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/%i.json
    
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/shadowsocks-libev-server@.service
sleep 1

cat /etc/systemd/system/shadowsocks-libev-server@.service
sleep 1

sudo systemctl enable --now shadowsocks-libev-server@config
sleep 1

sudo systemctl start shadowsocks-libev-server@config
sleep 1

file2="/etc/security/limits.conf"
echo "*soft nofile 51200" >> $file2
echo "*hard nofile 51200" >> $file2
echo "root soft nofile 51200" >> $file2
echo "root hard nofile 51200" >> $file2

sleep 1

touch /etc/sysctl.conf

echo "fs.file-max = 51200
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sleep 1

sudo sysctl -p 
sleep 1

sudo systemctl restart shadowsocks-libev-server@config
sleep 1
echo "Criação do serviço e inicialização terminaram com sucesso!"

IP_Server=$(hostname -I | awk '{ print $1}')

echo "Seu servidor Shadowsocks está pronto!"
echo " "
echo "
################################################
################################################
||Servidor          : $IP_Server              ||      
||Porta             : 8838                    ||
||Senha             : Proxy                   ||
||Encriptação       : xchacha20-ietf-poly1305 ||
################################################
################################################
"

echo "Para mudar a senha do servidor, execute o comando abaixo:"
echo "-> nano /var/snap/shadowsocks-libev/common/etc/shadowsocks-libev/config.json"
echo "Para qualquer mudança nesse arquivo, execute o comando -> reboot"

