#---------------------------------------------------------------------
# Config
#---------------------------------------------------------------------
$reportEmail 		 = 'REPORT_EMAIL'			# Ex: email@domain.com

$rootPwd     		 = 'ROOT_PWD_HASHED'
$newUserName 		 = 'USER_NAME'				# Ex: myUserName
$newUserPwd  		 = 'USER_PWD_HASHED'

$sshKeyComment 		 = 'SSH_KEY_COMMENT'		# Ex: nick@magpie.puppetlabs.lan
$sshKeyType    		 = 'SSH_KEY_TYPE'			# Ex: ssh-rsa
$sshKeyContent 		 = 'SSH_KEY_CONTENT'		# Ex: AAAAB3NzaC1yc2E[...]3YhrFwjtUqXfdaQ==
$sshPort	   		 = SSH_PORT					# Ex: 22

# Tripwire
$twLocalPassphrase 	 = 'TW_LOCAL_PASSPHRASE'
$twSitePassphrase 	 = 'TW_SITE_PASSPHRASE'

$knockdSequenceOpen  = 'KNOCKD_SEQ_OPEN' 		# Ex: 4000:udp,4697:tcp,3102:udp
$knockdSequenceClose = 'KNOCKD_SEQ_CLOSE' 		# Ex: 7634:tcp,3861:udp,4923:tcp