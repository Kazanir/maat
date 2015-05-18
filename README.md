### Drupal Performance Testing

This repository is a set of configuration files and scripts to set up a machine for Drupal load testing on PHP5, PHP7, and HHVM. To set up a completely new server (the intention is to use spot-priced AWS instances cheaply) simply run the following:

```
cd ~
wget -O - https://raw.githubusercontent.com/Kazanir/maat/master/scripts/install.sh | sudo sh
./maat/scripts/provision.sh
```

This will set up 3 virtual host servers in Apache, which are for the domains `*.php5.benchmark`, `*.php7.benchmark`, and `*.hhvm.benchmark`. These servers will serve a subdomain based on a dynamic folder path under `/var/www/[subdomain]/www/`, where the final `www/` is the document root. So for example, `/var/www/drupal8/www/` would be accesssible at the following hostnames:

- http://drupal8.php5.benchmark
- http://drupal8.php7.benchmark
- http://drupal8.hhvm.benchmark

The provisioning script sets up the *.benchmark domain with an internal DNS wildcard.

Coming soon: Scripts to automatically provision certain Drupal setups and run Apache Bench tests on them. As well as more documentation!
