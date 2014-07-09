sudo apt-get install dnsmasq -y
sudo cp /vagrant/config/vagrant/dnsmasq.conf /etc/dnsmasq.conf
sudo service dnsmasq restart

sudo cp /vagrant/config/vagrant/resolv.conf /etc/resolv.conf
