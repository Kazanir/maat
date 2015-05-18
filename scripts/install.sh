#!/bin/sh

sudo apt-get update -y
sudo apt-get install git -y

su - `logname` -c "git clone https://github.com/Kazanir/maat.git"

echo "Repository downloaded successfully. To provision this machine, run:"
echo "./maat/scripts/provision.sh"

