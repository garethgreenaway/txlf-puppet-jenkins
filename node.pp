class { "company::params::deploy": }

class { 'company::application':

  svn_type => "${company::params::deploy::svn_type}",
  war_branch => "${company::params::deploy::war_branch}",
  war_revision => "${company::params::deployment::war_revision}",

}
