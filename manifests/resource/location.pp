# define: nginx::resource::location
#
# This definition creates a new location entry within a virtual host
#
# Parameters:
#   [*ensure*]             - Enables or disables the specified location (present|absent)
#   [*vhost*]              - Defines the default vHost for this location entry to include with
#   [*location*]           - Specifies the URI associated with this location entry
#   [*www_root*]           - Specifies the location on disk for files to be read from. Cannot be set in conjunction with $proxy or $nginx_alias
#   [*index_files*]        - Default index files for NGINX to read when traversing a directory
#   [*proxy*]              - Proxy server(s) for a location to connect to. Accepts a single value, can be used in conjunction
#                            with nginx::resource::upstream . Cannot be set in conjunction with $www_root or $nginx_alias
#   [*proxy_read_timeout*] - Override the default the proxy read timeout value of 90 seconds
#   [*nginx_alias*]        - Sets up an alias for the location.
#   [*ssl*]                - Indicates whether to setup SSL bindings for this location.
#   [*option*]             - List of option rules.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::location { 'test2.local-bob':
#    ensure   => present,
#    www_root => '/var/www/bob',
#    location => '/bob',
#    vhost    => 'test2.local',
#  }
define nginx::resource::location(
  $location,
  $ensure             = present,
  $vhost              = undef,
  $www_root           = undef,
  $index_files        = ['index.html', 'index.htm', 'index.php'],
  $proxy              = undef,
  $proxy_read_timeout = $nginx::params::nx_proxy_read_timeout,
  $nginx_alias        = undef,
  $ssl                = false,
  $options            = []
) {

  validate_array($options)

  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Class['nginx::service'],
  }

  ## Shared Variables
  $ensure_real = $ensure ? {
    'absent' => absent,
    default  => file,
  }

  # Use proxy template if $proxy is defined, otherwise use directory template.
  if ($proxy != undef) {
    $content_real = template('nginx/vhost/vhost_location_proxy.erb')
  } elsif ($nginx_alias != undef) {
    $content_real = template('nginx/vhost/vhost_location_alias.erb')
  } else {
    $content_real = template('nginx/vhost/vhost_location_directory.erb')
  }

  ## Check for various error condtiions
  if ($vhost == undef) {
    fail('Cannot create a location reference without attaching to a virtual host')
  }
  if (($www_root == undef) and ($proxy == undef) and ($nginx_alias == undef)) {
    fail('Cannot create a location reference without a www_root, nginx_alias or proxy defined')
  }
  if (($www_root != undef) and ($nginx_alias != undef or $proxy != undef)) {
    fail('Can only define one of www_root, nginx_alias or proxy')
  }
  if ($nginx_alias != undef and $proxy != undef) {
    fail('Can only define one of www_root, nginx_alias or proxy')
  }

  ## Create stubs for vHost File Fragment Pattern
  if ($ssl == false) {
    file {"${nginx::config::nx_temp_dir}/nginx.d/${vhost}-500-${name}":
      ensure  => $ensure_real,
      content => $content_real,
    }
  }

  ## Only create SSL Specific locations if $ssl is true.
  if ($ssl == true) {
    file {"${nginx::config::nx_temp_dir}/nginx.d/${vhost}-800-${name}-ssl":
      ensure  => $ensure_real,
      content => $content_real,
    }
  }
}
