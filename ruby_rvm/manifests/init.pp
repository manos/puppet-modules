# Ruby rvm installer and manager.
# Charlie Schluting <charlie@schluting.com>
# == Overview
# Manages ruby version and their gems, optionally installing gem programs as system binaries.
# NOTE: this is causing a lot of confusion. This is NOT virtualenv. You can only install ONE
# version of ruby at a time. If you really want to have multiple versions of ruby 1.9.3, e.g.,
# then specify the patch level. You shouldn't need to do this though.
#
# Again, this is not for 'environment isolation' - stop thinking of it as virtualenv. This is
# for managing multiple versions of ruby, i.e. rvm!
#
# == Sample Usage
# Most complex example:
# To get cloudkick installed, in a 1.8.7 ruby env, and runnable via /usr/local/bin/cloudkick:
# ruby::ruby_install { "1.8.7":  ruby_version => "1.8.7", ruby_env => "cloudkick", } ->
# ruby::gem_install { "crack":   ruby_env => "cloudkick", gem_version => "0.1.8" }
# ruby::gem_install { "jeweler": ruby_env => "cloudkick", gem_version => "1.6.4" }
# ruby::gem_install { "cloudkick": ruby_env => "cloudkick", install_bin => "cloudkick", force_bin_overwrite => true }
#
# Trivial example, which is done by default:
# # install ruby 1.9.3 and call it "newhotness":
# ruby::ruby_install { "1.9.3": ruby_version => '1.9.3', ruby_env => 'newhotness', }
#
# And install a random gem in it:
# ruby::gem_install { "zzzzzz": ruby_env => "newhotness" }
#
# Note: if you have two ruby_envs in scope on the same server, you'll get conflicts installing the same gem in each.
# In this case, name the call something different, and explicitly pass gem => "name_of_gem" (i.e. the define uses $name by default).
#
#
class ruby {
    include kbase::params
    include ruby::params

    $my_name          = $ruby::params::my_name
    $my_dir           = $ruby::params::my_dir
    $rvm_env_vars     = $ruby::params::rvm_env_vars
    $src_dir          = $ruby::params::src_dir

    Exec { path => "/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin" }

    ### create the component dir
    file { $my_dir:
        source  => "puppet:///modules/$my_name",
        ensure  => directory,
        recurse => true,
        mode    => 755,
        owner   => root,
        group   => root,
        purge   => true,
        force   => true,    # remove directories as well
    }

    ### location for git clones to live in
    file { $src_dir:
        ensure  => directory,
        owner   => $kbase::params::system_user_name,
        group   => $kbase::params::system_user_name,
    }

    # the new package manager: bash. using 'creates' to only run it once.
    file { "${src_dir}/rvm-installer":
        source  => "puppet:///modules/${my_name}/sources/rvm-installer",
        mode    => 755,
        owner   => root,
        require => [ File[$src_dir], ],
    }
    exec { "install_rvm":
        command => "sudo bash ${my_dir}/sources/rvm-installer ",
        creates => "/usr/local/rvm",
        require => [ File["${src_dir}/rvm-installer"], ],
    }

    # rvm must be installed in /usr/local/rvm, so symlink it to /usr/local/ruby_rvm....
    file { "${my_dir}/rvm":
        ensure  => link,
        target  => "/usr/local/rvm",
        require => File[$my_dir],
        owner   => root,
    }

    # install latest ruby (as of now), as a starting point. this is ruby.
    ruby::ruby_install { "1.9.3":
        ruby_version => '1.9.3',
        ruby_env     => 'ruby',
    }


}
