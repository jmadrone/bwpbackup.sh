#!/bin/sh

# Backup wordpress and all associated files and databases.
# Bitnami full backup instructions https://docs.bitnami.com/aws/apps/wordpress/#backup

#----------------------------------------
# OPTIONS - Configure ALL user options in the .config file
#----------------------------------------

# Pull user options from .config file
source .config

# Check if root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Change to working directory
cd $work_dir

# Create the backup folder
if [ ! -d $backup_dir ]; then
  mkdir -p $backup_dir
fi


# Stop all services
echo "Stopping Services"
sudo /opt/bitnami/ctlscript.sh stop

# Compress entire directory
echo "Compressing directory /opt/bitnami"
sudo tar -pczvf "$backup_dir/www-backup-${today}.tgz" /opt/bitnami

# Restart all services
echo "Starting Services"
sudo /opt/bitnami/ctlscript.sh start

echo "Backup complete at $backup_dir/www-backup-${today}.tgz"

# Move to S3
echo "Moving backup file to S3 bucket at $s3_bucket/$backup_dir/www-backup-${today}.tgz"
aws s3 cp "$backup_dir/www-backup-${today}.tgz" "$s3_bucket"

echo "Removing local backup file at $backup_dir/www-backup-${today}.tgz"
sudo rm "$backup_dir/www-backup-${today}.tgz"


echo "Finished full backup and copied to S3"
echo "The backup file has been saved to $s3_bucket/$backup_dir/www-backup-${today}.tgz"
