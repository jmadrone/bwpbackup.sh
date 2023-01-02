# wpbackup.sh

This bash script was designed to automate the backup process of [Bitnami WordPress](https://docs.bitnami.com/aws/apps/wordpress/) stack to Amazon S3. Other backup destinations are possible (Google Cloud Storage, FTP, SFTP, SCP, rsync, file...) with minor modifications.

## Pre-requisites

- `aws-cli`

## There are four (4) scripts included:

1. `wpbackup.sh` - main script, used for automated backup to an S3 bucket (no output seen on screen)
2. `full-backup.sh` - use to manually create a full application backup and upload to S3 (visually watch backup status)
3. `scheduled-backup.sh` - use to ...
4. `restore-backup.sh` - use this to restore a previous backup to a new server or fresh install

## INSTRUCTIONS

1.  SSH into your Bitnami for Wordpress server and clone this repository into the user folder, then change directory into the newly cloned repo

        git clone https://github.com/allcomone-llc/wpbackup.sh.git && cd wpbackup.sh

2.  Edit the `.config` file to modify USER OPTIONS

        nano .config
        AWS_ACCESS_KEY_ID=[Your AWS Access Key ID Here]
        AWS_SECRET_ACCESS_KEY=[Your AWS Secret Access Key Here]
        Ctrl+x      #write & quit

    Possible **USER OPTIONS** Configureable in the `.config` file. These will be used for all scripts.

    - your AWS access key and secret #**change these**
    - workig directory #default is `/home/bitnami`
    - backup path #default is `$WORKING_DIRECTORY/backup`
    - bucket name #**You need to change this**
    - number of days to keep #default is 3 days for local backups

3.  Run the script of your choice as ROOT

        sudo ./wpbackup.sh
