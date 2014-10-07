#!/bin/bash
# This block defines the variables the user of the script needs to input
# when deploying using this script. 
# 
# 
#<UDF name="host_name" Label="Server's hostname" default="appserver" />
     
apt-get update
apt-get upgrade

apt-get install build-essential ruby-dev git puppet

gem install librarian-puppet

mkdir /tmp/putty-conf
cd /tmp/putty-conf
git clone https://github.com/leeroybrun/puppet-server-config.git --depth 1 --bare

mkdir /etc/puppet
cd /etc/puppet

git --work-tree=/etc/puppet checkout HEAD -- puppet

rm -rf /tmp/putty-conf

librarian-puppet install

puppet apply manifests/site.pp