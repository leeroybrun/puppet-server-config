
#---------------------------------------------------------------------
# Config
#---------------------------------------------------------------------
import 'config.pp'

#---------------------------------------------------------------------
# apt-get update/upgrade
#---------------------------------------------------------------------
	include apt

	exec { "apt-update":
	    command => "/usr/bin/apt-get update"
	}

	exec { "apt-upgrade":
	    command => "/usr/bin/apt-get upgrade"
	}

#---------------------------------------------------------------------
# Change root password and create a new user
#---------------------------------------------------------------------
	user {'root':
		password => $rootPwd
	}

	user {$newUserName:
		ensure => present,
		managehome => 'true',
		password => $newUserPwd
	}

#---------------------------------------------------------------------
# Add SSH key
#---------------------------------------------------------------------
	ssh_authorized_key { $sshKeyComment:
		user => $newUserName,
		type => $sshKeyType,
		key  => $sshKeyContent,
	}

#---------------------------------------------------------------------
# Add new user to sudoers
#---------------------------------------------------------------------
	sudo::conf { $newUserName:
		content => '${newUserName} ALL=(ALL) ALL',
	}

#---------------------------------------------------------------------
# More secure SSH config
#---------------------------------------------------------------------
	class { 'ssh::server':
		storeconfigs_enabled => false,
		options => {
			'PasswordAuthentication' => 'no',
			'PermitRootLogin'        => 'no',
			'Port'                   => $sshPort,
			'AllowUsers'			 => $newUserPwd
		},
	}

#---------------------------------------------------------------------
# Enable and configure firewall
#---------------------------------------------------------------------
	package { "iptables-persistent":
	    ensure => "installed"
	}

	include ufw

	ufw::allow { "allow-http-from-all":
		port => 80,
		proto => "tcp"
	}

	ufw::allow { "allow-https-from-all":
		port => 443,
		proto => "tcp"
	}

	ufw::logging { "activate-logging":
	    level => 'on',
	}

#---------------------------------------------------------------------
# Let packages be automatically updated
#---------------------------------------------------------------------
	package { "unattended-upgrades":
	    ensure => "installed"
	}

	file { "/etc/apt/apt.conf.d/10periodic":
	    content  => "APT::Periodic::Update-Package-Lists \"1\";
					APT::Periodic::Download-Upgradeable-Packages \"1\";
					APT::Periodic::AutocleanInterval \"7\";
					APT::Periodic::Unattended-Upgrade \"1\";",
	}

	file { "/etc/apt/apt.conf.d/50unattended-upgrades":
	    content  => "// Automatically upgrade packages from these (origin:archive) pairs
					Unattended-Upgrade::Allowed-Origins {
					        \"${distro_id}:${distro_codename}-security\";
					//      \"${distro_id}:${distro_codename}-updates\";
					//      \"${distro_id}:${distro_codename}-proposed\";
					//      \"${distro_id}:${distro_codename}-backports\";
					};",
	}

#---------------------------------------------------------------------
# Install and configure LogWatch
#---------------------------------------------------------------------
	package { "logwatch":
	    ensure => "installed"
	}

	file { "/etc/cron.daily/00logwatch":
	    content  => "#!/bin/bash

					#Check if removed-but-not-purged
					test -x /usr/share/logwatch/scripts/logwatch.pl || exit 0

					/usr/sbin/logwatch --output mail --mailto ${reportEmail} --detail high",
	}

#---------------------------------------------------------------------
# Small fixes for kernel parameters
#---------------------------------------------------------------------
	# IP Spoofing protection
	sysctl { 'net.ipv4.conf.all.rp_filter': value => '1' }
	sysctl { 'net.ipv4.conf.default.rp_filter': value => '1' }

	# Ignore ICMP broadcast requests
	sysctl { 'net.ipv4.icmp_echo_ignore_broadcasts': value => '1' }

	# Disable source packet routing
	sysctl { 'net.ipv4.conf.all.accept_source_route': value => '0' }
	sysctl { 'net.ipv6.conf.all.accept_source_route': value => '0' }
	sysctl { 'net.ipv4.conf.default.accept_source_route': value => '0' }
	sysctl { 'net.ipv6.conf.default.accept_source_route': value => '0' }

	# Ignore send redirects
	sysctl { 'net.ipv4.conf.all.send_redirects': value => '0' }
	sysctl { 'net.ipv4.conf.default.send_redirects': value => '0' }

	# Block SYN attacks
	sysctl { 'net.ipv4.tcp_syncookies': value => '1' }
	sysctl { 'net.ipv4.tcp_max_syn_backlog': value => '2048' }
	sysctl { 'net.ipv4.tcp_synack_retries': value => '2' }
	sysctl { 'net.ipv4.tcp_syn_retries': value => '5' }

	# Log Martians
	sysctl { 'net.ipv4.conf.all.log_martians': value => '1' }
	sysctl { 'net.ipv4.icmp_ignore_bogus_error_responses': value => '1' }

	# Ignore ICMP redirects
	sysctl { 'net.ipv4.conf.all.accept_redirects': value => '0' }
	sysctl { 'net.ipv6.conf.all.accept_redirects': value => '0' }
	sysctl { 'net.ipv4.conf.default.accept_redirects': value => '0' }
	sysctl { 'net.ipv6.conf.default.accept_redirects': value => '0' }

	# Ignore Directed pings
	sysctl { 'net.ipv4.icmp_echo_ignore_all': value => '1' }

#---------------------------------------------------------------------
# Monitor login attempts to SSH and ban bad IPs
#---------------------------------------------------------------------
	include fail2ban
	fail2ban::config { 'default':
		bantime => '1800',
		maxretry => 3,
		destemail => $reportEmail,
		action => 'action_mwl',
		ssh_enabled => 'true',
		sshddos_enabled => 'true'
	}

#---------------------------------------------------------------------
# Monitor ports scanning and other bad things
#---------------------------------------------------------------------
	class { 'psad' :
		config => {
			email_addresses => $reportEmail,
			ipt_syslog_file => '/var/log/syslog',
			enable_auto_ids => 'Y',
			auto_ids_danger_level => '4',
			auto_block_timeout => 3600
		}
	}

#---------------------------------------------------------------------
# Install and configure Tripwire to monitor changes to system/critical files
#---------------------------------------------------------------------
	include tripwire

	tripwire::config { 'default':
	  localpassphrase => $twLocalPassphrase,
	  sitepassphrase  => $twSitePassphrase,
	  globalemail     => $reportEmail
	}

#---------------------------------------------------------------------
# Install and enable port knocking
#---------------------------------------------------------------------
	class { 'knockd':
	  sequence_open  => $knockdSequenceOpen,
	  sequence_close => $knockdSequenceClose,
	  port_to_manage => $sshPort,
	  interface_to_manage => 'eth0',
	  command_timeout     => '15'
	}

#---------------------------------------------------------------------
# Install and configure RKHunter
#---------------------------------------------------------------------
	class { '::rkhunter':
	  rootEmail => $reportEmail,
	}

#---------------------------------------------------------------------
# Detect unused services and disable them (samba, lp, etc)
#---------------------------------------------------------------------
# service --status-all

