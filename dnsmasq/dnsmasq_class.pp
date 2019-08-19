class dnsmasq {

$domain = 'priv'
$resolve_server = '8.8.8.8'
$patch_to_zoneList = '/etc/dnsmasq.d/priv.zone'
$listen_address = '127.0.0.1'



   package { 'dnsmasq': ensure => installed }

   service { 'dnsmasq': ensure => running,
             enable => true,
             require => Package['dnsmasq'], }

  file { "/etc/dnsmasq.conf":
      notify  => Service['dnsmasq'],
      content => template('/etc/puppet/modules/chrony/files/dnsmasq.conf'),
      require => Package['dnsmasq'],
   }

  file { "/etc/dnsmasq.d/priv.zone":
      notify  => Service['dnsmasq'],
      content => template('/etc/puppet/modules/chrony/files/zone.list'),
      require => Package['dnsmasq'],
   }

}
