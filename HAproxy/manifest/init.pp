class haproxy (
  $http_back     = 'true',
  $frontend      = [],
  $server        = [],
  ) {
  package {'haproxy':
    ensure => present }
  service { ['haproxy']:
    ensure => running,
    enable   => true'
    require  => Package['haproxy'],
  }
  file {'/etc/haproxy/haproxy.cfg':
    ensure  => file,
    content => template('/etc/puppetlabs/puppet/haproxy.cfg.erb'),
    require => Package['haproxy'],
    notify  => Service['haproxy'],
  }
}

/*
README:
---
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
