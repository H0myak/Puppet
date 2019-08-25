define lxd::create (
  $container=$name,
  $storage=default) {
  exec { "/var/lib/snapd/snap/bin/lxc launch images:centos/7/amd64 $container \
-s $storage \
--config=user.network-config=\"$(cat /etc/puppetlabs/puppet/net.erb)\"":
    path   => '/usr/bin:/usr/sbin:/bin',
    unless => "/var/lib/snapd/snap/bin/lxc ls | grep $container",
  }
}

define lxd::remove ($container=$name) {
  exec { "/var/lib/snapd/snap/bin/lxc delete $container -f":
    provider => shell,
    onlyif   => "/var/lib/snapd/snap/bin/lxc ls | grep $container",
  }
}

lxd::remove { 'test1': }
lxd::create { 'test2S':
     storage => 'default', }
