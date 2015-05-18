#!/bin/sh

set -x

sudo apt-get update -y
sudo apt-get install git -y

git clone https://github.com/Kazanir/maat.git

echo "Repository downloaded successfully. To provision this machine, run:"
echo "./maat/scripts/provision.sh"

