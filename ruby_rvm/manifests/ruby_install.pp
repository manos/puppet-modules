#
# == Sample Usage
# The following installs a minimal ruby env (with gem, rake):
#     ruby::ruby_install { "1.8.7":  ruby_version => "1.8.7", ruby_env => "cloudkick", }
#
# You probably want to install something specific afterward. See ruby::gem_install.
# Note: this takes a long time on the first run!
#
define ruby::ruby_install (
    $ruby_version,
    $ruby_env           = false
){
    include ruby::params
    $rvm_env_vars = $ruby::params::rvm_env_vars
    $rvm_profile  = $ruby::params::rvm_profile
    $rvm          = $ruby::params::rvm

    ### default to $name
    $_ruby_env = $ruby_env ? {
        default => $ruby_env,
        false   => $name,
    }

    Exec { path    => "/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin", }

    # install the requested ruby_version:
    exec { "rvm_install_${_ruby_env}":
        command => "$rvm_env_vars $rvm install $ruby_version\"",
        unless  => "$rvm_env_vars $rvm list |grep $ruby_version\"",
        require => Exec['install_rvm'],
        timeout => 0,
    }

    # also, set up wrappers.
    #
    # e.g. $_ruby_env gets a -ruby script in /usr/local/bin, which prepends sourcing of the rvm_profile, and execs.

    # we're only writing scripts in this class, default to 0755:
    File { mode => 755, require => Exec["rvm_install_${_ruby_env}"] }

    # wrapper scripts, that DTRT with arguments like 'arg1 has spaces and * and --foo', when passing it on.
    $start_of_script = '#!/bin/bash
                . /etc/profile.d/rvm.sh
                export PATH
                declare -a args
                count=0
                for arg in "$@"; do args[count]="$arg"; count=$((count+1)); done
        '
    $argstring = '"${args[@]}"'

    file { "/usr/local/bin/${_ruby_env}-ruby":
        content => "$start_of_script
            exec $rvm $ruby_version do ruby $argstring
            ",
    }
    # make 'ruby' just work. This also means kcloudkick is runs ruby. hmm. well, this is how it is.
    file { "/usr/local/bin/${_ruby_env}":
        ensure => link,
        target => "/usr/local/bin/k${_ruby_env}-ruby",
    }
    file { "/usr/local/bin/${_ruby_env}-rdoc":
        content => "$start_of_script
            exec $rvm $ruby_version do rdoc $argstring
            ",
    }
    file { "/usr/local/bin/${_ruby_env}-rake":
        content => "$start_of_script
            exec $rvm $ruby_version do rake $argstring
            ",
    }
    #XXX: not sure we need these; people shouldn't be running rvm or gem by hand:
    file { "/usr/local/bin/${_ruby_env}-gem":
        content => "$start_of_script
            exec $rvm $ruby_version do gem $argstring
            ",
    }
    file { "/usr/local/bin/${_ruby_env}-rvm":
        content => "$start_of_script
            exec $rvm $ruby_version $argstring
            ",
    }
}

# == Overview
#    Manage rubygems version, in a ruby_env (e.g. in case a gem you plan to install needs newer rubygems)
# == Sample Usage
#    ruby::ruby_install::gemupdate { "1.8.19": ruby_env => "cloudkick" }
#
#
define ruby::ruby_install::gemupdate (
    $ruby_env
){

    $version = $name

    Exec {
        path    => "/usr/local/rvm/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin",
    }

    exec { "/usr/local/bin/k${ruby_env}-rvm rubygems $version": }

}


