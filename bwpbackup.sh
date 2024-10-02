#!/usr/bin/env bash
#	bwpbackup.sh Backup Script
#
# Bash script to backup Bitnami for Wordpress stacks
#
# Configure user options in the included `.config` file.
#
# To setup CRON
# add the next line to crontab of root user to run every day at 3:30am
# 30 3 * * * /path/to/bwpbackup.sh >> /path/to/logs/bwpbackup_cron.log 2>&1
#
#
############################# options #########################################
#
# Please edit all USER OPTIONS in the `.config` file first
#
######################## script happens below #################################
# Load configurations
CONFIG_FILE=".config"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file does not exist."
  exit 1
fi
source "$CONFIG_FILE"

# Function to log messages
log() {
  echo "$(date +'%Y-%m-%dT%H:%M:%S') - $@" >>"${logs}/$log_file"
}

# Function to check command availability
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if the script is running with necessary privileges
if [ "$EUID" -ne 0 ] && ! sudo -v; then
  log "This script must be run as root or with sudo privileges."
  exit 1
fi

# Check required commands
for cmd in tar aws; do
  if ! command_exists $cmd; then
    echo "Error: $cmd is not installed." >&2
    exit 1
  fi
done

# Directory change
cd "$work_dir" || {
  log "Failed to change to working directory \"$work_dir\""
  exit 1
}

# Create the backup directory if it doesn't exist
if [ ! -d "$backup_dir" ]; then
  mkdir -p "$backup_dir" || {
    log "Failed to create backup directory \"$backup_dir\""
    exit 1
  }
fi

# Create logs directory and file
logs="${backup_dir}/logs"
mkdir -p "$logs" || {
  log "Failed to create logs directory \"$logs\""
  exit 1
}
touch "${logs}/${log_file}"

# Stop all services
log "Stopping Services"
/opt/bitnami/ctlscript.sh stop 2>&1 | log

# Compress entire directory
log "Creating backup..."
tar -pczf "${backup_dir}/full-application-backup-${today}.tgz" /opt/bitnami 2>&1 | log

# Restart all services
log "Starting Services"
/opt/bitnami/ctlscript.sh start 2>&1 | log

log "Backup complete at ${backup_dir}/full-application-backup-${today}.tgz"

# Move to S3
log "Moving backup file to S3 bucket"
aws s3 cp "${backup_dir}/full-application-backup-${today}.tgz" "$s3_bucket/wpbackup/full-application-backup-${today}.tgz" 2>&1 | log

# Delete old backups
if [ "$local_days_to_keep" -gt 0 ]; then
  log "Deleting local backups older than $local_days_to_keep days"
  find "$backup_dir"/*.tgz -mtime +$local_days_to_keep -exec rm {} \; 2>&1 | log
fi

log "Finished backing up to S3 at $s3_bucket/wpbackup/full-application-backup-${today}.tgz"
