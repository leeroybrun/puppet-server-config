#!/bin/bash
# 
# We define parameters the user should provide when deploying to Linode with Stackscripts.
# 
#<UDF name="REPORT_EMAIL" Label="Report email" default="root@localhost" />
#<UDF name="REPORT_PWD" Label="Password for encrypted report" />
#<UDF name="ROOT_PWD" Label="Root password" default="" />
#<UDF name="USER_NAME" Label="New (non-root) user name" default="myUser" />
#<UDF name="USER_PWD" Label="New (non-root) user password" default="" />
#<UDF name="SSH_KEY_COMMENT" Label="SSH key comment" default="" />
#<UDF name="SSH_KEY_TYPE" Label="SSH key type" default="ssh-rsa" />
#<UDF name="SSH_KEY_CONTENT" Label="SSH key content" default="" />
#<UDF name="SSH_PORT" Label="SSH port" default="" />
#<UDF name="TW_LOCAL_PASSPHRASE" Label="Tripwire local passphrase" default="" />
#<UDF name="TW_SITE_PASSPHRASE" Label="Tripwire site passphrase" default="" />
#<UDF name="KNOCKD_SEQ_OPEN" Label="Knockd sequence open" default="" />
#<UDF name="KNOCKD_SEQ_CLOSE" Label="Knockd sequence close" default="" />
#

# Download and execute deploy script from Github
wget -q https://raw.githubusercontent.com/leeroybrun/puppet-server-config/master/deploy.sh
chmod +x deploy.sh
source deploy.sh
