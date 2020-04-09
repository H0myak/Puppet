class maxscale (
  $all_servers,
  $ensure = 'running',
  $write_servers           = [],
  $maxscale_mysql_user     = 'maxscale',
  $maxscale_mysql_password = undef,
  $secret,
  $maxscale_admin_user     = undef,
  $maxscale_admin_password = undef,
  $failover                = false,
  $failover_user           = undef,
  $failover_pass           = undef
) {
  include yum::maxscale
  package { 'maxscale': ensure => present }

  service { 'maxscale':
    enable     => true,
    ensure     => $ensure,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['maxscale'],
  }

  file { '/etc/maxscale.cnf':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    content => template('maxscale/maxscale.cnf.erb'),
    notify => Service['maxscale'],
  }

  file { '/var/lib/maxscale/.secrets':
    owner  => 'maxscale',
    group  => 'maxscale',
    mode   => '0400',
    content => "${secret}",
    require    => Package['maxscale'],
  }

  if $failover {
    file { '/usr/local/sbin/failover.sh':
      owner   => 'maxscale',
      group   => 'maxscale',
      mode    => '0750',
      content => template('maxscale/failover.sh.erb'),
      require => Package['maxscale'],
    }

    exec { 'enable maxscale user':
      unless   => '/usr/bin/maxadmin show users | grep Enabled | grep -q maxscale',
      command  => '/usr/bin/maxadmin enable account maxscale',
    }
    exec { 'enable zabbix user':
      unless   => '/usr/bin/maxadmin show users | grep Enabled | grep -q zabbix',
      command  => '/usr/bin/maxadmin enable account zabbix',
    }
    exec { 'enable mysql user':
      unless   => '/usr/bin/maxadmin show users | grep Enabled | grep -q mysql',
      command  => '/usr/bin/maxadmin enable account mysql',
    }
  }
}
