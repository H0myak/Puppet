define opendkim::key (
  $selector='default'
  ) {
  File {
    owner   => 'opendkim',
    group   => 'opendkim',
    mode    => '0640',
    require => Package['opendkim'],
    before  => Service['opendkim'],
  }

  file {
    "/etc/opendkim/keys/${name}":
      ensure => directory;
    "/etc/opendkim/keys/${name}/${selector}":
      source => "puppet:///modules/opendkim/keys/dkimkey.${name}.${selector}.key",
      notify => Service['opendkim'];
  }
}
