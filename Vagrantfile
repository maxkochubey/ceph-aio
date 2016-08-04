VAGRANTFILE_API_VERSION = '2'
VMNAME = 'ceph-aio'

require 'vagrant-openstack-provider'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.ssh.username = 'vagrant'

  if ENV['username'] != 'vagrant'
    config.ssh.username = ENV['username']
  end

  config.vm.box = 'ubuntu/trusty64'
  config.vm.network 'forwarded_port', guest: 8080, host: 8080
  config.vm.define VMNAME
  config.vm.hostname = VMNAME

  config.vm.provider "virtualbox"
  config.vm.provider "openstack"

  config.vm.provider 'virtualbox' do |vb|
    vb.memory = 4096
    vb.cpus = 2
  end

  config.vm.provider 'openstack' do |os|
    meta_args_support     = true
    os.openstack_auth_url = 'http://openstack.test:5000/v2.0/tokens'
    os.username           = 'e.snowden'
    os.password           = 'FilteredPassword'
    os.tenant_name        = 'QA Tenant'
    os.flavor             = 'm1.medium'
    os.availability_zone  = 'nova'
    os.image              = 'Ubuntu 14.04 amd64'
    os.floating_ip_pool   = 'vlan-net'
    os.networks = [
      {
        id: '0059e361-c1e1-4cbb-936e-b1ed41903156'
      }
    ]
  end

  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.provision "shell", inline: "chmod +x /vagrant/scripts/*.sh && /vagrant/scripts/ceph-aio-deploy.sh"
end
