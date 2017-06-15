# See README.md for details.
define openldap::server::ppolicy(
  $ensure = undef,
) {

  if ! defined(Class['openldap::server']) {
    fail 'class ::openldap::server has not been evaluated'
  }

  if $::openldap::server::provider == 'augeas' {
    Class['openldap::server::install']
    -> Openldap::Server::Ppolicy[$title]
    ~> Class['openldap::server::service']
  } else {
    Class['openldap::server::service']
    -> Openldap::Server::Ppolicy[$title]
    -> Class['openldap::server']
  }

  openldap_ppolicy { $title:
    ensure   => $ensure,
    provider => $::openldap::server::provider,
  }
}
