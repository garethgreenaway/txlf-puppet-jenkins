class company::application( $war_svn_type, $war_branch, $war_revision ) {

  # Depends on resin class
  Class['resin'] -> Class['company::application']
  
	appdeploy{ "AppServer":
	 war_svn_type => $war_svn_type,
	 war_branch => $war_branch,
	 war_revision => $ war_revision,
  }
  
}

