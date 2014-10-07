#---------------------------------------------------------------------
# Config
#---------------------------------------------------------------------
$reportEmail 		 = 'REPORT_EMAIL'

$rootPwd     		 = 'ROOT_PWD_ENCODED'
$newUserName 		 = 'USER_NAME'
$newUserPwd  		 = 'USER_PWD_ENCODED'

$sshKeyComment 		 = 'SSH_KEY_COMMENT'
$sshKeyType    		 = 'SSH_KEY_TYPE'
$sshKeyContent 		 = 'SSH_KEY_CONTENT'
$sshPort	   		 = SSH_PORT

# Tripwire
$twLocalPassphrase 	 = 'TW_LOCAL_PASSPHRASE'
$twSitePassphrase 	 = 'TW_SITE_PASSPHRASE'

$knockdSequenceOpen  = 'KNOCKD_SEQ_OPEN' #4000:udp,4697:tcp,3102:udp
$knockdSequenceClose = 'KNOCKD_SEQ_CLOSE' #7634:tcp,3861:udp,4923:tcp