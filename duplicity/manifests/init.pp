#
# duplicity
#
#== Overview
#    Class to manage file system backups to s3 with duplicity.
#
#    Defaults: just pass it a path, and it'll backup:
#     * 1 full backup the first night, followed by
#       * 5 incremental backups
#     * a full backup the 7th night, followed by
#       * a 'prune' job to remove oldest $num_fulls and all associated incremental data.
#
#== Sample Usage
#    include duplicity
#    duplicity::backup { "/home/": }
#
#== Arguments
#   $name      required  path to backup; NOTE: must start and end with a '/'
#   $path      optional  path to backup, if different from $name; NOTE: must start and end with a '/'
#   $num_fulls optional  specifies how many full weekly backup sets to keep; default=1
#   $hour      optional  specifies at what hour (UTC) to run the backup cron; default=random between 0 and 8
#
class duplicity {

    # package install: duplicity.
    package { "duplicity": ensure => latest }

}
