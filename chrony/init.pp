class chrony (
  $ntp_srv1 = '0.pool.ntp.org',
  $ntp_srv2 = '1.pool.ntp.org'
 ){
  package { ['ntp', 'ntpdate']: ensure => 'absent', }
  package { 'chrony': ensure => installed }
  service { 'chronyd': ensure => running,
    enable   => true,
    require  => Package['chrony'], }
  service { 'chrony-wait': ensure => running,
    enable   => true,
    require  => Package['chrony'], }
  file { "/etc/chrony.conf":
    notify   => Service['chronyd'],
    content  => template('chrony/chrony.erb'),
    owner    => root,
    group    => root,
    mode     => 644,
    require  => Package['chrony'],
  }
}
