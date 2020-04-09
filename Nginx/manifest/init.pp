class nginx(
  $upstreams_plain='',
  $upstreams={},
  $upstreams_ip_hash={},
  $upstream_max_fails='',
  $upstream_fail_timeout='',
  $keepalive=false,
  $worker_processes=1,
  $worker_rlimit_nofile=2000,
  $worker_connections=2000,
  $timer_resolution='',
  $gzip=false,
  $ssl=false,
  $ssi=false,
  $proxy_cache_path='',
  $maps_plain='',
  $resolver='',
  $custom='',
  $server_names_hash_bucket_size=128,
) {
  package { 'nginx': ensure => present }
  zabbix::metadata { 'nginx': }
  include zabbix::check_nginx

  service { 'nginx':
    enable     => true,
    ensure     => running,
    hasrestart => false,
    restart    => '/sbin/service nginx reload',
    require    => Package['nginx'],
  }

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['nginx'],
    before  => Service['nginx'],
  }

  file { ['/etc/nginx', '/etc/nginx/vhosts' ]: ensure => directory }

  file {
    '/etc/nginx/mime.types':
      source  => 'puppet:///modules/nginx/mime.types',
      notify  => Service['nginx'];
    '/etc/nginx/nginx.conf':
      content => template('nginx/nginx.conf.erb'),
      notify  => Service['nginx'];
  }
}
