define appdeploy( $war_svn_type, $war_branch, $war_revision ) {
  
  if ( $war_svn_type == "branch" ) {
    $war_release = "$war_svn_type/$war_branch/$war_revision"
  } else {
    $war_release = "$war_svn_type/$war_revision"
  }
  
	$resin_xml = "resin.xml.erb"

	file { "/etc/company/${name}/":
		owner	=> root,
		group 	=> root,
		mode 	=> 755,
		ensure => directory,
	}

  file {"/etc/company/${name}/release":
    owner => company,
    group   => company,
    mode  => 755,
    require => File["/etc/company/${name}"],
    content => template("company/release.erb"),
  }
  
  file {"/etc/init.d/${name}":
    ensure => link,
    target => "/etc/init.d/company-app",
    notify => Exec["enable_service_${name}"],
  }

	exec { "enable_service_${name}":
		refreshonly => true,
		command => "/usr/sbin/update-rc.d ${name} defaults 99 01",
	}

  file {"/opt/company/${name}":
    owner	=> root,
    group 	=> root,
    mode 	=> 755,
    ensure => directory,
    require => [
      File["/opt/company"],
      File["/var/log/resin"],
    ],
  }

	file {"/opt/company/${name}/store":
		owner	=> root,
		group 	=> root,
		mode 	=> 755,
		ensure => directory,
		require => File["/opt/company/${name}"],
	}

	file {"/opt/company/${name}/conf":
		ensure => link,
		require => [
				File["/opt/company/${name}"],
				File["/etc/company/${name}"],
		],
		target => "/etc/company/${name}",
	}

	file {"/opt/company/${name}/webapps":
		owner	=> company,
		group 	=> company,
		mode 	=> 755,
		ensure => directory,
		require => File["/opt/company/${name}"],
	}

  file {"/opt/company/${name}/store/ROOT.war":
    owner	=> root,
    group 	=> root,
    mode 	=> 755,
    source => "/nfs/release/wars/${war_release}/company-${name}-trunk-SNAPSHOT.war",
    require => File["/opt/company/${name}/webapps"],
    notify => Exec["Copy ${name} War"],
    backup => false,
  }

  file {"/etc/rsyslog.d/30-${name}.conf":
    content => template("company/rsyslog.erb"),
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => File["/var/log/company"],
    notify => Exec["rsyslog restart"],
  }

  file {"/etc/logrotate.d/${name}":
    content => template("company/logrotate.erb"),
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => File["/var/log/company"],
  }

  # Create the resin.xml file for app_server
  file {"/etc/company/${name}/resin.xml":
    content => template("resin/$resin_xml"),
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => File["/etc/company/${name}"],
    notify => Exec["${name} restart"],
  }

	if $resin_db == 'yes' {

    # Create the resin.xml file for app_server
    file {"/etc/company/${name}/company-database.xml":
      content => template("resin/company-database.xml.erb"),
      mode => 0644,
      owner => 'root',
      group => 'root',
      require => File["/etc/company/${name}"],
      notify => Exec["${name} restart"],
    }
	}

  ### log4j.properties file creation ###
  
  # Define the variable for the log4j.properties file since it needs to be in local scope.
  $log4j_level = 'info'
  $resin_server_name = "${name}"
  
  # Create the log4j.properties file for app_server
  file {"/etc/company/${name}/log4j.properties":
    content => template("resin/log4j.properties.erb"),
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => File["/etc/company/${name}"],
    notify => Exec["${name} restart"],
  }

  ### admin-users.xml ###
  
  # Get the file and put it in place
  file {"/etc/company/${name}/admin-users.xml":
    source => "puppet:///modules/resin/admin-users.xml",
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => File["/etc/company/${name}"],
    notify => Exec["${name} restart"],
  }

  ### app-default.xml ###
  
  # Get the file and put it in place
  file {"/etc/company/${name}/app-default.xml":
    source => "puppet:///modules/resin/app-default.xml",
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => File["/etc/company/${name}"],
    notify => Exec["${name} restart"],
  }
  
  # Get the file and put it in place
  file {"/etc/company/${name}/vars":
    source => "puppet:///modules/company/${name}/vars",
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => File["/etc/company/${name}"],
  }

	exec { "Copy ${name} War":
		command => "/bin/cp /opt/company/${name}/store/ROOT.war /opt/company/${name}/webapps/ROOT.war",
		notify => [
				Exec["${name} WAR clean"],
				Exec["${name} cache clean"],
				Exec["${name} restart"],
		],
  	refreshonly => true,
	}

  exec { "${name} stop":
    command => "/etc/init.d/resin stop ${name}",
    before => [
      Exec["Copy ${name} War"],
      Exec["${name} WAR clean"],
      Exec["${name} cache clean"],
    ],
    require => File["/etc/init.d/resin"],
    refreshonly => true,
  }

  exec { "${name} restart":
    command => "/etc/init.d/resin restart ${name}",
    require => [
      Exec["Copy ${name} War"],
      File["/etc/company/${name}/resin.xml"],
      File["/etc/company/${name}/log4j.properties"],
      File["/etc/company/${name}/admin-users.xml"],
      File["/etc/company/${name}/app-default.xml"],
      File["/etc/init.d/resin"],
    ],
    notify => Exec["email-deployment-alert"],
    refreshonly => true,
  }

  exec { "${name} WAR clean":
    command => "/bin/rm -rf /opt/company/${name}/webapps/ROOT",
    before => Exec["${name} restart"],
    onlyif => "/usr/bin/test -d /opt/company/${name}/webapps/ROOT",
    refreshonly => true,
  }

  exec { "${name} cache clean":
    command => "/bin/rm -rf /opt/company/resin/resin-data/${name}",
    before => Exec["${name} restart"],
    onlyif => "/usr/bin/test -d /opt/company/resin/resin-data/${name}",
    refreshonly => true,
  }
}
