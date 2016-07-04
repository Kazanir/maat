#!/bin/bash

set -x

sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password mysql'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password mysql'

echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse
deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse
deb http://security.ubuntu.com/ubuntu trusty-security multiverse" | sudo tee -a /etc/apt/sources.list > /dev/null

sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449
sudo add-apt-repository -y 'deb http://dl.hhvm.com/ubuntu trusty main'
sudo add-apt-repository -y ppa:ondrej/php

wget -O - https://packagecloud.io/gpg.key | sudo apt-key add -
echo "deb http://packages.blackfire.io/debian any main" | sudo tee /etc/apt/sources.list.d/blackfire.list  

sudo apt-get update -y

sudo apt-get install -y accountsservice adduser \
  apparmor apt apt-transport-https apt-utils autoconf automake \
  bash bash-completion build-essential bzip2 ca-certificates cmake coreutils \
  default-jre dos2unix dpkg ed eject findutils gcc-4.8 blackfire-agent \
  geoip-database git-flow glances grep hhvm iperf linux-tools-generic-lts-trusty \
  libmcrypt-dev libmemcached-dev libmysqlclient-dev libtool makedev man-db \
  manpages mawk memcached mime-support mlocate module-init-tools mount mountall \
  mtr multiarch-support mysql-common mysql-server ncdu ncurses-base ncurses-bin \
  nginx openntpd openssh-client openssh-server openssl rsync rsyslog samba \
  redis-server resolvconf putty-tools screen sed siege tcpdump tmux traceroute \
  udev ufw unixodbc-dev vim vim-common vim-tiny wget xml-core zsh \
  libcurl4-openssl-dev libmcrypt-dev libxml2-dev libjpeg-dev libfreetype6-dev \
  libmysqlclient-dev libt1-dev libgmp-dev libpspell-dev libicu-dev \
  librecode-dev libjpeg62

sudo apt-get install php5.6 php7.0 php5.6-curl php7.0-curl php5.6-gd \
  php7.0-gd php5.6-cgi php7.0-cgi php5.6-ldap php7.0-ldap php5.6-mcrypt \
  php7.0-mcrypt phpedis php5.6-mysql php7.0-mysql php-memcache php5.6-xml \
  php7.0-xml blackfire-php

# Permissions chicanery
sudo usermod -a -G www-data $USER

# MySQL user setup
mysql -u root -pmysql -e "CREATE DATABASE drupal_bench;"

mysql -u root -pmysql -e "CREATE USER '$USER'@'localhost';"
mysql -u root -pmysql -e "GRANT ALL ON *.* TO '$USER'@'localhost';"

mysql -u root -pmysql -e "CREATE USER 'drupal_bench'@'%';"
mysql -u root -pmysql -e "GRANT ALL ON *.* TO 'drupal_bench'@'%' IDENTIFIED BY 'drupal_bench';"

mysql -u root -pmysql -e "FLUSH PRIVILEGES;"
mysql -u root -pmysql -e "SET GLOBAL max_connections = 1000;"

# PHP setup
sudo phpenmod mcrypt pdo_mysql mysql mysqli redis memcache opcache

# @todo: HHVM config files
sudo cp ~/maat/hhvm/php.ini /etc/hhvm/php.ini
sudo cp ~/maat/hhvm/server.ini /etc/hhvm/server.ini
sudo service hhvm restart

# Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
# @TODO: Drush broken ATM, fix it.
# composer global require drush/drush:dev-master
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

# All done. Generate a UUID for this machine; this is used later in results
# reporting.
MAAT_INSTANCE_UUID=$(cat /proc/sys/kernel/random/uuid)
export MAAT_INSTANCE_UUID

