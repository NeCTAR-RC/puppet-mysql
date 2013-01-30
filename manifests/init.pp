class mysql {

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

  nagios::nrpe::service {
    'check_mysqld':
      check_command  => '/usr/lib/nagios/plugins/check_mysql',
      servicegroups  => 'databases';
    }

  define mysqldb( $user, $password, $access='localhost' ) {
    exec { "create-${name}-db":
      command => "mysql -u root -p${mysql_root_password} -e \"CREATE DATABASE ${name};\"",
      creates => "/var/lib/mysql/${name}/",
      path    => "/bin:/usr/bin",
      require => Service["mysql"],
    }

    exec { "create-mysql-${name}-user":
      command => "mysql -u root -p${mysql_root_password} -e \"CREATE USER '${user}'@'localhost' IDENTIFIED BY '${password}'; GRANT ALL PRIVILEGES ON ${name}.* TO '${user}'@'localhost';\"",
      path    => "/bin:/usr/bin",
      unless  => "mysql -u${user} -p${password} ${name}",
      require => Service["mysql"],
    }
    if $access == 'localhost' {

    }
    else {
      exec { "create-mysql-${name}-user-remote":
        command => "mysql -u root -p${mysql_root_password} -e \"CREATE USER '${user}'@'${access}' IDENTIFIED BY '${password}'; GRANT ALL PRIVILEGES ON ${name}.* TO '${user}'@'${access}';\"",
        path    => "/bin:/usr/bin",
        unless  => "mysql -u${user} -p${password} -h ${ipaddress} ${name}",
        require => Service["mysql"],
      }
    }
  }
}
