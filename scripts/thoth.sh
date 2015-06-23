#!/bin/bash

# Do setup.
CURRENT_DATE=`date +"%Y-%m-%d"`
D8_COMMIT=${1:-8.0.x}

if [ "$D8_COMMIT" != "none" ]; then
  git clone https://github.com/drupal/drupal.git ~/drupal-8.0.0-beta11
  cd ~/drupal-8.0.0-beta11
  git checkout $D8_COMMIT
  D8_ACTUAL_COMMIT=`git rev-parse --short HEAD`
  D8_COMMIT_TIME=$(git show -s --format=%ct $D8_ACTUAL_COMMIT)
  tar -C /home/ubuntu -czf ~/drupal-8.0.0-beta11.tar.gz drupal-8.0.0-beta11
  mv ~/drupal-8.0.0-beta11.tar.gz ~/oss/targets/drupal8/drupal-8.0.0-beta11.tar.gz
fi

mkdir -p ~/maat/results
sudo mv /etc/php5/mods-available/opcache.ini ~/maat/tools/oss/opcache.ini
cp ~/oss/base/PerfSettings.php ~/maat/tools/oss/PerfSettingsBackup.php

echo -e "\n********************************************"
echo -e "***** Running D8 batch with concurrency 1..."

cp ~/maat/tools/oss/PerfC1.php ~/oss/base/PerfSettings.php
hhvm ~/oss/batch-run.php --i-am-not-benchmarking --no-proxygen < ~/maat/tools/d8_progress.json > ~/maat/results/results_c1_${D8_ACTUAL_COMMIT}_${CURRENT_DATE}.json

echo -e "\n********************************************"
echo -e "***** Running D8 batch with concurrency 5..."

cp ~/maat/tools/oss/PerfC5.php ~/oss/base/PerfSettings.php
hhvm ~/oss/batch-run.php --i-am-not-benchmarking --no-proxygen < ~/maat/tools/d8_progress.json > ~/maat/results/results_c5_${D8_ACTUAL_COMMIT}_${CURRENT_DATE}.json

echo -e "\n*********************************************"
echo -e "***** Running D8 batch with concurrency 20..."

cp ~/maat/tools/oss/PerfC20.php ~/oss/base/PerfSettings.php
hhvm ~/oss/batch-run.php --i-am-not-benchmarking --no-proxygen < ~/maat/tools/d8_progress.json > ~/maat/results/results_c20_${D8_ACTUAL_COMMIT}_${CURRENT_DATE}.json

echo -e "\n*************************************"
echo -e "***** Posting data to API endpoint..."

export D8_ACTUAL_COMMIT
export D8_COMMIT_TIME
hhvm ~/maat/scripts/postresults.php

echo -e "\n***** Cleaning up..."

cp ~/maat/tools/oss/PerfSettingsBackup.php ~/oss/base/PerfSettings.php
sudo mv ~/maat/tools/oss/opcache.ini /etc/php5/mods-available/opcache.ini

