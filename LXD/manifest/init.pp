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
  exec { "lxc launch images:centos/7/amd64 $container -s $storage; sleep 10":
    path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
    unless => "lxc ls | grep $container",
  }
  if $size != '' {
    exec { "lxc config device set $container root size=$size":
      path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
      unless => "lxc config show $container | grep \"size: $size\"",
      require => Exec["lxc launch images:centos/7/amd64 $container -s $storage; sleep 10"],
    }
  }
  if $profile != '' {
    exec { "lxc profile assign $container $profile":
      path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
      unless => "lxc config show $container | grep \"$profile\"",
      require => Exec["lxc launch images:centos/7/amd64 $container -s $storage; sleep 10"],
    }
  }
  if $hostname != '' {
    exec { "lxc exec $container -- sh -c \"hostname $hostname\"; lxc exec $container -- sh -c \"echo $hostname > /etc/hostname\"":
      path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
      unless => "lxc exec $container -- \"hostname\" | grep \"$hostname\"",
      require => Exec["lxc launch images:centos/7/amd64 $container -s $storage; sleep 10"],
    }
  }
  if $ipaddr != '' {
    exec { "lxc exec $container -- sh -c \echo -e '# Managed by puppet\nDEVICE=$iface\nBOOTPROTO=none\nONBOOT=yes\nTYPE=Ethernet\nIPADDR=$ipaddr\nPREFIX=$prefix\nMTU=$mtu' > $ifcfg-$iface; $if_reload\"":
      path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
      unless => ["lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"$ipaddr\""],
      require => Exec["lxc launch images:centos/7/amd64 $container -s $storage; sleep 10"],
    }
  }
  if $gateway != '' {
    exec { "lxc exec $container -- sh -c \"sed '/GATEWAY=/d' -i $ifcfg-$iface; echo -e 'GATEWAY=$gateway' >> $ifcfg-$iface; $if_reload\"":
      path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
      unless => "lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"$gateway\"",
      require => Exec["lxc exec $container -- sh -c \echo -e '# Managed by puppet\nDEVICE=$iface\nBOOTPROTO=none\nONBOOT=yes\nTYPE=Ethernet\nIPADDR=$ipaddr\nPREFIX=$prefix\nMTU=$mtu' > $ifcfg-$iface; $if_reload\""],
    }
  }
  if $dns1 != '' {
    exec { "lxc exec $container -- sh -c \"sed '/DNS1=/d' -i $ifcfg-$iface; echo -e 'DNS1=$dns1' >> $ifcfg-$iface; $if_reload\"":
      path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
      unless => "lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"$dns1\"",
      require => Exec["lxc exec $container -- sh -c \echo -e '# Managed by puppet\nDEVICE=$iface\nBOOTPROTO=none\nONBOOT=yes\nTYPE=Ethernet\nIPADDR=$ipaddr\nPREFIX=$prefix\nMTU=$mtu' > $ifcfg-$iface; $if_reload\""],
    }
  }
  if $dns2 != '' {
    exec { "lxc exec $container -- sh -c \"sed '/DNS2=/d' -i $ifcfg-$iface; echo -e 'DNS1=$dns2' >> $ifcfg-$iface; $if_reload\"":
      path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
      unless => "lxc exec $container -- sh -c \"cat $ifcfg-$iface\" | grep \"$dns2\"",
      require => Exec["lxc exec $container -- sh -c \echo -e '# Managed by puppet\nDEVICE=$iface\nBOOTPROTO=none\nONBOOT=yes\nTYPE=Ethernet\nIPADDR=$ipaddr\nPREFIX=$prefix\nMTU=$mtu' > $ifcfg-$iface; $if_reload\""],
    }
  }
  if $memory != '' {
    exec { "lxc config device set $container limits.memory $memory":
      path   => '/usr/bin:/usr/sbin:/bin:/var/lib/snapd/snap/bin',
      unless => "lxc config show $container | grep \"limits.memory: $memory\"",
      require => Exec["lxc launch images:centos/7/amd64 $container -s $storage; sleep 10"],
    }
  }
}

define lxd::remove ($container=$name) {
  exec { "/var/lib/snapd/snap/bin/lxc delete $container -f":
    provider => shell,
    onlyif   => "/var/lib/snapd/snap/bin/lxc ls | grep $container",
  }
}
