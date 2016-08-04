# Ceph all-in-one

Deploying single-node Ceph cluster with HTTP REST gateway for the RADOS object store.

By default, after installation RadosGW listens on port 8080.

## Deploy with Vagrant on local VirtualBox VM

```bash
$ git clone https://github.com/maxkochubey/ceph-aio.git /tmp/ceph-aio
$ cd /tmp/ceph-aio
$ # Now it's time to customize config "scripts/ceph-aio.conf"
$ vagrant up
```

## Deploy with Vagrant in OpenStack VM

```bash
$ git clone https://github.com/maxkochubey/ceph-aio.git /tmp/ceph-aio
$ cd /tmp/ceph-aio
$ # Now it's time to customize config "scripts/ceph-aio.conf"
$ vagrant plugin install vagrant-openstack-provider
$ # After vagrant plugin installation you have to edit "Vagrantfile" and \
  # write correct OpenStack credentials, networks, image, flavor, etc.
$ # Usually there's no "vagrant" user in regular Ubuntu Trusty OpenStack \
  # image, so we'll use "ubuntu" user from Ubuntu cloud image
$ username=ubuntu vagrant up --provider=openstack
```

## Deploy on already existing Ubuntu VM

```bash
$ git clone https://github.com/maxkochubey/ceph-aio.git /tmp/ceph-aio
$ cd /tmp/ceph-aio/scripts
$ # Now it's time to customize config ceph-aio.conf
$ # and just start script for ceph deploy
$ ./ceph-aio-deploy.sh
```
