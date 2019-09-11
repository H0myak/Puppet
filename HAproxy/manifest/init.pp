class haproxy (
  $redis          = false,
  $redis_node     = [],
  $redis_pass     = '',
  $redis_cluster  = '',
  $redis_listen   = '6379',
  ) {
  package {'haproxy':
    ensure => present }
  zabbix::metadata { 'haproxy': }
  service { ['haproxy']:
    ensure => running,
    enable   => true,
    require  => Package['haproxy'],
  }
  file {'/etc/haproxy/haproxy.cfg':
    ensure  => file,
    content => template('haproxy.cfg.erb'),
    require => Package['haproxy'],
    notify  => Service['haproxy'],
  }
}


class haproxy::new (
  $http          = true,
  $frontend      = [],
  $backend       = [],

  $redis_node     = [],
  $redis_pass     = '',
  $redis_cluster  = '',
  $redis_listen   = '6379',
  ) {
  package {'haproxy':
    ensure => present }
  zabbix::metadata { 'haproxy': }
  service { ['haproxy']:
    ensure => running,
    enable   => true,
    require  => Package['haproxy'],
  }
  file {'/etc/haproxy/haproxy_new.cfg':
    ensure  => file,
    content => template('haproxy.cfg.erb'),
    require => Package['haproxy'],
    notify  => Service['haproxy'],
  }
}
