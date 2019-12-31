class opendkim (
$PidFile             = '/var/run/opendkim/opendkim.pid',
$Mode                = 'sv',
$Syslog              = 'yes',
$SyslogSuccess       = 'yes',
$LogWhy              = 'yes',
$UserID              = 'opendkim:postfix',
$Socket              = 'local:/var/run/opendkim/opendkim.sock',
$UMask               = '000',
$SendReports         = 'no',
$SoftwareHeader      = 'yes',
$Canonicalization    = 'relaxed/simple',
$MinimumKeyBits      = '2048',
$OversignHeaders     = 'From',
$SigningTable        = 'refile:/etc/opendkim/SigningTable',
$ExternalIgnoreList  = 'refile:/etc/opendkim/TrustedHosts',
$KeyTable            = 'refile:/etc/opendkim/KeyTable',
$InternalHosts       = 'refile:/etc/opendkim/TrustedHosts',
$main_custom         = '',
$domain              = [],
$TrustedHosts        = [],
  ) {
  package {'opendkim':
    ensure => present }
  service { ['opendkim']:
    ensure => running,
    enable   => 'true',
    require  => Package['opendkim','postfix'],
  }
  file {'/etc/opendkim/keys':
    ensure  => directory,
    owner   => 'opendkim',
    group   => 'opendkim',
    mode    => '0640',
  }
  file {
    '/etc/opendkim.conf': content => template('opendkim/opendkim.conf.erb'),
      require => Package['opendkim'], notify  => Service['opendkim'];
    '/etc/KeyTable':      content => template('opendkim/KeyTable.erb'),
      require => Package['opendkim'], notify  => Service['opendkim'];
    '/etc/SigningTable':  content => template('opendkim/SigningTable.erb'),
      require => Package['opendkim'], notify  => Service['opendkim'];
    '/etc/TrustedHosts':  content => template('opendkim/TrustedHosts.erb'),
      require => Package['opendkim'], notify  => Service['opendkim'];
  }
  create_resources(opendkim::key, $keys)
}
