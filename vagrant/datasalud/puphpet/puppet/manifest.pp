## Begin Server manifest

if $server_values == undef {
  $server_values = hiera('server', false)
}

# Ensure the time is accurate, reducing the possibilities of apt repositories
# failing for invalid certificates
include '::ntp'

Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }
group { 'puppet':   ensure => present }
group { 'www-data': ensure => present }

user { $::ssh_username:
  shell  => '/bin/bash',
  home   => "/home/${::ssh_username}",
  ensure => present
}

user { ['apache', 'nginx', 'httpd', 'www-data']:
  shell  => '/bin/bash',
  ensure => present,
  groups => 'www-data',
  require => Group['www-data']
}

file { "/home/${::ssh_username}":
    ensure => directory,
    owner  => $::ssh_username,
}

# copy dot files to ssh user's home directory
exec { 'dotfiles':
  cwd     => "/home/${::ssh_username}",
  command => "cp -r /vagrant/puphpet/files/dot/.[a-zA-Z0-9]* /home/${::ssh_username}/ \
              && chown -R ${::ssh_username} /home/${::ssh_username}/.[a-zA-Z0-9]* \
              && cp -r /vagrant/puphpet/files/dot/.[a-zA-Z0-9]* /root/",
  onlyif  => 'test -d /vagrant/puphpet/files/dot',
  returns => [0, 1],
  require => User[$::ssh_username]
}

case $::osfamily {
  # debian, ubuntu
  'debian': {
    class { 'apt': }

    Class['::apt::update'] -> Package <|
        title != 'python-software-properties'
    and title != 'software-properties-common'
    |>

    ensure_packages( ['augeas-tools'] )
  }
  # redhat, centos
  'redhat': {
    class { 'yum': extrarepo => ['epel'] }

    class { 'yum::repo::rpmforge': }
    class { 'yum::repo::repoforgeextras': }

    Class['::yum'] -> Yum::Managed_yumrepo <| |> -> Package <| |>

    if defined(Package['git']) == false {
      package { 'git':
        ensure  => latest,
        require => Class['yum::repo::repoforgeextras']
      }
    }

    exec { 'bash_git':
      cwd     => "/home/${::ssh_username}",
      command => "curl https://raw.github.com/git/git/master/contrib/completion/git-prompt.sh > /home/${::ssh_username}/.bash_git",
      creates => "/home/${::ssh_username}/.bash_git"
    }

    exec { 'bash_git for root':
      cwd     => '/root',
      command => "cp /home/${::ssh_username}/.bash_git /root/.bash_git",
      creates => '/root/.bash_git',
      require => Exec['bash_git']
    }

    file_line { 'link ~/.bash_git':
      ensure  => present,
      line    => 'if [ -f ~/.bash_git ] ; then source ~/.bash_git; fi',
      path    => "/home/${::ssh_username}/.bash_profile",
      require => [
        Exec['dotfiles'],
        Exec['bash_git'],
      ]
    }

    file_line { 'link ~/.bash_git for root':
      ensure  => present,
      line    => 'if [ -f ~/.bash_git ] ; then source ~/.bash_git; fi',
      path    => '/root/.bashrc',
      require => [
        Exec['dotfiles'],
        Exec['bash_git'],
      ]
    }

    file_line { 'link ~/.bash_aliases':
      ensure  => present,
      line    => 'if [ -f ~/.bash_aliases ] ; then source ~/.bash_aliases; fi',
      path    => "/home/${::ssh_username}/.bash_profile",
      require => File_line['link ~/.bash_git']
    }

    file_line { 'link ~/.bash_aliases for root':
      ensure  => present,
      line    => 'if [ -f ~/.bash_aliases ] ; then source ~/.bash_aliases; fi',
      path    => '/root/.bashrc',
      require => File_line['link ~/.bash_git for root']
    }

    ensure_packages( ['augeas'] )
  }
}

if $php_values == undef {
  $php_values = hiera('php', false)
}

