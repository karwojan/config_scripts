DIRECTORY_WITH_BACKUP="/run/media/jan/KARWOWSKI/backup"
BACKUP_FILE_NAME="backup_$(date +%F).tar.gz"
BACKUP_FULL_PATH="${DIRECTORY_WITH_BACKUP}/${BACKUP_FILE_NAME}"
FILES_TO_SAVE="/snapshot_mnt/jan/Dokumenty/ /snapshot_mnt/jan/Muzyka/ /snapshot_mnt/jan/Obrazy/ /snapshot_mnt/jan/Projects/ /snapshot_mnt/jan/config_scripts/"

#check if target directory exists
if test ! -e $DIRECTORY_WITH_BACKUP
then
	echo "Target directory doesn't exist."
	exit 0
fi

#check if copy has been made today
if test -e $BACKUP_FULL_PATH
then
	echo "Copy has been made today."
	exit 0
fi

#------make a backup------

#create snapshot
lvcreate -s -L 2G -n home_snapshot -pr /dev/fedora_karwowski/home

#mount snapshot
mkdir /snapshot_mnt
cd /snapshot_mnt
mount /dev/fedora_karwowski/home_snapshot /snapshot_mnt

#make backup
tar -c --no-check-device -p -z -f $BACKUP_FULL_PATH -g /backup_metadata $FILES_TO_SAVE

#unmount snapshot
umount /snapshot_mnt
rm -r /snapshot_mnt

#remove used snapshot
lvremove -f /dev/fedora_karwowski/home_snapshot
