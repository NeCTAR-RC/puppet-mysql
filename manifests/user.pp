define mysql::user (
  $user,
  $password,
  $database,
  $grant='read-only',
  $access='localhost') {

  case $grant {
    'read-only': {
      $mysql_grant = 'SELECT'
    }
    'read-write': {
      $mysql_grant = 'ALL'
    }
  }

  exec { "create-mysql-${name}-user":
    command => "mysql -u root -p${mysql_root_password} -e \"CREATE USER '${user}'@'localhost' IDENTIFIED BY '${password}'; GRANT ${mysql_grant} PRIVILEGES ON ${database}.* TO '${user}'@'localhost';\"",
    path    => '/bin:/usr/bin',
    unless  => "mysql -u${user} -p${password} ${database}",
    require => Service['mysql'],
  }

  if $access != 'localhost' {
    exec { "create-mysql-${name}-user-remote":
      command => "mysql -u root -p${mysql_root_password} -e \"CREATE USER '${user}'@'${access}' IDENTIFIED BY '${password}'; GRANT ${mysql_grant} PRIVILEGES ON ${database}.* TO '${user}'@'${access}';\"",
      path    => '/bin:/usr/bin',
      unless  => "mysql -u${user} -p${password} -h ${ipaddress} ${database}",
      require => Service['mysql'],
    }
  }
}
