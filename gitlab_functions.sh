#!/bin/bash

die () {
    echo >&2 "$@"
    exit 1
}

dpkg -s jq &>/dev/null || die "install jq!"
dpkg -s curl &>/dev/null || die "install curl!"

#
# getRunnerIdByDescription "description" "https://gitlab.com/" "token"
#
# $1 is description
# $2 is url of gitlab instance ie: https://gitlab.com/
# $3 is private token with admin privilages
getRunnerIdByDescription() {
    DESCRIPTION=$1
    CI_SERVER_URL=$2
    PRIVATE_TOKEN=$3
    ENDPOINT=$(echo "$CI_SERVER_URL/api/v4" | sed "s/\\/\\/api/\\/api/g")
    RUNNERS=$(curl -s --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$ENDPOINT/runners")
    RUNNER_ID=$(jq '.[] | select(.description == "'"$DESCRIPTION"'") | .id' <<< "$RUNNERS")
    
    if [ "$RUNNER_ID" == "" ] 
    then
        die "runner not found!"
    fi

    echo "$RUNNER_ID"
}


#
# registerRunnerToProject "runner_id" "project_id" "https://gitlab.com/" "token"
#
# $1 is runner id
# $2 is project id
# $3 is url of gitlab instance ie: https://gitlab.com/
# $4 is private token with admin privilages
registerRunnerToProject() {
    RUNNER_ID=$1
    PROJECT=$2
    CI_SERVER_URL=$3
    PRIVATE_TOKEN=$4
    ENDPOINT=$(echo "$CI_SERVER_URL/api/v4" | sed "s/\\/\\/api/\\/api/g")

    echo "registering runner $RUNNER_ID to [$PROJECT]"
    RSP=$(curl -s --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$ENDPOINT/projects/$PROJECT/runners" --form "runner_id=$RUNNER_ID")
    echo "rsp: $(jq . <<< "$RSP")"
    echo ""
}

# $1 is runner id
# $2 is url of gitlab instance ie: https://gitlab.com/
# $3 is private token with admin privilages
removeRunner(){
    RUNNER=$1
    CI_SERVER_URL=$2
    PRIVATE_TOKEN=$3
    ENDPOINT=$(echo "$CI_SERVER_URL/api/v4" | sed "s/\\/\\/api/\\/api/g")

    echo "registering runner $RUNNER_ID to [$PROJECT_ID]"
    curl -s --request DELETE --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$ENDPOINT/runners/$RUNNER"
    echo "finished..."
}
