class ruby::params {
    include kbase::params

    $my_name       = "ruby"
    $my_dir        = "/usr/local/ruby_${rvm}"
    $src_dir       = "${my_dir}/sources"

    $rvm              = "/usr/local/rvm/bin/rvm"
    $rvm_profile      = "/etc/profile.d/rvm.sh"
    $rvm_env_vars     = "bash -c \"source ${rvm_profile} &&"
}