case $::operatingsystem {
  'debian': {
    include apt::backports

    add_dotdeb { 'packages.dotdeb.org': release => $lsbdistcodename }

   if hash_key_equals($php_values, 'install', 1) {
      # Debian Squeeze 6.0 can do PHP 5.3 (default) and 5.4
      if $lsbdistcodename == 'squeeze' and $php_values['version'] == '54' {
        add_dotdeb { 'packages.dotdeb.org-php54': release => 'squeeze-php54' }
      }
      # Debian Wheezy 7.0 can do PHP 5.4 (default) and 5.5
      elsif $lsbdistcodename == 'wheezy' and $php_values['version'] == '55' {
        add_dotdeb { 'packages.dotdeb.org-php55': release => 'wheezy-php55' }
      }
    }

    $server_lsbdistcodename = downcase($lsbdistcodename)

    apt::force { 'git':
      release => "${server_lsbdistcodename}-backports",
      timeout => 60
    }
  }
  'ubuntu': {
    apt::key { '4F4EA0AAE5267A6C':
      key_server => 'hkp://keyserver.ubuntu.com:80'
    }
    apt::key { '4CBEDD5A':
      key_server => 'hkp://keyserver.ubuntu.com:80'
    }

    apt::ppa { 'ppa:pdoes/ppa': require => Apt::Key['4CBEDD5A'] }

    if hash_key_equals($php_values, 'install', 1) {
      # Ubuntu Lucid 10.04, Precise 12.04, Quantal 12.10 and Raring 13.04 can do PHP 5.3 (default <= 12.10) and 5.4 (default <= 13.04)
      if $lsbdistcodename in ['lucid', 'precise', 'quantal', 'raring'] and $php_values['version'] == '54' {
        if $lsbdistcodename == 'lucid' {
          apt::ppa { 'ppa:ondrej/php5-oldstable': require => Apt::Key['4F4EA0AAE5267A6C'], options => '' }
        } else {
          apt::ppa { 'ppa:ondrej/php5-oldstable': require => Apt::Key['4F4EA0AAE5267A6C'] }
        }
      }
      # Ubuntu Precise 12.04, Quantal 12.10 and Raring 13.04 can do PHP 5.5
      elsif $lsbdistcodename in ['precise', 'quantal', 'raring'] and $php_values['version'] == '55' {
        apt::ppa { 'ppa:ondrej/php5': require => Apt::Key['4F4EA0AAE5267A6C'] }
      }
      elsif $lsbdistcodename in ['lucid'] and $php_values['version'] == '55' {
        err('You have chosen to install PHP 5.5 on Ubuntu 10.04 Lucid. This will probably not work!')
      }
    }
  }
  'redhat', 'centos': {
    if hash_key_equals($php_values, 'install', 1) {
      if $php_values['version'] == '54' {
        class { 'yum::repo::remi': }
      }
      # remi_php55 requires the remi repo as well
      elsif $php_values['version'] == '55' {
        class { 'yum::repo::remi': }
        class { 'yum::repo::remi_php55': }
      }
    }
  }
}

if !empty($server_values['packages']) {
  ensure_packages( $server_values['packages'] )
}

define add_dotdeb ($release){
   apt::source { $name:
    location          => 'http://packages.dotdeb.org',
    release           => $release,
    repos             => 'all',
    required_packages => 'debian-keyring debian-archive-keyring',
    key               => '89DF5277',
    key_server        => 'keys.gnupg.net',
    include_src       => true
  }
}

## Begin MailCatcher manifest

if $mailcatcher_values == undef {
  $mailcatcher_values = hiera('mailcatcher', false)
}

