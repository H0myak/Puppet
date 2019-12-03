class lxd {
  include yum::lxd
  package { ['lxc','lxcfs','lxc-libs','lxc-templates','lxd']:
    ensure => installed,
  }
  service { 'lxd':
    ensure   => running,
    require  => Package['lxd'],
    enable   => true,
  }
}

define lxd::create(
  $container  = $name,
  $storage    = "default",
  $size       = '',
  $profile    = '',
  $hostname   = '',
  $ipaddr     = '',
  $iface      = '',
  $prefix     = '24',
  $mtu        = '1500',
  $gateway    = '',
  $dns1       = '',
  $dns2       = '',
  $memory     = '',
  $bootproto  = 'none',
  $onboot     = 'yes',
  $privileged = false,
  $file_lim   = '',
  $ifcfg      = '/etc/sysconfig/network-scripts/ifcfg',
  $if_reload  = "ifdown $iface; ifup $iface",
) {
  Exec { path => '/usr/bin:/usr/sbin:/bin' }
  exec { "create LXD container $container":
    command => "lxc launch images:centos/7/amd64 $container -s $storage; sleep 10",
    unless  => "lxc ls | grep $container",
  }
  if $size != '' {
    exec { "set size in $container":
    command => "lxc config device set $container root size=$size",
    unless  => "lxc config show $container | grep \"size: $size\"",
    require => Exec["create LXD container $container"],
    }
  }
  if $profile != '' {
    exec { "add profile in $container":
    command => "lxc profile assign $container $profile",
    unless  => "lxc config show $container | grep \"$profile\"",
    require => Exec["create LXD container $container"],
    }
  }
  if $hostname != '' {
    exec { "set hostname in $container":
    command => "lxc exec $container -- sh -c \"hostname $hostname\"; lxc exec $container -- sh -c \"hostnamectl set-hostname $hostname \"",
    unless  => "lxc exec $container -- \"hostname\" | grep \"$hostname\"",
    require => Exec["create LXD container $container"],
    }
  }
  file { "interface template $container":
    path    => "/var/lib/lxd/networks/if_template_$container",
    content => template('lxd/if_template.erb'),
    require => Exec["create LXD container $container"],
  }
  if $iface != '' {
    exec { "config iface in $container":
    command   => "lxc file push /var/lib/lxd/networks/if_template_$container $container$ifcfg-$iface",
    subscribe => File["/var/lib/lxd/networks/if_template_$container"],
    refreshonly => true,
    }
  }
  if $privileged == true {
    exec { "set priv mode on $container":
    command => "lxc config set $container security.privileged true",
    unless  => "lxc config show $container | grep \"security.privileged\"",
    require => Exec["create LXD container $container"],
    }
  }
  if $file_lim != '' {
    exec { "set limits.kernel.nofile on $container":
    command => "lxc config set $container limits.kernel.nofile $file_lim",
    unless  => "lxc config show $container | grep \"limits.kernel.nofile:.*$file_lim\"",
    require => Exec["create LXD container $container"],
    }
  }
  if $memory != '' {
    exec { "set memory limit in $container":
    command => "lxc config set $container limits.memory $memory",
    unless  => "lxc config show $container | grep \"limits.memory: $memory\"",
    require => Exec["create LXD container $container"],
    }
  }
}

define lxd::remove ($container=$name) {
  exec { "remove container $container":
  command => "/var/lib/snapd/snap/bin/lxc delete $container -f",
  provider => shell,
  onlyif => "/usr/bin/lxc ls | grep $container",
  }
}
