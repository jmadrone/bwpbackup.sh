#!/usr/bin/env bash
#
# Copyright (C) 2020 Josh Madrone
#
#
# This program is free software: you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published by 
# the Free Software Foundation, either version 3 of the License, or 
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License 
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#	bwpbackup.sh Backup Script
#
# Bash script to backup Bitnami for Wordpress stacks
#
# Configure user options in the included `.config` file.
#
# To setup CRON
# add the next line to crontab of root user to run every day at 3:30am
# 30 3 * * * /path/to/wpbackup.sh >> /path/to/logs/wpbackup_cron.log 2>&1
# 
#
############################# options #########################################
#
# Please edit all USER OPTIONS in the `.config` file first
#
######################## script happens below #################################
#
# Load config values
source ./.config



# Check if root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

# Change to working directory
cd "$work_dir" || exit

# Create the backup folder
if [ ! -d "$backup_dir" ]; then
  mkdir -p "$backup_dir"
fi

# check if tmp dir was created
#if [[ ! "$backup_dir" || ! -d "$backup_dir" ]]; then
#  echo "Could not create temp dir"
#  exit 1
#fi

# Create the logs folder
logs="${backup_dir}/logs"

if [ ! -d "$logs" ]; then
  mkdir -p "$logs"
fi

# Create the log file
touch "${logs}/${log_file}"

#!/bin/bash
#
# Copyright (c) 2020 Josh Madrone
#
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.
#
#				WPBACKUP.SH Backup Script
#
# Backup wordpress and all associated files and databases.
# Bitnami full backup instructions https://docs.bitnami.com/aws/apps/wordpress/#backup
#
# 
#
# To setup CRON
# add the next line to crontab of root user to run every day at 3:30am
# 30 3 * * * /home/bitnami/wpbackup.sh >> /home/bitnami/backup/logs/wpbackup_cron.log 2>&1
# 
#
#----------------------------------------
# USER OPTIONS - Configure ALL user options in the `.config` file
#  - Add your AWS credentials
#  - Configure other vars, such as $BACKUP_PATH, $LOGS and $LOG_FILE...
#  - All options are now stored in the separate config file named `.config`
#----------------------------------------

##############################################################
# Script Happens Below This Line - Shouldn't Require Editing #
##############################################################

# Load config values
source .config

# Check if root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Change to working directory
cd $WORKING_DIR

# Create the backup folder
if [ ! -d $BACKUP_PATH ]; then
  mkdir -p $BACKUP_PATH
fi

# Create the logs folder

if [ ! -d $LOGS ]; then
  mkdir -p $LOGS
fi

# Create the log file
touch $LOGS/$LOG_FILE


# Stop all services
echo "Stopping Services" >> $LOGS/$LOG_FILE
sudo /opt/bitnami/ctlscript.sh stop >> $LOGS/$LOG_FILE 2>&1

# Compress entire directory
echo "Creating backup..." >> $LOGS/$LOG_FILE
sudo tar -pczf $BACKUP_PATH/full-application-backup-$NOW.tgz /opt/bitnami >> $LOGS/$LOG_FILE 2>&1

# Restart all services
echo "Starting Services" >> $LOGS/$LOG_FILE
sudo /opt/bitnami/ctlscript.sh start >> $LOGS/$LOG_FILE 2>&1

echo "Backup complete at $BACKUP_PATH/full-application-backup-$NOW.tgz" >> $LOGS/$LOG_FILE

# Move to S3
echo "Moving backup file to S3 bucket" >> $LOGS/$LOG_FILE
/usr/bin/aws s3 cp $BACKUP_PATH/full-application-backup-$NOW.tgz $BUCKET/wpbackup/full-application-backup-$NOW.tgz >> $LOGS/$LOG_FILE 2>&1

#echo "Removing local backup file at $BACKUP_PATH/www-backup-$NOW.tgz" >> $LOG_FILE
#sudo rm $BACKUP_PATH/www-backup-$NOW.tgz >> $LOG_FILE 2>&1

# Delete old backups
if [ "$LOCAL_DAYS_TO_KEEP" -gt 0 ] ; then
  echo "Deleting local backups older than $LOCAL_DAYS_TO_KEEP days" >> $LOGS/$LOG_FILE
  find $BACKUP_PATH/*.tgz -mtime +$LOCAL_DAYS_TO_KEEP -exec rm {} \; >> $LOGS/$LOG_FILE 2>&1
fi

echo "Finished backing up to S3 at" >> $LOGS/$LOG_FILE
echo "$BUCKET/full-application-backup-$NOW.tgz" >> $LOGS/$LOG_FILE

