#!/bin/bash

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

#---------------------------------------------------------------------
# Print report functions
#---------------------------------------------------------------------
REPORT_COLUMNS=100
REPORT_CONF_COL_NAME=25
REPORT_CONF_COL_VAL=73
REPORT_PAD=$(printf '%0.1s' "-"{1..100})

printLine() {
	printf "|%*s|\n" $(($REPORT_COLUMNS - 2 )) "$REPORT_PAD"
}

printEmptyLine() {
	printf "|%*s|\n" $(($REPORT_COLUMNS )) " "
}

printTitle() {
	local title=$1
   	title="${title} - $(date)"
   	
   	printLine
   	printEmptyLine
   	printf "|%*s%*s|\n" $(((${#title}+$REPORT_COLUMNS)/2)) "$title" $((((${#title}+$REPORT_COLUMNS)/2)-${#title}+1)) " "
}

printTitleLeft() {
	local title=$1
	
	printEmptyLine
	printLine
   	printf "| %-*s|\n" $(($REPORT_COLUMNS-1)) "$title"
	printLine
	printEmptyLine
}

printTextLeft() {
	local text=$1
   	printf "|    %-*s|\n" $(($REPORT_COLUMNS-4)) "$text"
}

printConfValueLine() {
	local name=$1
	local value=$2
	printEmptyLine
	printLine
	printEmptyLine
   	printf "|%*s: %-*s|\n" $REPORT_CONF_COL_NAME "$name" $REPORT_CONF_COL_VAL "$value"
}

IP_ADDR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
FQDN_HOSTNAME=$(hostname --fqdn)

printTitle "Deployment report for $FQDN_HOSTNAME"

#---------------------------------------------------------------------
# No linode ID defined, probably called from shell
#---------------------------------------------------------------------
if [ "$LINODE_ID" == '' ]; then
	printTitleLeft "Basic configuration..."
	printTextLeft "We will ask you for some informations to setup your new box."
	printTextLeft "If the following values are not provided, they will be randomly generated :"
	printTextLeft "    root pwd, user pwd, SSH key, SSH port, Tripwire passphrases, Knockd sequences"
	printEmptyLine
	printLine
	
	# We should ask the user to manually enter values
	read -e -p "Enter a report email: " -i "root@localhost" REPORT_EMAIL
	read -e -p "Enter a password to encrypt report: " -i "" REPORT_PWD
	read -e -p "Enter root password: " -i "" ROOT_PWD
	read -e -p "Enter new (non-root) user name: " -i "" USER_NAME
	read -e -p "Enter new (non-root) user password: " -i "" USER_PWD
	read -e -p "Enter an SSH public key: " -i "" TMP_PUB_KEY
	if [ "$TMP_PUB_KEY" == "" ]; then
		read -e -p "Enter an SSH key passphrase: " -i "" SSH_KEY_PASSPHRASE
	fi
	read -e -p "Enter an SSH port: " -i "22" SSH_PORT
	read -e -p "Enter a Tripwire local passphrase: " -i "" TW_LOCAL_PASSPHRASE
	read -e -p "Enter a Tripwire site passphrase: " -i "" TW_SITE_PASSPHRASE
	read -e -p "Enter a Knockd sequence open: " -i "" KNOCKD_SEQ_OPEN
	read -e -p "Enter a Knockd sequence close: " -i "" KNOCKD_SEQ_CLOSE

	printEmptyLine
	printTextLeft "All done !"
fi

printTitleLeft "Generating non provided params..."

#---------------------------------------------------------------------
# Generate values for parameters not defined
#---------------------------------------------------------------------
if [ "$ROOT_PWD" == '' ]; then
	printTextLeft "No root password provided, generating..."
	ROOT_PWD=$(genpasswd 50)
fi

if [ "$USER_PWD" == '' ]; then
	printTextLeft "No user password provided, generating..."
	USER_PWD=$(genpasswd 50)
fi

if [ "$TMP_PUB_KEY" != '' ]; then
	splitSSHkey "$TMP_PUB_KEY"
fi

if [ "$SSH_KEY_CONTENT" == '' ]; then
	printTextLeft "No SSH key provided, generating..."
	rm -f /tmp/generatedKey
	rm -f /tmp/generatedKey.pub
	ssh-keygen -q -t rsa -N "$SSH_KEY_PASSPHRASE" -C "$USER_NAME@$FQDN_HOSTNAME" -f /tmp/generatedKey
	TMP_PUB_KEY=$(cat /tmp/generatedKey.pub)
	splitSSHkey "$TMP_PUB_KEY"
fi

if [ "$SSH_PORT" == '' ]; then
	printTextLeft "No SSH port provided, generating..."
	SSH_PORT="$(shuf -i 2000-9999 -n 1)"
fi

if [ "$TW_LOCAL_PASSPHRASE" == '' ]; then
	printTextLeft "No Tripwire local passphrase provided, generating..."
	TW_LOCAL_PASSPHRASE=$(genpasswd 50)
fi

if [ "$TW_SITE_PASSPHRASE" == '' ]; then
	printTextLeft "No Tripwire site passphrase provided, generating..."
	TW_SITE_PASSPHRASE=$(genpasswd 50)
fi

if [ "$KNOCKD_SEQ_OPEN" == '' ]; then
	printTextLeft "No Knockd sequence open provided, generating..."
	KNOCKD_SEQ_OPEN="$(shuf -i 2000-9999 -n 1):udp,$(shuf -i 2000-9999 -n 1):tcp,$(shuf -i 2000-9999 -n 1):udp"
fi

if [ "$KNOCKD_SEQ_CLOSE" == '' ]; then
	printTextLeft "No Knockd sequence close provided, generating..."
	KNOCKD_SEQ_CLOSE="$(shuf -i 2000-9999 -n 1):tcp,$(shuf -i 2000-9999 -n 1):udp,$(shuf -i 2000-9999 -n 1):tcp"
fi

printEmptyLine
printTextLeft "All done !"

#---------------------------------------------------------------------
# Generating configuration report...
#---------------------------------------------------------------------
printTitleLeft "Generating configuration report..."

printTitle "Configuration report" > /root/deploy-config.log

CONF_VALUES=( "IP_ADDR" "FQDN_HOSTNAME" "SSH_PORT" "REPORT_EMAIL" "REPORT_PWD" "ROOT_PWD" "USER_NAME" "USER_PWD" "TW_LOCAL_PASSPHRASE" "TW_SITE_PASSPHRASE" "KNOCKD_SEQ_OPEN" "KNOCKD_SEQ_CLOSE" )

for i in "${CONF_VALUES[@]}"; do
	printConfValueLine "$i" "${!i}" >> /root/deploy-config.log
done

# If we generated an SSH key
if [ -f "/tmp/generatedKey" ]; then
	printConfValueLine "SSH_KEY_PASSPHRASE" "$SSH_KEY_PASSPHRASE" >> /root/deploy-config.log

	printConfValueLine "SSH_PRIVATE_KEY" "" >> /root/deploy-config.log
	cat /tmp/generatedKey >> /root/deploy-config.log
	
	printConfValueLine "SSH_PUBLIC_KEY" "" >> /root/deploy-config.log
	cat /tmp/generatedKey.pub >> /root/deploy-config.log
	
	rm -f /tmp/generatedKey
	rm -f /tmp/generatedKey.pub
fi

printTextLeft "All done !"

#---------------------------------------------------------------------
# Install needed packages for deployment
#---------------------------------------------------------------------
printTitleLeft "Installing needed packages for deployment..."

apt-get update -q > /root/deploy-details.log
apt-get upgrade -q -y > /dev/null
apt-get install -q -y build-essential ruby-dev git puppet makepasswd > /root/deploy-details.log
gem install -q librarian-puppet > /root/deploy-details.log

printEmptyLine
printTextLeft "All done !"

#---------------------------------------------------------------------
# Hash passwords
#---------------------------------------------------------------------
printTitleLeft "Hashing passwords..."

ROOT_PWD_HASHED=$(mkpasswd -m sha-512 $ROOT_PWD | tr -d '\n')
USER_PWD_HASHED=$(mkpasswd -m sha-512 $USER_PWD | tr -d '\n')

printTextLeft "All done !"

#---------------------------------------------------------------------
# Get Puppet manifests from Github
#---------------------------------------------------------------------
printTitleLeft "Download Puppet manifests from Github..."

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

cp /etc/puppet/manifests/config.example.pp /etc/puppet/manifests/config.pp

rm -rf /tmp/puppet-conf

printTextLeft "All done !"

#---------------------------------------------------------------------
# Install Puppet modules dependencies
#---------------------------------------------------------------------
printTitleLeft "Install Puppet modules dependencies..."

librarian-puppet install

printTextLeft "All done !"

#---------------------------------------------------------------------
# Replace values in config.pp with variables content
#---------------------------------------------------------------------
printTitleLeft "Replace values in Puppet config manifest..."

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

printTextLeft "All done !"

#---------------------------------------------------------------------
# Here we go !
#---------------------------------------------------------------------
printTitleLeft "Applying Puppet manifest..."

puppet apply manifests/site.pp > /root/deploy-details.log

printEmptyLine
printTextLeft "All done !"

#---------------------------------------------------------------------
# Sending report to email provided
#---------------------------------------------------------------------
printTitleLeft "Sending report to $REPORT_EMAIL..."

if [ -d "/etc/exim4" ]; then
	apt-get install -y -q mutt
	MUTT_INSTALLED=1
else
	MUTT_INSTALLED=0
fi

# TODO: add REPORT_PWD param & encrypt file as it contains sensitive informations !
# TODO: send deploy-details too
# http://www.cyberciti.biz/tips/linux-how-to-encrypt-and-decrypt-files-with-a-password.html
if [ MUTT_INSTALLED == 0 ]; then
	cat /etc/puppet/manifests/config.pp | mail -s "Puppet config for $IP_ADDR - $FQDN_HOSTNAME" "$REPORT_EMAIL"
	cat /root/deploy.log | mail -s "Deploying report for $IP_ADDR - $FQDN_HOSTNAME" "$REPORT_EMAIL"
	cat /root/deploy-conf.log | mail -s "Deploying report conf for $IP_ADDR - $FQDN_HOSTNAME" "$REPORT_EMAIL"
	cat /root/deploy-details.log | mail -s "Deploying report details for $IP_ADDR - $FQDN_HOSTNAME" "$REPORT_EMAIL"
else
	echo "You will find all the details attached to this message." | mutt -s "Deploying report for $IP_ADDR - $FQDN_HOSTNAME" -a /etc/puppet/manifests/config.pp -a /root/deploy.log -a /root/deploy-details.log -a /root/deploy-config.log "$REPORT_EMAIL"
fi

printTextLeft "All done !"

#---------------------------------------------------------------------
# Removing report from filesystem
#---------------------------------------------------------------------
printTitleLeft "Removing report from filesystem"

rm -f /root/deploy.log
rm -f /root/deploy-details.log
rm -f /root/deploy-config.log

printTextLeft "All done !"

#---------------------------------------------------------------------
# Removing Puppet config from fs
#---------------------------------------------------------------------
printTitleLeft "Removing Puppet config from filesystem"

rm -f /etc/puppet/manifests/config.pp

printTextLeft "All done !"

#---------------------------------------------------------------------
# Reboot to be sure all changes are applied
#---------------------------------------------------------------------
printTitleLeft "Reboot to be sure all changes are applied..."

reboot
