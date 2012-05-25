#
# == Overview
# Installs ruby gems in a system-wide rvm environment.
# Optionally, it can write a binary in /usr/local/bin if you specify install_bin => "name". You probably want to name it ruby_$env-$gem in most cases.
# If it already exists on our systems, use force_bin_overwrite => true, to make puppet generate this every time. NOTE: use caution!
#
#
# == Sample Usage
# Once you've installed a ruby version and named it, you can call gem_install on the ruby_env (name) you gave the ruby.
# (see ruby_install.pp)
#
# Basic usage; install 'crack' gem in the 'cloudkick' ruby env:
# ruby::gem_install { "crack": ruby_env => "cloudkick", }
#
# Install a gem, specifying the version:
# ruby::gem_install { "crack":   ruby_env => "cloudkick", gem_version => "0.1.8" }
# ruby::gem_install { "jeweler": ruby_env => "cloudkick", gem_version => "1.6.4" }
#
# Install a gem from github, latest version:
# ruby::gem_install { "cloudkick": ruby_env => "cloudkick", install_bin => 'cloudkick' }
#
# == Requires
#  A working git module, with git::clone.
#
define ruby::gem_install (
    $ruby_env,
    $gem                 = "",
    $gem_version         = false,
    $vcs                 = false,
    $install_bin         = false,
    $force_bin_overwrite = false
){
    include ruby::params
    include ruby

    # this pisses me off. Though, with a newer puppet, we could define gem_install ( $gem = $name ) and
    # then life would be rainbows and ponies.
    if $gem == "" { $thegem = $name } else { $thegem = $gem }

    $rvm              = $ruby::params::rvm
    $rvm_env_vars     = $ruby::params::rvm_env_vars
    $src_dir          = $ruby::params::src_dir

    # do this to speed up installs, nobody reads docs anyway ;)
    if $gem_version {
        $_gem = "$thegem -v $gem_version --no-rdoc --no-ri"
    }
    else { $_gem = "$thegem --no-rdoc --no-ri" }

    Exec {
        path    => "/usr/local/rvm/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin",
        require => Exec["rvm_install_${ruby_env}"],
    }

    # if we're installing from a repo:
    if $vcs {
        # install from $vcs (git::clone into $source_dir)
        git::clone { $thegem:
            host        => $_host,
            source      => $vcs,
            dir         => $src_dir,
            target      => $thegem,
        }

        # rake install
        exec { "rake_install_${thegem}":
            command => "/usr/local/bin/${ruby_env}-rake install",
            cwd     => "${src_dir}/${thegem}",
            require => [ Git::Clone[$thegem], ]
        }
    }
    else {

        # install the gem from $MAGIC_PLACE (no vcs was specified)

        # used below for 'unless' to prevent execution if already installed.. "gem list |grep" is faster than running "gem install" every time!
        if $gem_version {
            $grep_string = "|grep $thegem |grep $gem_version"
        } else { $grep_string = "|grep $thegem" }

        exec { "rvm_gem_install_${thegem}_in_${ruby_env}":
            command => "/usr/local/bin/${ruby_env}-gem install $_gem",
            unless  => "$rvm_env_vars rvm $ruby_version do gem list $grep_string \"",
            require => [ File["/usr/local/bin/${ruby_env}-gem"] ],
        }
    }

    # we probably want (some) gems to now be executable.. let's make a wrapper:
    #  Note: unless you want errors to spew, you must call 'rvm gem' with a specific version (`rvm 1.8.7 do gem`)
    #  We use the foo-rvm wrapper to handle this for us.

    # use install_bin => name, to specify that a wrapper in /usr/local/bin/ should be generated.
    # if force_bin_overwrite=true, then write it every time puppet runs.
    if $force_bin_overwrite {
        # remove, a) in case it's a symlink, so we aren't writing to the wrong place; b) so new gets written below:
        exec { "rm -f /usr/local/bin/${install_bin}": before => File["/usr/local/bin/${install_bin}"] }

    }
    $argstring = '"${args[@]}"'
    if $install_bin {
        file { "/usr/local/bin/${install_bin}":
            content => "#!/bin/bash
                declare -a args
                count=0
                for arg in \"$@\"; do args[count]=\"\$arg\"; count=$((count+1)); done
                exec /usr/local/bin/${ruby_env}-rvm do $thegem $argstring
                ",
            mode    => 755,
        }
    }

}
