#!/usr/bin/env bash

echo "Beginning provisioning on $(whoami)@$(hostname)"

sudo apt-get update -y && sudo apt-get -y upgrade && sudo apt-get -y autoremove
#sudo do-release-upgrade

# upgrade monitoring: https://www.digitalocean.com/docs/monitoring/how-to/upgrade-legacy-agent/
#sudo apt-get purge do-agent
curl -sSL https://repos.insights.digitalocean.com/install.sh | sudo bash

#EOF