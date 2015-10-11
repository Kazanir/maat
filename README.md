### Drupal Performance Testing

This repository is a set of configuration files and scripts to set up a machine for Drupal load testing on PHP5, PHP7, and HHVM. To set up a completely new server (the intention is to use spot-priced AWS instances cheaply) simply run the following:

```
cd ~
wget -O - https://raw.githubusercontent.com/Kazanir/maat/master/scripts/install.sh | sudo sh
./maat/scripts/provision.sh
```

Initially this repository was intending to do most of the site setup and benchmarking itself, but around the time I started working on it I found the HHVM team's OSS Performance tool (https://github.com/hhvm/oss-perforamnce). This allowed me to save a bunch of work, so I turned this repository into an orchestration layer for their tool. Primarily the tooling around `scripts/thoth.sh` will run through a large batch of benchmarks using the OSS Perf tool and then has the option to report a JSON of those results to a desired API endpoint, which is set via an environment variable.

This allows me to essentially run a complete copy of the benchmarks and post their data back to my home server by means of a small AWS spot request and user-init script. An example of this is found in `scripts/ec2.sh` even though it is conceptually separate from the rest of the stuff in the repo.
