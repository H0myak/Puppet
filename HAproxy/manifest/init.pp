class haproxy (
  $http_back      = 'true',
  $frontend       = [],
  $server         = [],
  $def_mode       = 'http',
  $def_maxconn    = '4000',
  $def_tm_connect = '5000',
  $def_tm_client  = '50000',
  $def_tm_server  = '50000',
  $def_retries    = '3',
  $def_backend    = 'default_srv 127.0.0.1:666',
  $gl_log         = '127.0.0.1 local2',
  $gl_user        = 'haproxy',
  $gl_group       = 'haproxy',
  $gl_custom      = '',
  $def_custom     = '',
  $http_back_custom = '',
  ) {
  package {'haproxy':
    ensure => present }
  service { ['haproxy']:
    ensure => running,
    enable   => 'true',
    require  => Package['haproxy'],
  }
  file {'/etc/haproxy/haproxy_new.cfg':
    ensure  => file,
    content => template('haproxy/haproxy_new.cfg.erb'),
    require => Package['haproxy'],
#    notify  => Service['haproxy'],
  }
}

/*
http_back - (true/false) -- enable options for web backend
frontend  - (hash key)   -- variables for generate frontend and backend blocks
server    - (hash key)   -- variables for backend servers

EXAMPLE:
---
frontend      => [{
  name        => 'http',
  acl_name    => 'test_acl_name',             # optional
  mode        => 'http',
  address     => '0.0.0.0',
  port        => '80',
  acl_rule    => 'path -i -m beg /static',    # optional
  check       => 'option tcp-check',          # optional
  },
server        => [{
  front       => 'test_acl_name',
  servername  => 'nameserver',
  ip          => '127.0.0.1',
  port        => '8080',
  maxconn     => '4096',                      # optional
  time_check  => '2s',                        # optional
  }]
*/
