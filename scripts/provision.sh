#!/bin/bash

set -x

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password mysql'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password mysql'

echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse
deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse
deb http://security.ubuntu.com/ubuntu trusty-security multiverse
deb http://repos.zend.com/zend-server/early-access/php7/repos ubuntu/" | sudo tee -a /etc/apt/sources.list > /dev/null

sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449
sudo add-apt-repository -y 'deb http://dl.hhvm.com/ubuntu trusty main'
sudo add-apt-repository -y ppa:ondrej/php5-5.6

wget -O - https://packagecloud.io/gpg.key | sudo apt-key add -
echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list  

sudo apt-get update -y

sudo apt-get install -y accountsservice adduser apache2-mpm-worker \
  apache2-utils apparmor apt apt-transport-https apt-utils autoconf automake \
  bash bash-completion build-essential bzip2 ca-certificates cmake coreutils \
  default-jre dos2unix dpkg ed eject findutils gcc-4.8 blackfire-agent \
  geoip-database git-flow glances grep hhvm iperf linux-tools-generic-lts-trusty \
  libapache2-mod-fastcgi libmcrypt-dev libmemcached-dev libmysqlclient-dev \
  libtool makedev man-db manpages mawk memcached mime-support mlocate \
  module-init-tools mount mountall mtr multiarch-support mysql-common \
  mysql-server ncdu ncurses-base ncurses-bin nginx blackfire-php \
  openntpd openssh-client openssh-server openssl php5 php5-cli php5-curl \
  php5-fpm php5-gd php5-ldap php5-mcrypt php5-mysql php5-memcache \
  php5-pgsql php5-redis putty-tools redis-server resolvconf \
  rsync rsyslog samba screen sed siege tcpdump tmux traceroute \
  udev ufw unixodbc-dev vim vim-common vim-tiny wget xml-core zsh \
  libcurl4-openssl-dev libmcrypt-dev libxml2-dev libjpeg-dev libfreetype6-dev \
  libmysqlclient-dev libt1-dev libgmp-dev libpspell-dev libicu-dev \
  librecode-dev libjpeg62 php5-cgi

# Permissions chicanery
sudo usermod -a -G www-data $USER
sudo chown -R www-data:www-data /var/log/apache2
sudo chown www-data:www-data /var/log/php5-fpm.log

# MySQL user setup
mysql -u root -pmysql -e "CREATE USER '$USER'@'localhost';"
mysql -u root -pmysql -e "GRANT ALL ON *.* TO '$USER'@'localhost';"

mysql -u root -pmysql -e "CREATE USER 'drupal_bench'@'localhost';"
mysql -u root -pmysql -e "GRANT ALL ON *.* TO 'drupal_bench'@'localhost' IDENTIFIED BY 'drupal_bench';"

mysql -u root -pmysql -e "FLUSH PRIVILEGES;"
mysql -u root -pmysql -e "SET GLOBAL max_connections = 1000;"

# PHP5 setup
sudo php5enmod mcrypt pdo_mysql mysql mysqli redis memcache
sudo service php5-fpm restart
# @todo: PHP5 config files

# @todo: PHP7 setup
wget http://repos.zend.com/zend-server/early-access/php7/php-7.0-240515-DEB-x86_64.tar.gz
sudo tar zxPf php-7.*.tar.gz
sudo cp ~/maat/php7/etc-initd-php7fpm /etc/init.d/php7-fpm
sudo chmod a+x /etc/init.d/php7-fpm
sudo cp ~/maat/php7/etc-init-php7fpm /etc/init/php7-fpm
sudo cp ~/maat/php7/php7-fpm-checkconf /usr/local/lib/php7-fpm-checkconf
sudo chmod a+x /usr/local/lib/php7-fpm-checkconf
sudo update-rc.d php7-fpm defaults
sudo service php7-fpm start

# @todo: PHP7 config files

# @todo: HHVM setup

# @todo: HHVM config files
sudo cp ~/maat/hhvm/php.ini /etc/hhvm/php.ini
sudo cp ~/maat/hhvm/server.ini /etc/hhvm/server.ini
sudo service hhvm restart

# Apache config
sudo a2dismod mpm_event
sudo a2enmod alias actions vhost_alias rewrite mpm_worker ssl socache_shmcb proxy fastcgi
# @todo: Wildcard VHosts for PHP5, PHP7, HHVM
sudo cp ~/maat/apache2/vhosts/*.conf /etc/apache2/sites-available/
sudo cp ~/maat/apache2/apache2.conf /etc/apache2/
sudo a2dissite 000-default.conf
sudo a2ensite php5.conf php7.conf hhvm.conf

# Restart Apache
sudo apache2ctl restart
sudo apache2ctl restart

# Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer global require drush/drush:dev-master
echo 'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> /home/$USER/.bashrc

# Use my Vim config! It rules.
git clone https://github.com/Kazanir/dotvim.git ~/.vim
ln -s ~/.vim/.vimrc ~/.vimrc
cd ~/.vim
git submodule init
git submodule update

# Install Facebook's OSS performance toolkit
cd ~
git clone https://github.com/Kazanir/oss-performance.git oss
cd oss
composer install
echo 1 | sudo tee /proc/sys/net/ipv4/tcp_tw_reuse


# Get a working copy of Linuxtools perf
wget http://dl.hhvm.com/resources/perf.gz
gunzip perf.gz
sudo mv perf /usr/bin/perf
sudo chmod a+x /usr/bin/perf

# Install an old, not-buggy version of Siege
cd ~
wget http://download.joedog.org/siege/siege-2.70.tar.gz
tar -xzvf siege-2.70.tar.gz
cd siege-2.70/
./configure
sudo make
sudo make install

# @todo: Wildcard DNS for *.benchmark
# The below doesn't work on EC2, use it at your peril!!!
# sudo cp ~/maat/dnsmasq/dnsmasq.conf /etc/dnsmasq.conf
# sudo echo "prepend domain-name-servers 127.0.0.1;" | sudo tee -a /etc/dhcp/dhclient.conf
# sudo service networking restart

