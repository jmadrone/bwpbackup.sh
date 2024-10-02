#!/usr/bin/env bash

# Backup WordPress and all associated files and databases for Bitnami installations.

# Load configurations
CONFIG_FILE=".config"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file does not exist."
  exit 1
fi
source $CONFIG_FILE

# Function to log messages
log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $@"
}

# Check if the script is running with necessary privileges
if [ "$EUID" -ne 0 ] && ! sudo -v; then
  log "This script must be run as root or with sudo privileges."
  exit 1
fi

# Check if necessary binaries exist
for cmd in tar aws; do
  if ! command -v $cmd >/dev/null; then
    log "Error: $cmd is not installed."
    exit 1
  fi
done

# Change to working directory
if ! cd "$work_dir"; then
  log "Error: Failed to change directory to $work_dir."
  exit 1
fi

# Create the backup folder
if [ ! -d "$backup_dir" ]; then
  if ! mkdir -p "$backup_dir"; then
    log "Error: Failed to create backup directory $backup_dir."
    exit 1
  fi
fi

# Backup process
log "Stopping services..."
sudo /opt/bitnami/ctlscript.sh stop

log "Compressing directory /opt/bitnami"
if ! sudo tar -pczvf "$backup_dir/www-backup-$today.tgz" /opt/bitnami; then
  log "Error: Failed to compress directory."
  sudo /opt/bitnami/ctlscript.sh start
  exit 1
fi

log "Starting services..."
sudo /opt/bitnami/ctlscript.sh start

log "Backup completed: $backup_dir/www-backup-$today.tgz"

# Move to S3
log "Moving backup to S3 bucket: $s3_bucket/www-backup-$today.tgz"
if /usr/bin/aws s3 cp "$backup_dir/www-backup-$today.tgz" "$s3_bucket/www-backup-$today.tgz"; then
  log "Backup successfully moved to S3."
  sudo rm "$backup_dir/www-backup-$today.tgz"
else
  log "Error: Failed to move backup to S3."
fi

log "Finished full backup process."
