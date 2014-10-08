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

exec > >(tee /root/deploy.log)
exec 2>&1

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

echo ""
echo "------------------------------------------------------"
echo "- Welcome ! - $(date)"
echo "------------------------------------------------------"
echo ""

#---------------------------------------------------------------------
# No linode ID defined, probably called from shell
#---------------------------------------------------------------------
if [ "$LINODE_ID" == '' ]; then
	echo "- We will ask you for some informations to setup your new box."
	echo "- If the following values are not provided, they will be randomly generated :"
	echo "-     root pwd, user pwd, SSH key, SSH port, Tripwire passphrases, Knockd sequences"
	echo ""
	echo "------------------------------------------------------"
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
	echo "------------------------------------------------------"
	echo ""
fi

#---------------------------------------------------------------------
# Generate values for parameters not defined
#---------------------------------------------------------------------
if [ "$ROOT_PWD" == '' ]; then
	echo ""
	echo "------------------------------------------------------"
	echo "- No root password provided, generating..."
	ROOT_PWD=$(genpasswd 50)
	echo "- Root password : $ROOT_PWD"
fi

if [ "$USER_PWD" == '' ]; then
	echo ""
	echo "------------------------------------------------------"
	echo "- No user password provided, generating..."
	USER_PWD=$(genpasswd 50)
	echo "- User password : $USER_PWD"
fi

if [ "$TMP_PUB_KEY" != '' ]; then
	splitSSHkey "$TMP_PUB_KEY"
fi

if [ "$SSH_KEY_CONTENT" == '' ]; then
	echo ""
	echo "------------------------------------------------------"
	echo "- No SSH key provided, generating..."
	rm -f /tmp/generatedKey
	rm -f /tmp/generatedKey.pub
	ssh-keygen -t rsa -N "" -C "$USER_NAME@$HOSTNAME" -f /tmp/generatedKey
	TMP_PUB_KEY=$(cat /tmp/generatedKey.pub)
	splitSSHkey "$TMP_PUB_KEY"
	echo "------------------------------------------------------"
	echo "- Public key :"
	echo "------------------------------------------------------"
	echo ""
	cat /tmp/generatedKey.pub
	echo "------------------------------------------------------"
	echo "- Private key :"
	echo "------------------------------------------------------"
	echo ""
	cat /tmp/generatedKey
	
	rm -f /tmp/generatedKey.pub
	rm -f /tmp/generatedKey
fi

if [ "$SSH_PORT" == '' ]; then
	echo ""
	echo "------------------------------------------------------"
	echo "- No SSH port provided, generating..."
	SSH_PORT="$(shuf -i 2000-9999 -n 1)"
	echo "- SSH port : $SSH_PORT"
fi

if [ "$TW_LOCAL_PASSPHRASE" == '' ]; then
	echo ""
	echo "------------------------------------------------------"
	echo "- No Tripwire local passphrase provided, generating..."
	TW_LOCAL_PASSPHRASE=$(genpasswd 50)
	echo "- Tripwire local passphrase : $TW_LOCAL_PASSPHRASE"
fi

if [ "$TW_SITE_PASSPHRASE" == '' ]; then
	echo ""
	echo "------------------------------------------------------"
	echo "- No Tripwire site passphrase provided, generating..."
	TW_SITE_PASSPHRASE=$(genpasswd 50)
	echo "- Tripwire site passphrase : $TW_SITE_PASSPHRASE"
fi

if [ "$KNOCKD_SEQ_OPEN" == '' ]; then
	echo ""
	echo "------------------------------------------------------"
	echo "- No Knockd sequence open provided, generating..."
	KNOCKD_SEQ_OPEN="$(shuf -i 2000-9999 -n 1):udp,$(shuf -i 2000-9999 -n 1):tcp,$(shuf -i 2000-9999 -n 1):udp"
	echo "- Knockd sequence open : $KNOCKD_SEQ_OPEN"
fi

if [ "$KNOCKD_SEQ_CLOSE" == '' ]; then
	echo ""
	echo "------------------------------------------------------"
	echo "- No Knockd sequence close provided, generating..."
	KNOCKD_SEQ_CLOSE="$(shuf -i 2000-9999 -n 1):tcp,$(shuf -i 2000-9999 -n 1):udp,$(shuf -i 2000-9999 -n 1):tcp"
	echo "- Knockd sequence close : $KNOCKD_SEQ_CLOSE"
fi

echo ""
echo "------------------------------------------------------"
echo "- All config values entered/generated, starting..."
echo "------------------------------------------------------"
echo ""

