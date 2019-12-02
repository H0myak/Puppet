class lxd {
  package { ['lxc','lxcfs','lxc-libs','lxc-templates','lxd']:
  ensure => installed,
  }
}

define lxd::create(
  $container = $name,
  $storage   = "default",
  $size      = '',
  $profile   = '',
  $hostname  = '',
  $ipaddr    = '',
  $iface     = '',
  $prefix    = '24',
  $mtu       = '1500',
  $gateway   = '',
  $dns1      = '',
  $dns2      = '',
  $memory    = '',
  $ifcfg     = '/etc/sysconfig/network-scripts/ifcfg',
  $if_reload = "ifdown $iface; ifup $iface",
) {
  exec { "create LXD container $container":
    command => "lxc launch images:centos/7/amd64 $container -s $storage; sleep 10",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc ls | grep $container",
  }
  if $size != '' {
    exec { "set size in $container":
    command => "lxc config device set $container root size=$size",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc config show $container | grep \"size: $size\"",
    require => Exec["create LXD container $container"],
    }
  }
  if $profile != '' {
    exec { "add profile in $container":
    command => "lxc profile assign $container $profile",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc config show $container | grep \"$profile\"",
    require => Exec["create LXD container $container"],
    }
  }
  if $hostname != '' {
    exec { "set hostname in $container":
    command => "lxc exec $container -- sh -c \"hostname $hostname\"; lxc exec $container -- sh -c \"hostnamectl set-hostname $hostname \"",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc exec $container -- \"hostname\" | grep \"$hostname\"",
    require => Exec["create LXD container $container"],
    }
  }
  if $ipaddr != '' {
    exec { "interface base config in $container":
    command => "lxc exec $container -- sh -c \"echo -e '# Managed by puppet\nDEVICE=$iface\nBOOTPROTO=none\nONBOOT=yes\nTYPE=Ethernet\nIPADDR=$ipaddr' > $ifcfg-$iface; $if_reload\"",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => ["lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"$ipaddr\""],
    require => Exec["create LXD container $container"],
    }
  }
  exec { "set network mask in $container":
    command => "lxc exec $container -- sh -c \"sed '/PREFIX=/d' -i $ifcfg-$iface; echo -e 'PREFIX=$prefix' >> $ifcfg-$iface; $if_reload\"",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"PREFIX=$prefix\"",
    require => Exec["interface base config in $container"],
  }
  if $mtu != '' and $ipaddr != '' {
    exec { "set MTU in $container":
    command => "lxc exec $container -- sh -c \"sed '/MTU=/d' -i $ifcfg-$iface; echo -e 'MTU=$mtu' >> $ifcfg-$iface; $if_reload\"",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"MTU=$mtu\"",
    require => Exec["interface base config in $container"],
    }
  }
  if $gateway != '' {
    exec { "set gateway in $container":
    command => "lxc exec $container -- sh -c \"sed '/GATEWAY=/d' -i $ifcfg-$iface; echo -e 'GATEWAY=$gateway' >> $ifcfg-$iface; $if_reload\"",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"$gateway\"",
    require => Exec["interface base config in $container"],
    }
  }
  if $dns1 != '' {
    exec { "set DNS1 in $container":
    command => "lxc exec $container -- sh -c \"sed '/DNS1=/d' -i $ifcfg-$iface; echo -e 'DNS1=$dns1' >> $ifcfg-$iface; $if_reload\"",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"$dns1\"",
    require => Exec["interface base config in $container"],
    }
  }
  if $dns2 != '' {
    exec { "set DNS2 in $container":
    command => "lxc exec $container -- sh -c \"sed '/DNS2=/d' -i $ifcfg-$iface; echo -e 'DNS1=$dns2' >> $ifcfg-$iface; $if_reload\"",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"$dns2\"",
    require => Exec["interface base config in $container"],
    }
  }
  if $memory != '' {
    exec { "set memory limit in $container":
    command => "lxc config set $container limits.memory $memory",
    path    => '/usr/bin:/usr/sbin:/bin',
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
