#!/bin/bash

# Add a hostname to the benchmarks "wildcards"
echo <<<HOSTS |
  127.0.0.1 $1.php5.benchmark
  127.0.0.1 $1.php7.benchmark
  127.0.0.1 $1.hhvm.benchmark
HOSTS
sudo tee -a /etc/hosts
