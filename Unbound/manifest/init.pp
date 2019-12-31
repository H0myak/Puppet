class unbound (
  $listening      = '',
  $allow_networks = '',
  $stubs          = '',
  $forwards       = '',
  $custom         = '',
){
  package {'unbound':
    ensure => present }
  service { ['unbound']:
    ensure => running,
    enable   => 'true',
    require  => Package['unbound'],
  }
  file {'/etc/unbound/unbound.conf':
    ensure  => file,
    content => template('unbound/unbound.conf.erb'),
    require => Package['unbound'],
    notify  => Service['unbound'],
  }
}

#EXAMPLES
#---------

# class { 'unbound':
#   allow_networks => hiera('varaibles::allow_networks')
# }
