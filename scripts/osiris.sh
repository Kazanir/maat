#!/bin/bash

# Do setup.
CURRENT_DATE=`date +"%Y-%m-%d"`

mkdir -p ~/maat/results
sudo mv /etc/php5/mods-available/opcache.ini ~/maat/tools/oss/opcache.ini
cp ~/oss/base/PerfSettings.php ~/maat/tools/oss/PerfSettingsBackup.php

echo -e "\n*********************************************"
echo -e "***** Running OSS batch with concurrency 1..."

cp ~/maat/tools/oss/PerfC1.php ~/oss/base/PerfSettings.php
hhvm ~/oss/batch-run.php --i-am-not-benchmarking --no-proxygen < ~/maat/tools/batch.json > ~/maat/results/results_c1_${CURRENT_DATE}.json

echo -e "\n*********************************************"
echo -e "***** Running OSS batch with concurrency 5..."

cp ~/maat/tools/oss/PerfC5.php ~/oss/base/PerfSettings.php
hhvm ~/oss/batch-run.php --i-am-not-benchmarking --no-proxygen < ~/maat/tools/batch.json > ~/maat/results/results_c5_${CURRENT_DATE}.json

echo -e "\n**********************************************"
echo -e "***** Running OSS batch with concurrency 20..."

cp ~/maat/tools/oss/PerfC20.php ~/oss/base/PerfSettings.php
hhvm ~/oss/batch-run.php --i-am-not-benchmarking --no-proxygen < ~/maat/tools/batch.json > ~/maat/results/results_c20_${CURRENT_DATE}.json

echo -e "\n***** Cleaning up..."

cp ~/maat/tools/oss/PerfSettingsBackup.php ~/oss/base/PerfSettings.php
sudo mv ~/maat/tools/oss/opcache.ini /etc/php5/mods-available/opcache.ini