if hash_key_equals($mailcatcher_values, 'install', 1) {
  $mailcatcher_path       = $mailcatcher_values['settings']['path']
  $mailcatcher_smtp_ip    = $mailcatcher_values['settings']['smtp_ip']
  $mailcatcher_smtp_port  = $mailcatcher_values['settings']['smtp_port']
  $mailcatcher_http_ip    = $mailcatcher_values['settings']['http_ip']
  $mailcatcher_http_port  = $mailcatcher_values['settings']['http_port']
  $mailcatcher_log        = $mailcatcher_values['settings']['log']

  class { 'mailcatcher':
    mailcatcher_path => $mailcatcher_path,
    smtp_ip          => $mailcatcher_smtp_ip,
    smtp_port        => $mailcatcher_smtp_port,
    http_ip          => $mailcatcher_http_ip,
    http_port        => $mailcatcher_http_port,
  }

  if $::osfamily == 'redhat' and ! defined(Iptables::Allow["tcp/${mailcatcher_smtp_port}"]) {
    iptables::allow { "tcp/${mailcatcher_smtp_port}":
      port     => $mailcatcher_smtp_port,
      protocol => 'tcp'
    }
  }

  if $::osfamily == 'redhat' and ! defined(Iptables::Allow["tcp/${mailcatcher_http_port}"]) {
    iptables::allow { "tcp/${mailcatcher_http_port}":
      port     => $mailcatcher_http_port,
      protocol => 'tcp'
    }
  }

  if ! defined(Class['supervisord']) {
    class { 'supervisord':
      install_pip => true,
    }
  }

  $supervisord_mailcatcher_options = sort(join_keys_to_values({
    ' --smtp-ip'   => $mailcatcher_smtp_ip,
    ' --smtp-port' => $mailcatcher_smtp_port,
    ' --http-ip'   => $mailcatcher_http_ip,
    ' --http-port' => $mailcatcher_http_port
  }, ' '))

  $supervisord_mailcatcher_cmd = "mailcatcher ${supervisord_mailcatcher_options} -f  >> ${mailcatcher_log}"

  supervisord::program { 'mailcatcher':
    command     => $supervisord_mailcatcher_cmd,
    priority    => '100',
    user        => 'mailcatcher',
    autostart   => true,
    autorestart => true,
    environment => {
      'PATH' => "/bin:/sbin:/usr/bin:/usr/sbin:${mailcatcher_path}"
    },
    require => Package['mailcatcher']
  }
}

## Begin Nginx manifest

if $nginx_values == undef {
   $nginx_values = hiera('nginx', false)
} if $php_values == undef {
   $php_values = hiera('php', false)
} if $hhvm_values == undef {
  $hhvm_values = hiera('hhvm', false)
}

if hash_key_equals($apache_values, 'install', 1) {
  include puphpet::params

  if $lsbdistcodename in ['lucid'] and hash_key_equals($php_values, 'version', '53') {
    apt::key { '67E15F46': key_server => 'hkp://keyserver.ubuntu.com:80' }
    apt::ppa { 'ppa:l-mierzwa/lucid-php5':
      options => '',
      require => Apt::Key['67E15F46']
    }
  }

  $webroot_location = $puphpet::params::nginx_webroot_location

  exec { "exec mkdir -p ${webroot_location}":
    command => "mkdir -p ${webroot_location}",
    onlyif  => "test -d ${webroot_location}",
  }

  if ! defined(File[$webroot_location]) {
    file { $webroot_location:
      ensure  => directory,
      group   => 'www-data',
      mode    => 0775,
      require => [
        Exec["exec mkdir -p ${webroot_location}"],
        Group['www-data']
      ]
    }
  }

  if hash_key_equals($php_values, 'install', 1) {
    $php5_fpm_sock = '/var/run/php5-fpm.sock'

    if $php_values['version'] == undef {
      $fastcgi_pass = null
    } elsif $php_values['version'] == '53' {
      $fastcgi_pass = '127.0.0.1:9000'
    } else {
      $fastcgi_pass = "unix:${php5_fpm_sock}"
    }

    $fastcgi_param_parts = [
      'PATH_INFO $fastcgi_path_info',
      'PATH_TRANSLATED $document_root$fastcgi_path_info',
      'SCRIPT_FILENAME $document_root$fastcgi_script_name'
    ]

    if $::osfamily == 'redhat' and $fastcgi_pass == "unix:${php5_fpm_sock}" {
      exec { "create ${php5_fpm_sock} file":
        command => "touch ${php5_fpm_sock} && chmod 777 ${php5_fpm_sock}",
        onlyif  => ["test ! -f ${php5_fpm_sock}", "test ! -f ${php5_fpm_sock}="],
        require => Package['nginx']
      }

      exec { "listen = 127.0.0.1:9000 => listen = ${php5_fpm_sock}":
        command => "perl -p -i -e 's#listen = 127.0.0.1:9000#listen = ${php5_fpm_sock}#gi' /etc/php-fpm.d/www.conf",
        unless  => "grep -c 'listen = 127.0.0.1:9000' '${php5_fpm_sock}'",
        notify  => [
          Class['nginx::service'],
          Service['php-fpm']
        ],
        require => Exec["create ${php5_fpm_sock} file"]
      }
    }
  } elsif hash_key_equals($hhvm_values, 'install', 1) {
    $fastcgi_pass        = '127.0.0.1:9000'
    $fastcgi_param_parts = [
      'SCRIPT_FILENAME $document_root$fastcgi_script_name'
    ]
  } else {
    $fastcgi_pass        = ''
    $fastcgi_param_parts = []
  }

  class { 'nginx': }

  if count($nginx_values['vhosts']) > 0 {
    each( $nginx_values['vhosts'] ) |$key, $vhost| {
      exec { "exec mkdir -p ${vhost['www_root']} @ key ${key}":
        command => "mkdir -p ${vhost['www_root']}",
        creates => $vhost['docroot'],
      }

      if ! defined(File[$vhost['www_root']]) {
        file { $vhost['www_root']:
          ensure  => directory,
          require => Exec["exec mkdir -p ${vhost['www_root']} @ key ${key}"]
        }
      }
    }

    create_resources(nginx_vhost, $nginx_values['vhosts'])
  }

  if $::osfamily == 'redhat' and ! defined(Iptables::Allow['tcp/80']) {
    iptables::allow { 'tcp/80':
      port     => '80',
      protocol => 'tcp'
    }
  }
}

