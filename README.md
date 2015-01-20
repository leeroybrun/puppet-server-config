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

- Check : https://telekomlabs.github.io
     - https://forge.puppetlabs.com/hardening/ssh_hardening
     - https://forge.puppetlabs.com/hardening/os_hardening
- Check : http://www.tenable.com/products/nessus
- Check : https://github.com/sandstorm-io/sandstorm
- Encrypt report before sending by email
- Check tripwire puppet errors when deploying
- Check psad Puppet module for iptables/ip6tables default logging rule (http://www.cipherdyne.org/psad/docs/fwconfig.html)
- Verify puppet modules & improve them if necessary 

## Licence

MIT
