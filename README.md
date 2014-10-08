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

- Encrypt report before sending by email
- Print summary of all parameters in report
- Verify puppet modules & improve them if necessary 

## Licence

MIT
