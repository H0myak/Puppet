class s3fs (
  $key    = '',
  $secret = '',
  $bucket = '',
  $folder = '/backup',
  $passw  = '/root/.s3fs-pass',
  $cron   = '',
){
  if $::operatingsystemrelease <= '6' {
  }
  package { 's3fs-fuse': ensure => installed }
  $password = inline_template('<%= @key %>:<%= @secret %>')
  file { "$folder":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    require => Package['s3fs-fuse'],
  } ->
  file { "$passw":
    ensure   => 'present',
    owner    => 'root',
    group    => 'root',
    mode     => '0600',
    content  => $password
  } ->
  exec { 'mount backup dir':
    command => "s3fs $bucket $folder -o passwd_file=$passw"
  }
  class { 's3fs::backup':
    folder => $folder,
    passw  => $passw,
    cron   => true,
    bucket => $bucket,
  }
}

class s3fs::backup (
  $folder = '',
  $passw  = '',
  $cron   = true,
  $bucket = '',
){
  file { "/usr/local/sbin/mk_backup":
    ensure   => 'present',
    owner    => 'root',
    group    => 'root',
    mode     => '0744',
    content  => template('s3fs/backup.erb')
  }
  if $cron {
    cron { 'Backup system':
      command => 'sleep $(( ( RANDOM % 3600 ) )) && sh /usr/local/sbin/mk_backup',
      user    => 'root',
      weekday => ['2','4','6'],
      hour    => '04',
      minute  => '01',
    }
  }
}
#bzip2
