sudo apt-get install dnsmasq -y
sudo cp /vagrant/tmp/dnsmasq.conf /etc/dnsmasq.conf
sudo service dnsmasq restart

sudo cp /vagrant/tmp/resolv.conf /etc/resolv.conf