define nginx_vhost (
  $server_name,
  $server_aliases = [],
  $www_root,
  $listen_port,
  $index_files,
  $envvars = [],
){
  $merged_server_name = concat([$server_name], $server_aliases)

  if is_array($index_files) and count($index_files) > 0 {
    $try_files = $index_files[count($index_files) - 1]
  } else {
    $try_files = 'index.php'
  }

  nginx::resource::vhost { $server_name:
    server_name      => $merged_server_name,
    www_root         => $www_root,
    listen_port      => $listen_port,
    index_files      => $index_files,
    try_files        => ['$uri', '$uri/', "/${try_files}?\$args"],
    vhost_cfg_append => {
       sendfile => 'off'
    }
  }

  $fastcgi_param = concat($fastcgi_param_parts, $envvars)

  nginx::resource::location { "${server_name}-php":
    ensure              => present,
    vhost               => $server_name,
    location            => '~ \.php$',
    proxy               => undef,
    try_files           => ['$uri', '$uri/', "/${try_files}?\$args"],
    www_root            => $www_root,
    location_cfg_append => {
      'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
      'fastcgi_param'           => $fastcgi_param,
      'fastcgi_pass'            => $fastcgi_pass,
      'fastcgi_index'           => 'index.php',
      'include'                 => 'fastcgi_params'
    },
    notify              => Class['nginx::service'],
  }
}

## Begin PHP manifest

if $php_values == undef {
  $php_values = hiera('php', false)
}

if $apache_values == undef {
  $apache_values = hiera('apache', false)
}

if $nginx_values == undef {
  $nginx_values = hiera('nginx', false)
}