#---------------------------------------------------------------------
# Install needed packages for deployment
#---------------------------------------------------------------------
echo ""
echo "------------------------------------------------------"
echo "- Installing needed packages for deployment..."
echo "------------------------------------------------------"
echo ""
apt-get update -q > /root/deploy-details.log
apt-get upgrade -q -y > /dev/null
apt-get install -q -y build-essential ruby-dev git puppet makepasswd > /root/deploy-details.log
gem install librarian-puppet > /root/deploy-details.log 2>&1

#---------------------------------------------------------------------
# Hash passwords
#---------------------------------------------------------------------
echo ""
echo "------------------------------------------------------"
echo "- Hashing passwords..."
echo "------------------------------------------------------"
echo ""
ROOT_PWD_HASHED=$(mkpasswd -m sha-512 $ROOT_PWD | tr -d '\n')
USER_PWD_HASHED=$(mkpasswd -m sha-512 $USER_PWD | tr -d '\n')

#---------------------------------------------------------------------
# Get Puppet manifests from Github
#---------------------------------------------------------------------
echo ""
echo "------------------------------------------------------"
echo "- Download Puppet manifests from Github..."
echo "------------------------------------------------------"
echo ""
if [ ! -d "/etc/puppet" ]; then
	mkdir /etc/puppet
fi
cd /etc/puppet

mkdir /tmp/puppet-conf
cd /tmp/puppet-conf
wget -q https://github.com/leeroybrun/puppet-server-config/tarball/master -O puppet.tar.gz > /root/deploy-details.log
tar -zxf puppet.tar.gz --strip-components=1 > /root/deploy-details.log
cp -r puppet/* /etc/puppet

cd /etc/puppet

rm -rf /tmp/puppet-conf

#---------------------------------------------------------------------
# Install Puppet modules dependencies
#---------------------------------------------------------------------
echo ""
echo "------------------------------------------------------"
echo "- Install Puppet modules dependencies..."
echo "------------------------------------------------------"
echo ""
librarian-puppet install

#---------------------------------------------------------------------
# Replace values in config.pp with variables content
#---------------------------------------------------------------------
echo ""
echo "------------------------------------------------------"
echo "- Replace values in Puppet config manifest..."
echo "------------------------------------------------------"
echo ""
sed -i.bak "s/REPORT_EMAIL/$(echo $REPORT_EMAIL | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/ROOT_PWD_HASHED/$(echo $ROOT_PWD_HASHED | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/USER_NAME/$(echo $USER_NAME | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/USER_PWD_HASHED/$(echo $USER_PWD_HASHED | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/SSH_KEY_COMMENT/$(echo $SSH_KEY_COMMENT | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/SSH_KEY_TYPE/$(echo $SSH_KEY_TYPE | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/SSH_KEY_CONTENT/$(echo $SSH_KEY_CONTENT | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/SSH_PORT/$(echo $SSH_PORT | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/TW_LOCAL_PASSPHRASE/$(echo $TW_LOCAL_PASSPHRASE | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/TW_SITE_PASSPHRASE/$(echo $TW_SITE_PASSPHRASE | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/KNOCKD_SEQ_OPEN/$(echo $KNOCKD_SEQ_OPEN | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp
sed -i.bak "s/KNOCKD_SEQ_CLOSE/$(echo $KNOCKD_SEQ_CLOSE | sed -e 's/[\/&]/\\&/g')/g" /etc/puppet/manifests/config.pp

#---------------------------------------------------------------------
# Here we go !
#---------------------------------------------------------------------
echo ""
echo "------------------------------------------------------"
echo "- Applying Puppet manifest..."
echo "------------------------------------------------------"
echo ""
puppet apply manifests/site.pp > /root/deploy-details.log

#---------------------------------------------------------------------
# Sending report to email provided
#---------------------------------------------------------------------
echo ""
echo "------------------------------------------------------"
echo "- Sending report to $REPORT_EMAIL..."
echo "------------------------------------------------------"
echo ""
# TODO: add REPORT_PWD param & encrypt file as it contains sensitive informations !
# TODO: send deploy-details too
# http://www.cyberciti.biz/tips/linux-how-to-encrypt-and-decrypt-files-with-a-password.html
cat /root/deploy.log | mail -s "Deploying report for $HOSTNAME" "$REPORT_EMAIL"

#---------------------------------------------------------------------
# Removing report from filesystem
#---------------------------------------------------------------------
echo ""
echo "------------------------------------------------------"
echo "- Removing report from filesystem"
echo "------------------------------------------------------"
echo ""
rm -f /root/deploy.log
rm -f /root/deploy-details.log

echo ""
echo "------------------------------------------------------"
echo "- All done !"
echo "------------------------------------------------------"
echo ""

#---------------------------------------------------------------------
# Reboot to be sure all changes are applied
#---------------------------------------------------------------------
reboot
