#!/bin/bash
# IBM(c) 2015 EPL license http://www.eclipse.org/legal/epl-v10.html

# Get all disks which are formatted in JOBD functions
jbod_disks=`iprconfig -c show-jbod-disks | grep "^sd[a-z]\+.*Active" | awk '{print $1}' | sort`

# Format all the jbod disk to 'Advanced Function' format
for disk in $jbod_disks; do
    disklist="$disklist $disk"
done
echo "Format disk [$disklist] for Advanced Function to be ready for raid array creating."
`iprconfig -c format-for-raid $disklist`

# Get all available IOAs
ioas=`iprconfig -c show-ioas | grep "^sg[0-9]\+.*Operational" | awk '{print $1}' | sort`

# Exit if there's no available IOA
if [ -z "$ioas" ]; then
    echo "Error: No available IOA found."
    exit 0
fi

for ioa in $ioas; do
    # Figure out all available disks for the IOA
    disks=`iprconfig -c query-raid-create $ioa | grep "^sg[0-9]\+.*Active" | awk '{print $1}'`

    # Create arraies:
    # Create raid0 for each of active disks
    for disk in $disks; do
        # Create a raid 0 for each disk
        echo "Create raid 0 array with device /dev/$disk."
        `iprconfig -c raid-create -r 0 /dev/$disk >/dev/null`
    done
done


# show out the configuration result
output=`iprconfig -c show-config`
echo $output
