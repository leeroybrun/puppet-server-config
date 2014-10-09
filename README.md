# Simple server config

Simple basic config for a fresh Ubuntu server.

## Deploy


### Deploy to Linode

You can use the Stackscript for deploying to Linode.

### Deploy everywhere

```
wget -q https://raw.githubusercontent.com/leeroybrun/puppet-server-config/master/deploy.sh && chmod +x deploy.sh && ./deploy.sh
```

## TODO

- Install mutt in deploy.sh, not with puppet. Check before if exim was successfully installed, if not, send with mail
- Encrypt report before sending by email
- Check psad Puppet module for iptables/ip6tables default logging rule (http://www.cipherdyne.org/psad/docs/fwconfig.html)
- Verify puppet modules & improve them if necessary 

## Licence

MIT
