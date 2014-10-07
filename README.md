First, install dependencies with http://librarian-puppet.com/

```
sudo apt-get update
sudo apt-get upgrade

sudo apt-get install build-essential
sudo apt-get install ruby-dev

sudo apt-get install git
sudo apt-get install puppet

gem install librarian-puppet

cd /etc/puppet

librarian-puppet install

puppet apply manifests/site.pp
```