class mysql::slave {

  file { '/etc/mysql/conf.d/replication.cnf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => 'puppet:///modules/mysql/slave-replication.cnf',
    notify  => Service['mysql'],
    require => Package['mysql-server'],
  }
  
}