if hash_key_equals($php_values, 'install', 1) {
  Class['Php'] -> Class['Php::Devel'] -> Php::Module <| |> -> Php::Pear::Module <| |> -> Php::Pecl::Module <| |>

  if $php_prefix == undef {
    $php_prefix = $::operatingsystem ? {
      /(?i:Ubuntu|Debian|Mint|SLES|OpenSuSE)/ => 'php5-',
      default                                 => 'php-',
    }
  }

  if $php_fpm_ini == undef {
    $php_fpm_ini = $::operatingsystem ? {
      /(?i:Ubuntu|Debian|Mint|SLES|OpenSuSE)/ => '/etc/php5/fpm/php.ini',
      default                                 => '/etc/php.ini',
    }
  }

  if is_hash($apache_values) {
    include apache::params

    if has_key($apache_values, 'mod_spdy') and $apache_values['mod_spdy'] == 1 {
      $php_webserver_service_ini = 'cgi'
    } else {
      $php_webserver_service_ini = 'httpd'
    }

    $php_webserver_service = 'httpd'
    $php_webserver_user    = $apache::params::user
    $php_webserver_restart = true

    class { 'php':
      service => $php_webserver_service
    }
  } elsif is_hash($nginx_values) {
    include nginx::params

    $php_webserver_service     = "${php_prefix}fpm"
    $php_webserver_service_ini = $php_webserver_service
    $php_webserver_user        = $nginx::params::nx_daemon_user
    $php_webserver_restart     = true

    class { 'php':
      package             => $php_webserver_service,
      service             => $php_webserver_service,
      service_autorestart => false,
      config_file         => $php_fpm_ini,
    }

    service { $php_webserver_service:
      ensure     => running,
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      require    => Package[$php_webserver_service]
    }
  } else {
    $php_webserver_service     = undef
    $php_webserver_service_ini = undef
    $php_webserver_restart     = false

    class { 'php':
      package             => "${php_prefix}cli",
      service             => $php_webserver_service,
      service_autorestart => false,
    }
  }

  class { 'php::devel': }

  if count($php_values['modules']['php']) > 0 {
    php_mod { $php_values['modules']['php']:; }
  }
  if count($php_values['modules']['pear']) > 0 {
    php_pear_mod { $php_values['modules']['pear']:; }
  }
  if count($php_values['modules']['pecl']) > 0 {
    php_pecl_mod { $php_values['modules']['pecl']:; }
  }
  if count($php_values['ini']) > 0 {
    each( $php_values['ini'] ) |$key, $value| {
      if is_array($value) {
        each( $php_values['ini'][$key] ) |$innerkey, $innervalue| {
          puphpet::ini { "${key}_${innerkey}":
            entry       => "CUSTOM_${innerkey}/${key}",
            value       => $innervalue,
            php_version => $php_values['version'],
            webserver   => $php_webserver_service_ini
          }
        }
      } else {
        puphpet::ini { $key:
          entry       => "CUSTOM/${key}",
          value       => $value,
          php_version => $php_values['version'],
          webserver   => $php_webserver_service_ini
        }
      }
    }

    if $php_values['ini']['session.save_path'] != undef {
      exec {"mkdir -p ${php_values['ini']['session.save_path']}":
        onlyif  => "test ! -d ${php_values['ini']['session.save_path']}",
      }

      file { $php_values['ini']['session.save_path']:
        ensure  => directory,
        group   => 'www-data',
        mode    => 0775,
        require => Exec["mkdir -p ${php_values['ini']['session.save_path']}"]
      }
    }
  }

  puphpet::ini { $key:
    entry       => 'CUSTOM/date.timezone',
    value       => $php_values['timezone'],
    php_version => $php_values['version'],
    webserver   => $php_webserver_service_ini
  }

  if hash_key_equals($php_values, 'composer', 1) {
    class { 'composer':
      target_dir      => '/usr/local/bin',
      composer_file   => 'composer',
      download_method => 'curl',
      logoutput       => false,
      tmp_path        => '/tmp',
      php_package     => "${php::params::module_prefix}cli",
      curl_package    => 'curl',
      suhosin_enabled => false,
    }
  }
}


define php_mod {
  php::module { $name:
    service_autorestart => $php_webserver_restart,
  }
}
define php_pear_mod {
  php::pear::module { $name:
    use_package         => false,
    service_autorestart => $php_webserver_restart,
  }
}
define php_pecl_mod {
  php::pecl::module { $name:
    use_package         => false,
    service_autorestart => $php_webserver_restart,
  }
}

## Begin Xdebug manifest

if $xdebug_values == undef {
  $xdebug_values = hiera('xdebug', false)
}

if $php_values == undef {
  $php_values = hiera('php', false)
}

if $apache_values == undef {
  $apache_values = hiera('apache', false)
}

if $nginx_values == undef {
  $nginx_values = hiera('nginx', false)
}

if is_hash($apache_values) {
  $xdebug_webserver_service = 'httpd'
} elsif is_hash($nginx_values) {
  $xdebug_webserver_service = 'nginx'
} else {
  $xdebug_webserver_service = undef
}

if hash_key_equals($xdebug_values, 'install', 1) and hash_key_equals($php_values, 'install', 1) {
  class { 'puphpet::xdebug':
    webserver => $xdebug_webserver_service
  }

  if is_hash($xdebug_values['settings']) and count($xdebug_values['settings']) > 0 {
    each( $xdebug_values['settings'] ) |$key, $value| {
      puphpet::ini { $key:
        entry       => "XDEBUG/${key}",
        value       => $value,
        php_version => $php_values['version'],
        webserver   => $xdebug_webserver_service
      }
    }
  }
}

## Begin Drush manifest

if $drush_values == undef {
  $drush_values = hiera('drush', false)
}

