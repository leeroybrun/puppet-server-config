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
#<UDF name="SSH_PORT" Label="SSH port" default="" />
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

splitSSHkey() {
	local key=$1
   	[[ $key =~ ^([^ ]+)\ ([^ ]+)\ (.*)$ ]]
	SSH_KEY_TYPE="${BASH_REMATCH[1]}"
	SSH_KEY_CONTENT="${BASH_REMATCH[2]}"
	SSH_KEY_COMMENT="${BASH_REMATCH[3]}"
}

#---------------------------------------------------------------------
# No linode ID defined, probably called from shell
#---------------------------------------------------------------------
if [ "$LINODE_ID" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- Welcome !"
	echo "- We will ask you for some informations to setup your new box."
	echo "- If the following values are not provided, they will be randomly generated :"
	echo "-     root pwd, user pwd, SSH key, SSH port, Tripwire passphrases, Knockd sequences"
	echo "\n------------------------------------------------------"
	# We should ask the user to manually enter values
	read -e -p "Enter a report email:" -i "root@localhost" REPORT_EMAIL
	read -e -p "Enter root password:" -i "" ROOT_PWD
	read -e -p "Enter new (non-root) user name:" -i "myUser" USER_NAME
	read -e -p "Enter new (non-root) user password:" -i "" USER_PWD
	read -e -p "Enter an SSH public key:" -i "" TMP_PUB_KEY
	read -e -p "Enter an SSH port:" -i "22" SSH_PORT
	read -e -p "Enter a Tripwire local passphrase:" -i "22" TW_LOCAL_PASSPHRASE
	read -e -p "Enter a Tripwire site passphrase:" -i "22" TW_SITE_PASSPHRASE
	read -e -p "Enter a Knockd sequence open:" -i "" KNOCKD_SEQ_OPEN
	read -e -p "Enter a Knockd sequence close:" -i "" KNOCKD_SEQ_CLOSE
fi

#---------------------------------------------------------------------
# Generate values for parameters not defined
#---------------------------------------------------------------------
if [ "$ROOT_PWD" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- No root password provided, generating..."
	ROOT_PWD=$(genpasswd 50)
	echo "- Root password : $ROOT_PWD"
fi

if [ "$USER_PWD" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- No user password provided, generating..."
	USER_PWD=$(genpasswd 50)
	echo "- User password : $USER_PWD"
fi

if [ "$TMP_PUB_KEY" != '' ]; then
	splitSSHkey "$TMP_PUB_KEY"
fi

if [ "$SSH_KEY_CONTENT" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- No SSH key provided, generating..."
	rm -f /tmp/generatedKey
	rm -f /tmp/generatedKey.pub
	ssh-keygen -t rsa -N "" -C "$USER_NAME@$HOSTNAME" -f /tmp/generatedKey
	TMP_PUB_KEY=$(cat /tmp/generatedKey.pub)
	splitSSHkey "$TMP_PUB_KEY"
	echo "------------------------------------------------------"
	echo "- Public key :"
	echo "------------------------------------------------------\n"
	cat /tmp/generatedKey.pub
	echo "------------------------------------------------------"
	echo "- Private key :"
	echo "------------------------------------------------------\n"
	cat /tmp/generatedKey
fi

if [ "$SSH_PORT" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- No SSH port provided, generating..."
	SSH_PORT="$(shuf -i 2000-9999 -n 1)"
	echo "- SSH port : $SSH_PORT"
fi

if [ "$TW_LOCAL_PASSPHRASE" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- No Tripwire local passphrase provided, generating..."
	TW_LOCAL_PASSPHRASE=$(genpasswd 50)
	echo "- Tripwire local passphrase : $TW_LOCAL_PASSPHRASE"
fi

if [ "$TW_SITE_PASSPHRASE" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- No Tripwire site passphrase provided, generating..."
	TW_SITE_PASSPHRASE=$(genpasswd 50)
	echo "- Tripwire site passphrase : $TW_SITE_PASSPHRASE"
fi

if [ "$KNOCKD_SEQ_OPEN" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- No Knockd sequence open provided, generating..."
	KNOCKD_SEQ_OPEN="$(shuf -i 2000-9999 -n 1):udp,$(shuf -i 2000-9999 -n 1):tcp,$(shuf -i 2000-9999 -n 1):udp"
	echo "- Knockd sequence open : $KNOCKD_SEQ_OPEN"
fi

if [ "$KNOCKD_SEQ_CLOSE" == '' ]; then
	echo "\n------------------------------------------------------"
	echo "- No Knockd sequence close provided, generating..."
	KNOCKD_SEQ_CLOSE="$(shuf -i 2000-9999 -n 1):tcp,$(shuf -i 2000-9999 -n 1):udp,$(shuf -i 2000-9999 -n 1):tcp"
	echo "- Knockd sequence close : $KNOCKD_SEQ_CLOSE"
fi

echo "\n------------------------------------------------------"
echo "- All config values entered/generated, starting..."
echo "------------------------------------------------------\n"

#---------------------------------------------------------------------
# Install needed packages for deployment
#---------------------------------------------------------------------
echo "\n------------------------------------------------------"
echo "- Installing needed packages for deployment..."
echo "------------------------------------------------------\n"
apt-get update -q
apt-get upgrade -q -y
apt-get install -q -y build-essential ruby-dev git puppet makepasswd
gem install librarian-puppet

#---------------------------------------------------------------------
# Hash passwords
#---------------------------------------------------------------------
echo "\n------------------------------------------------------"
echo "- Hashing passwords..."
echo "------------------------------------------------------\n"
ROOT_PWD_HASHED=$(mkpasswd -m sha-512 $ROOT_PWD | tr -d '\n')
USER_PWD_HASHED=$(mkpasswd -m sha-512 $USER_PWD | tr -d '\n')

#---------------------------------------------------------------------
# Get Puppet manifests from Github
#---------------------------------------------------------------------
echo "\n------------------------------------------------------"
echo "- Download Puppet manifests from Github..."
echo "------------------------------------------------------\n"
mkdir /etc/puppet
cd /etc/puppet

mkdir /tmp/puppet-conf
cd /tmp/puppet-conf
wget https://github.com/leeroybrun/puppet-server-config/tarball/master -O puppet.tar.gz
tar -zxvf puppet.tar.gz --strip-components=1
cp -r puppet/ /etc/puppet

cd /etc/puppet

rm -rf /tmp/puppet-conf

#---------------------------------------------------------------------
# Install Puppet modules dependencies
#---------------------------------------------------------------------
echo "\n------------------------------------------------------"
echo "- Install Puppet modules dependencies..."
echo "------------------------------------------------------\n"
librarian-puppet install

#---------------------------------------------------------------------
# Replace values in config.pp with variables content
#---------------------------------------------------------------------
echo "\n------------------------------------------------------"
echo "- Replace values in Puppet config manifest..."
echo "------------------------------------------------------\n"
sed -i.bak 's/REPORT_EMAIL/"${REPORT_EMAIL}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/ROOT_PWD_HASHED/"${ROOT_PWD_HASHED}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/USER_NAME/"${USER_NAME}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/USER_PWD_HASHED/"${USER_PWD_HASHED}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/SSH_KEY_COMMENT/"${SSH_KEY_COMMENT}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/SSH_KEY_TYPE/"${SSH_KEY_TYPE}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/SSH_KEY_CONTENT/"${SSH_KEY_CONTENT}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/SSH_PORT/"${SSH_PORT}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/TW_LOCAL_PASSPHRASE/"${TW_LOCAL_PASSPHRASE}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/TW_SITE_PASSPHRASE/"${TW_SITE_PASSPHRASE}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/KNOCKD_SEQ_OPEN/"${KNOCKD_SEQ_OPEN}"/g' /etc/puppet/manifests/config.pp
sed -i.bak 's/KNOCKD_SEQ_CLOSE/"${KNOCKD_SEQ_CLOSE}"/g' /etc/puppet/manifests/config.pp

#---------------------------------------------------------------------
# Here we go !
#---------------------------------------------------------------------
echo "\n------------------------------------------------------"
echo "- Applying Puppet manifest..."
echo "------------------------------------------------------\n"
puppet apply manifests/site.pp

echo "\n------------------------------------------------------"
echo "- All done !"
echo "------------------------------------------------------\n"