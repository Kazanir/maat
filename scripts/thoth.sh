#!/bin/bash

# Do setup.
CURRENT_DATE=`date +"%Y-%m-%d"`
D8_COMMIT=${2:-8.0.x}

if [ "$D8_COMMIT" != "none" ]; then
  git clone https://github.com/drupal/drupal.git ~/drupal-8.0.0-rc1
  cd ~/drupal-8.0.0-rc1
  git checkout $D8_COMMIT
  D8_ACTUAL_COMMIT=`git rev-parse --short HEAD`
  D8_COMMIT_TIME=$(git show -s --format=%ct $D8_ACTUAL_COMMIT)
  tar -C ~/ -czf ~/drupal-8.0.0-rc1.tar.gz drupal-8.0.0-rc1 --exclude-vcs
  mv ~/drupal-8.0.0-rc1.tar.gz ~/oss/targets/drupal8/drupal-8.0.0-rc1.tar.gz
fi

mkdir -p ~/maat/results
cp ~/oss/base/PerfSettings.php ~/maat/tools/oss/PerfSettingsBackup.php

# Prepare concurrencies
IFS=","
CONCURRENCIES_RAW=${1:-"1,5,20"}
CONCURRENCIES=($CONCURRENCIES_RAW)

for c in "${CONCURRENCIES[@]}"
do
  echo -e "\n************************************************"
  echo -e "***** Running D8 batch with concurrency ${c}..."
  CONC_LINE=`grep -n "BenchmarkConcurrency" ~/oss/base/PerfSettings.php | cut -f1 -d:`
  sed -i "$(($CONC_LINE + 1))s/return.*/return ${c};/" ~/oss/base/PerfSettings.php 
  hhvm ~/oss/batch-run.php --i-am-not-benchmarking --no-proxygen < ~/maat/tools/d8_progress.json > ~/maat/results/results_c${c}_${D8_ACTUAL_COMMIT}_${CURRENT_DATE}.json

done

echo -e "\n*************************************"
echo -e "***** Posting data to API endpoint..."

export D8_ACTUAL_COMMIT
export D8_COMMIT_TIME
hhvm ~/maat/scripts/postresults.php

echo -e "\n***** Cleaning up..."

cp ~/maat/tools/oss/PerfSettingsBackup.php ~/oss/base/PerfSettings.php

if [ "$MAAT_AUTO_CLEANUP_RESULTS" = true ]; then
  rm -r ~/maat/results
  rm -rf /tmp/hhvm-nginx*
fi