if hash_key_equals($drush_values, 'install', 1) {
  if ($drush_values['settings']['drush.tag_branch'] != undef) {
    $drush_tag_branch = $drush_values['settings']['drush.tag_branch']
  } else {
    $drush_tag_branch = ''
  }

  include drush::git::drush
}

## Begin MySQL manifest

if $mysql_values == undef {
  $mysql_values = hiera('mysql', false)
} if $php_values == undef {
  $php_values = hiera('php', false)
} if $apache_values == undef {
  $apache_values = hiera('apache', false)
} if $nginx_values == undef {
  $nginx_values = hiera('nginx', false)
}

if hash_key_equals($mysql_values, 'install', 1) {
  if hash_key_equals($apache_values, 'install', 1) or hash_key_equals($nginx_values, 'install', 1) {
    $mysql_webserver_restart = true
  } else {
    $mysql_webserver_restart = false
  }

  if hash_key_equals($php_values, 'install', 1) {
    $mysql_php_installed = true
    $mysql_php_package   = 'php'
  } elsif hash_key_equals($hhvm_values, 'install', 1) {
    $mysql_php_installed = true
    $mysql_php_package   = 'hhvm'
  } else {
    $mysql_php_installed = false
  }

  if $mysql_values['root_password'] {
    class { 'mysql::server':
      root_password => $mysql_values['root_password'],
    }

    if is_hash($mysql_values['databases']) and count($mysql_values['databases']) > 0 {
      create_resources(mysql_db, $mysql_values['databases'])
    }

    if $mysql_php_installed and $mysql_php_package == 'php' {
      if $::osfamily == 'redhat' and $php_values['version'] == '53' {
        $mysql_php_module = 'mysql'
      } else {
        $mysql_php_module = 'mysqlnd'
      }

      if ! defined(Php::Module[$mysql_php_module]) {
        php::module { $mysql_php_module:
          service_autorestart => $mysql_webserver_restart,
        }
      }
    }
  }

  if hash_key_equals($mysql_values, 'phpmyadmin', 1) and $mysql_php_installed {
    if hash_key_equals($apache_values, 'install', 1) {
      $mysql_pma_webroot_location = $puphpet::params::apache_webroot_location
    } elsif hash_key_equals($nginx_values, 'install', 1) {
      $mysql_pma_webroot_location = $puphpet::params::nginx_webroot_location

      mysql_nginx_default_conf { 'override_default_conf':
        webroot => $mysql_pma_webroot_location
      }
    } else {
      $mysql_pma_webroot_location = '/var/www'
    }

    class { 'puphpet::phpmyadmin':
      dbms             => 'mysql::server',
      webroot_location => $mysql_pma_webroot_location,
    }
  }

  if hash_key_equals($mysql_values, 'adminer', 1) and $mysql_php_installed {
    if hash_key_equals($apache_values, 'install', 1) {
      $mysql_adminer_webroot_location = $puphpet::params::apache_webroot_location
    } elsif hash_key_equals($nginx_values, 'install', 1) {
      $mysql_adminer_webroot_location = $puphpet::params::nginx_webroot_location
    } else {
      $mysql_adminer_webroot_location = $puphpet::params::apache_webroot_location
    }

    class { 'puphpet::adminer':
      location    => "${mysql_adminer_webroot_location}/adminer",
      owner       => 'www-data',
      php_package => $mysql_php_package
    }
  }
}

define mysql_db (
  $user,
  $password,
  $host,
  $grant    = [],
  $sql_file = false
) {
  if $name == '' or $password == '' or $host == '' {
    fail( 'MySQL DB requires that name, password and host be set. Please check your settings!' )
  }

  mysql::db { $name:
    user     => $user,
    password => $password,
    host     => $host,
    grant    => $grant,
    sql      => $sql_file,
  }
}

# @todo update this
define mysql_nginx_default_conf (
  $webroot
) {
  if $php5_fpm_sock == undef {
    $php5_fpm_sock = '/var/run/php5-fpm.sock'
  }

  if $fastcgi_pass == undef {
    $fastcgi_pass = $php_values['version'] ? {
      undef   => null,
      '53'    => '127.0.0.1:9000',
      default => "unix:${php5_fpm_sock}"
    }
  }

  class { 'puphpet::nginx':
    fastcgi_pass => $fastcgi_pass,
    notify       => Class['nginx::service'],
  }
}

## Begin MongoDb manifest

