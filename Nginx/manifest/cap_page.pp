class cap_page (
  $port     = '80',
  $ssl_port = '443',
  $ssl      = 'false', ){
  file { '/etc/nginx/vhost/cap_page.conf':
    content => template('nginx/cap_page.conf.erb'),
    notify  => Service['nginx'];
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    before  => Service['nginx'],
  }
  if $ssl == 'true' {
    pki::nginx::cert { "cap_page": notify => Service["nginx"] }
  }
}
