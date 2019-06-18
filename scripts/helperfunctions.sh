#!/bin/bash

function get_setup_params {
    local configFile=/usr/local/moodleparams.json

    (dpkg -l jq &> /dev/null) || (apt -y update; apt -y install jq)

    local wait_time_sec=0
    while [ ! -f "$configFile" ]; do
        sleep 15
        let "wait_time_sec += 15"
        if [ "$wait_time_sec" -ge "1800" ]; then
            echo "Error: Cloud-init write-files didn't complete in 30 minutes!"
            return 1
        fi
    done

    local json=$(cat $configFile)
    export siteFQDN=$(echo $json | jq -r .siteProfile.siteURL)
    export mysqlUsername=$(echo $json | jq -r .dbServerProfile.mysqlAdminUsername)
    export mysqlPassword=$(echo $json | jq -r .dbServerProfile.mysqlAdminPassword)
    export mysqlHost=$(echo $json | jq -r .dbServerProfile.dbFQDN)
    export mysqlUsername="$mysqlUsername@$mysqlHost"
}