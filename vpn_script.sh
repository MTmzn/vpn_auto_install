#!/bin/sh
echo "run as root!"
if [ `whoami` != "root" ]; then
  echo "you must run this script as root"
  exit 1
fi
apt-get install pptpd

conf_file="/etc/pptpd.conf"
secret_file="/etc/ppp/chap-secrets"
options_file="/etc/ppp/pptpd-options"
sysctl_file="/etc/sysctl.conf"

if [ ! -f "$conf_file" ]; then
  echo "pptpd conf file not found! must be something wrong while installing pptpd"
fi

sed -i '$a localip 10.0.0.1' $conf_file
sed -i '$a remoteip 10.0.0.100-200' $conf_file

echo "Create VPN User"
while true; do
  read -p "Please input username : "  username
  read -p "Please input password : "  password
  sed -i "\$a ${username} pptpd ${password}  *" $secret_file
  read -p "Create more user? y/n: " answer
  if [ $answer != 'y' ]; then
    break
  fi
done
sed -i '$a ms-dns 8.8.8.8' $options_file
sed -i '$a ms-dns 8.8.4.4' $options_file

service pptpd restart

if [ `netstat -alpn | grep :1723 | wc -l` -eq 0 ]; then
  echo "pptpd lauch error?!?"
  exit 1
fi

sed -i 's/.*net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/' $sysctl_file
sysctl -p
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE && iptables-save

service pptpd restart
