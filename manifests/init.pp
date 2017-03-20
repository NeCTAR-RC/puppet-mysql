class mysql($local_backup=false) {

  package { 'mysql-server':
    ensure => installed,
  }

  service { 'mysql':
    ensure  => running,
    require => Package[mysql-server],
  }

  exec { 'set-mysql-root-password':
    unless => "mysqladmin -uroot -p${mysql_root_password} status",
    path => ['/bin', '/usr/bin'],
    command => "mysqladmin -uroot password ${mysql_root_password}",
    require => Service['mysql'],
  }

  file { '/etc/mysql/my.cnf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("mysql/my.cnf-${lsbdistcodename}.erb"),
    notify  => Service['mysql'],
    require => Package['mysql-server'],
  }

  if $local_backup {
    $backup_ensure = present
  } else {
    $backup_ensure = absent
  }
  
  file { '/usr/local/sbin/backup-mysql.sh':
    ensure => $backup_ensure,
    owner  => root,
    group  => root,
    mode   => '0750',
    source => 'puppet:///modules/mysql/backup-mysql.sh'
  }

  cron { backup-mysql:
    ensure  => $backup_ensure,
    command => '/usr/local/sbin/backup-mysql.sh',
    user    => root,
    hour    => '4',
    minute  => '0',
    require => File['/usr/local/sbin/backup-mysql.sh'],
  }

  nagios::nrpe::service {
    'check_mysqld':
      check_command  => '/usr/lib/nagios/plugins/check_mysql',
      servicegroups => 'databases',
    }

  define mysqldb( $user, $password, $access='localhost' ) {
    exec { "create-${name}-db":
      command => "mysql -u root -p${mysql_root_password} -e \"CREATE DATABASE ${name};\"",
      creates => "/var/lib/mysql/${name}/",
      path    => "/bin:/usr/bin",
      require => Service["mysql"],
    }

    mysql::user { $user:
      user     => $user,
      password => $password,
      database => $name,
      grant    => 'read-write',
      access   => $access,
    }
  }
}
