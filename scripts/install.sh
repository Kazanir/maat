#!/bin/sh

set -x

sudo apt-get update -y
sudo apt-get install git -y

git clone https://github.com/Kazanir/maat.git

# Once this has run, you can provision with:
# ./maat/scripts/provision.sh

