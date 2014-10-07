#!/bin/bash
# 
# We define parameters the user should provide when deploying to Linode with Stackscripts.
# 
#<UDF name="REPORT_EMAIL" Label="Report email" default="root@localhost" />
#<UDF name="ROOT_PWD" Label="Root password" default="" />
#<UDF name="USER_NAME" Label="New (non-root) user name" default="myUser" />
#<UDF name="USER_PWD" Label="New (non-root) user password" default="" />
#<UDF name="SSH_KEY_COMMENT" Label="SSH key comment" default="" />
#<UDF name="SSH_KEY_TYPE" Label="SSH key type" default="ssh-rsa" />
#<UDF name="SSH_KEY_CONTENT" Label="SSH key content" default="" />
#<UDF name="SSH_PORT" Label="SSH port" default="22" />
#<UDF name="TW_LOCAL_PASSPHRASE" Label="Tripwire local passphrase" default="" />
#<UDF name="TW_SITE_PASSPHRASE" Label="Tripwire site passphrase" default="" />
#<UDF name="KNOCKD_SEQ_OPEN" Label="Knockd sequence open" default="" />
#<UDF name="KNOCKD_SEQ_CLOSE" Label="Knockd sequence close" default="" />
#

genpasswd() {
	local l=$1
   	[ "$l" == "" ] && l=16
  	tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}

# No linode ID defined, probably called from shell
if [ "$LINODE_ID" == '' ]; then
	# We should ask the user to manually enter values


fi

# Generate values for parameters not defined
if [ "$ROOT_PWD" == '' ]; then
	echo "\n---------------------------"
	echo "No root password provided, generating..."
	ROOT_PWD=$(genpasswd 50)
	echo "Root password : $ROOT_PWD"
fi

if [ "$USER_PWD" == '' ]; then
	echo "\n---------------------------"
	echo "No user password provided, generating..."
	USER_PWD=$(genpasswd 50)
	echo "User password : $USER_PWD"
fi

if [ "$SSH_KEY_CONTENT" == '' ]; then
	echo "\n---------------------------"
	echo "No SSH key provided, generating..."
	ssh-keygen -t rsa -N "" -C "$USER_NAME@$HOSTNAME" -f /tmp/generatedKey
	TMP_PUB_KEY=$(cat /tmp/generatedKey.pub)
	[[ $TMP_PUB_KEY =~ ^([^ ]+)\ ([^ ]+)\ (.*)$ ]]
	SSH_KEY_TYPE="${BASH_REMATCH[1]}"
	SSH_KEY_CONTENT="${BASH_REMATCH[2]}"
	SSH_KEY_COMMENT="${BASH_REMATCH[3]}"
	echo "---------------------------"
	echo "- Public key :"
	echo "---------------------------\n"
	cat /tmp/generatedKey.pub
	echo "---------------------------"
	echo "- Private key :"
	echo "---------------------------\n"
	cat /tmp/generatedKey
fi

if [ "$TW_LOCAL_PASSPHRASE" == '' ]; then
	echo "\n---------------------------"
	echo "No Tripwire local passphrase provided, generating..."
	TW_LOCAL_PASSPHRASE=$(genpasswd 50)
	echo "Tripwire local passphrase : $TW_LOCAL_PASSPHRASE"
fi

if [ "$TW_SITE_PASSPHRASE" == '' ]; then
	echo "\n---------------------------"
	echo "No Tripwire site passphrase provided, generating..."
	TW_SITE_PASSPHRASE=$(genpasswd 50)
	echo "Tripwire site passphrase : $TW_SITE_PASSPHRASE"
fi

if [ "$KNOCKD_SEQ_OPEN" == '' ]; then
	echo "\n---------------------------"
	echo "No Knockd sequence open provided, generating..."
	KNOCKD_SEQ_OPEN="$(shuf -i 2000-9999 -n 1):udp,$(shuf -i 2000-9999 -n 1):tcp,$(shuf -i 2000-9999 -n 1):udp"
	echo "Knockd sequence open : $KNOCKD_SEQ_OPEN"
fi

if [ "$KNOCKD_SEQ_CLOSE" == '' ]; then
	echo "\n---------------------------"
	echo "No Knockd sequence close provided, generating..."
	KNOCKD_SEQ_CLOSE="$(shuf -i 2000-9999 -n 1):tcp,$(shuf -i 2000-9999 -n 1):udp,$(shuf -i 2000-9999 -n 1):tcp"
	echo "Knockd sequence close : $KNOCKD_SEQ_CLOSE"
fi

# Hash passwords
ROOT_PWD_HASHED=""
USER_PWD_HASHED=""
     
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