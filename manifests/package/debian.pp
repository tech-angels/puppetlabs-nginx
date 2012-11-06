# Class: nginx::package::debian
#
# This module manages NGINX package installation on debian based systems
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
$nginx_debian_package_name = 'nginx'

class nginx::package::debian {
  if ($nginx_debian_package_name) {
     $nginx_package = $nginx_debian_package_name
  } else {
     $nginx_package = 'nginx'
  }
  package { $nginx_package:
    alias  => 'nginx',
    ensure => present,
  }
}
