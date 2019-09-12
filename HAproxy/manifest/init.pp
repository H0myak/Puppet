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
  $server        = [],
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

/*
# Example of use this class
#  P.S. frontend hash used to backend generate

frontend => [{ name       => 'frontend name',
               mode       => 'http or tcp',
               address    => 'bind address',
               port       => 'bind port',
               acl_name   => 'use this key if you nead acl',
               acl_rule   => 'example: hdr(host) -i www.domain.com',
               check      => 'backend checks' }]
server   => [{ front      => 'used frontend',
               servername => 'backend name',
               ip         => 'backend ip',
               port       => 'backend port',
               maxconn    => 'maximum of connections',
               time_check => 'backend check timeout' }]
*/
