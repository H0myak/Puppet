class ceph (
  $ceph_release = 'nautilus',
  $ceph_version = '14.2.8-0.el7',
  $ceph_node    = true,
  $ceph_deploy  = false,
  $hw_node      = false,

){
  class {'yum::ceph': ceph_release => $ceph_release }
  if $ceph_node {
    package { ['python-ceph-argparse', 'ceph-mgr', 'ceph', 'libcephfs2',
               'python-cephfs', 'ceph-common', 'ceph-selinux', 'ceph-osd',
               'ceph-mds', 'ceph-radosgw', 'ceph-base', 'ceph-mon']:
    ensure => $ceph_version,
    require => Class['yum::ceph'],
  }
  if $ceph_deploy {
    package { ['ceph-deploy']:
    require => Class['yum::ceph'],
  }
  if $hw_node {
    package { ['ceph-common']:
    ensure => $ceph_version,
    require => Class['yum::ceph'],
  }
}
