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

- Better report
    - Better spaces
    - Show "OK" for each sections
    - Disable gem install output
    - Print summary of all parameters
- Encrypt report before sending by email
- Check psad Puppet module for iptables/ip6tables default logging rule (http://www.cipherdyne.org/psad/docs/fwconfig.html)
- Verify puppet modules & improve them if necessary 

## Licence

MIT
