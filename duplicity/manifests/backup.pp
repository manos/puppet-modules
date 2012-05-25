define duplicity::backup ( $path = false, $num_fulls='1', $hour=false ) {

    include duplicity
    include duplicity::params

    # $path argument must have a trailing slash (just fix if it doesn't)
    if ! $path {
        $path_real = regsubst($name, '^(.*[^/])$', '\1/')
    }
    else {
        $path_real = regsubst($path, '^(.*[^/])$', '\1/')
    }

    # make sure it starts with a /, too:
    if $path_real !~ /^\// { fail("path must begin with a slash!") }

    # splay the hour between 0 and 8 (UTC!) (or just use the one specified)
    if ! $hour {
        $hour_real = fqdn_rand(8)
    } else {
        $hour_real = $hour
    }

    # the first one will be full, subsequent ones are incremental:
    cron { "duplicity backup of ${path_real} for ${::hostname}":
        user    => root,
        command => "$kduplicity::params::duplicity --no-encryption $path_real ${kduplicity::params::bucket}${path_real} >/dev/null",
        minute  => '0',
        hour    => $hour_real,
        weekday => [Sun,Mon,Tue,Wed,Thu,Fri],
    }

    # force a full, and remove older ones based on $num_fulls.
    cron { "duplicity weekly full backup and cleanup of ${path_real} for ${::hostname}":
        user    => root,
        command => "$kduplicity::params::duplicity --no-encryption full $path_real ${kduplicity::params::bucket}${path_real} && $duplicity --force remove-all-but-n-full $num_fulls $path_real >/dev/null",
        minute  => '0',
        hour    => $hour_real,
        weekday => 'Sat',
    }

}
