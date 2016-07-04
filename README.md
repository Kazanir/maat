### Drupal Performance Testing

This repository is a set of configuration files and scripts to set up a machine for Drupal load testing on PHP5, PHP7, and HHVM. To set up a completely new server (the intention is to use spot-priced AWS instances cheaply) simply run the following:

```
cd ~
wget -O - https://raw.githubusercontent.com/Kazanir/maat/master/scripts/install.sh | sudo sh
./maat/scripts/provision.sh
```

Initially this repository was intending to do most of the site setup and benchmarking itself, but around the time I started working on it I found the HHVM team's OSS Performance tool (https://github.com/hhvm/oss-performance). This allowed me to save a bunch of work, so I turned this repository into an orchestration layer for their tool. A set of shell scripts do most of the legwork; each is described below.

#### install.sh

Provided as a remote installer that can operate via a wget or curl request.

#### provision.sh

Provisions the machine, adding the appropriate Aptitude repositories, setting up the MySQL server, and adding some convenient tooling like Composer, perf, and Blackfire. (The basic OSS perf scripts only use Siege but the machine has other abilities for those who want to get fancy.)

#### osiris.sh

Runs the contents of `tools/batch.json` through oss-performance with a concurrency of 1, 5, and 20. The default batch includes Drupal 7 (w/o page cache) and Drupal 8 both with and without the page cache.

#### thoth.sh 

Takes 2 arguments: A concurrency list (such as "1,5,20") and a Drupal 8 commit hash. If no commit hash is provided, the default is the tip of the 8.1.x-dev branch. If the second argument is "none", the script will use the oss-performance default for Drupal 8, which was beta 11. At the end of this script, the assembled results are posted to the Maat endpoint exported in the shell environment. See `scripts/postresults.php` for details.

#### postresults.php

Uses environment variables and reads all result files to post to the endpoint defined in various `MAAT_` shell variables. 

#### ec2.sh

This script is designed to be run from a local copy of this repo. It puts together the necessary information to make a spot request to AWS, booting up an instance and feeding it the proper data to run `scripts/thoth.sh` on that instance and then shutting it down automatically. It requires both account-specific adjustments as well as a preconfigured copy of the AWS CLI tool with credentials available to work.
