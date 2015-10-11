#!/bin/bash -e

INSTANCE_CLASS=$1
D8_COMMIT=$2
LAST_HOUR=`date --date='-1 hours' +%Y-%m-%dT%H:%M:%S`

SPOT_USER_SCRIPT="#!/bin/bash
set -vx
cd /home/ubuntu
apt-get update -y
apt-get install git -y
MAAT_RESULTS_ENDPOINT='http://www.your.results.endpoint.here'
MAAT_INFRASTRUCTURE_TAG='ec2/c4.xlarge'
MAAT_AUTO_CLEANUP_RESULTS=false
MAAT_RESULTS_USER='basicauth_username'
MAAT_RESULTS_PASS='basicauth_password'
export MAAT_AUTO_CLEANUP_RESULTS
export MAAT_INFRASTRUCTURE_TAG
export MAAT_RESULTS_ENDPOINT
export MAAT_RESULTS_USER
export MAAT_RESULTS_PASS
su ubuntu -c 'git clone https://github.com/Kazanir/maat.git'
su ubuntu -c './maat/scripts/provision.sh'
su ubuntu -c './maat/scripts/thoth.sh 1,5,20 $D8_COMMIT'
"

ENCODED_USER_SCRIPT=$(base64 -w 0 <<< "$SPOT_USER_SCRIPT")

SPOT_PRICE=$(aws ec2 describe-spot-price-history \
  --start-time=$LAST_HOUR \
  --instance-type=$INSTANCE_CLASS \
  --product-descriptions="Linux/UNIX" \
  --output="text" \
  | awk 'BEGIN {max = 0} {if ($5>max) max=$5} END {printf("%.2f",max+0.005)}')

aws ec2 request-spot-instances \
  --spot-price $SPOT_PRICE \
  --type "one-time" \
  --instance-count 1 \
  --output "text" \
  --launch-specification \
    "{ 
      \"ImageId\":\"ami-5189a661\", 
      \"KeyName\":\"YOUR PRIVATE KEY NAME HERE\", 
      \"InstanceType\":\"$INSTANCE_CLASS\", 
      \"SecurityGroups\": [\"your_security_group_here\"], 
      \"SecurityGroupIds\": [\"sg-12345678\"], 
      \"BlockDeviceMappings\": [
            {
                \"DeviceName\": \"/dev/sda1\",
                \"Ebs\": {
                    \"VolumeSize\": 20,
                    \"DeleteOnTermination\": true,
                    \"Encrypted\": true
                }
            }
        ],
      \"UserData\":\"$ENCODED_USER_SCRIPT\" 
    }" \
  | grep SPOTINSTANCEREQUESTS | awk '{print $4}'