if $mongodb_values == undef {
  $mongodb_values = hiera('mongodb', false)
}

if $php_values == undef {
  $php_values = hiera('php', false)
}

if $apache_values == undef {
  $apache_values = hiera('apache', false)
}

if $nginx_values == undef {
  $nginx_values = hiera('nginx', false)
}

if is_hash($apache_values) or is_hash($nginx_values) {
  $mongodb_webserver_restart = true
} else {
  $mongodb_webserver_restart = false
}

if hash_key_equals($mongodb_values, 'install', 1) {
  case $::osfamily {
    'debian': {
      class {'::mongodb::globals':
        manage_package_repo => true,
      }->
      class {'::mongodb::server':
        auth => $mongodb_values['auth'],
        port => $mongodb_values['port'],
      }

      $mongodb_pecl = 'mongo'
    }
    'redhat': {
      class {'::mongodb::globals':
        manage_package_repo => true,
      }->
      class {'::mongodb::server':
        auth => $mongodb_values['auth'],
        port => $mongodb_values['port'],
      }->
      class {'::mongodb::client': }

      $mongodb_pecl = 'pecl-mongo'
    }
  }

  if is_hash($mongodb_values['databases']) and count($mongodb_values['databases']) > 0 {
    create_resources(mongodb_db, $mongodb_values['databases'])
  }

  if is_hash($php_values) and has_key($php_values, 'install') and $php_values['install'] == 1 and ! defined(Php::Pecl::Module[$mongodb_pecl]) {
    php::pecl::module { $mongodb_pecl:
      service_autorestart => $mariadb_webserver_restart,
      require             => Class['::mongodb::server']
    }
  }
}

define mongodb_db (
  $user,
  $password
) {
  if $name == '' or $password == '' {
    fail( 'MongoDB requires that name and password be set. Please check your settings!' )
  }

  mongodb::db { $name:
    user     => $user,
    password => $password
  }
}

# Begin beanstalkd

if $beanstalkd_values == undef {
  $beanstalkd_values = hiera('beanstalkd', false)
}

if $php_values == undef {
  $php_values = hiera('php', false)
}

if $hhvm_values == undef {
  $hhvm_values = hiera('hhvm', false)
}

if $apache_values == undef {
  $apache_values = hiera('apache', false)
}

if $nginx_values == undef {
  $nginx_values = hiera('nginx', false)
}

if is_hash($apache_values) {
  $beanstalk_console_webroot_location = "${puphpet::params::apache_webroot_location}/beanstalk_console"
} elsif is_hash($nginx_values) {
  $beanstalk_console_webroot_location = "${puphpet::params::nginx_webroot_location}/beanstalk_console"
} else {
  $beanstalk_console_webroot_location = undef
}

if hash_key_equals($php_values, 'install', 1) or hash_key_equals($hhvm_values, 'install', 1) {
  $beanstalkd_php_installed = true
} else {
  $beanstalkd_php_installed = false
}

if hash_key_equals($beanstalkd_values, 'install', 1) {
  create_resources(beanstalkd::config, {'beanstalkd' => $beanstalkd_values['settings']})

  if hash_key_equals($beanstalkd_values, 'beanstalk_console', 1) and $beanstalk_console_webroot_location != undef and $beanstalkd_php_installed {
    exec { 'delete-beanstalk_console-path-if-not-git-repo':
      command => "rm -rf ${beanstalk_console_webroot_location}",
      onlyif  => "test ! -d ${beanstalk_console_webroot_location}/.git"
    }

    vcsrepo { $beanstalk_console_webroot_location:
      ensure   => present,
      provider => git,
      source   => 'https://github.com/ptrofimov/beanstalk_console.git',
      require  => Exec['delete-beanstalk_console-path-if-not-git-repo']
    }
  }
}

# Begin rabbitmq

if $rabbitmq_values == undef {
  $rabbitmq_values = hiera('rabbitmq', false)
}

if $php_values == undef {
  $php_values = hiera('php', false)
}

if hash_key_equals($rabbitmq_values, 'install', 1) {
  class { 'rabbitmq':
    port => $rabbitmq_values['port']
  }

  if hash_key_equals($php_values, 'install', 1) and ! defined(Php::Pecl::Module['amqp']) {
    php_pecl_mod { 'amqp': }
  }
}

