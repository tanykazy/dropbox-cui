#!/bin/bash

#for debug
#set -x

APP_KEY=""
ACCESS_TOKEN=""

readonly CMD_JQ="jq"
readonly OPT_JQ="--raw-output"

readonly CMD_CURL="curl"
readonly OPT_CURL="--show-error --silent"

readonly CMD_BROWSER="w3m"
readonly OPT_BROWSER="-no-cookie"

which ${CMD_JQ} >/dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo "${CMD_JQ} is not install."
fi
which ${CMD_CURL} >/dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo "${CMD_CURL} is not install."
fi
which ${CMD_BROWSER} >/dev/null 2>&1
if [ "$?" -ne 0 ]; then
    echo "${CMD_BROWSER} is not install."
fi

readonly SCRIPT_NAME=$(basename $0)
readonly SCRIPT_DIR=$(cd $(dirname $0); pwd)
readonly APP_KEY_FILE="${SCRIPT_DIR}/.${SCRIPT_NAME%.*}.app_key"
readonly ACCESS_TOKEN_FILE="${SCRIPT_DIR}/.${SCRIPT_NAME%.*}.access_token"

readonly API_OAUTH2_AUTHORIZE="https://www.dropbox.com/oauth2/authorize"
readonly API_GET_CURRENT_ACCOUNT="https://api.dropboxapi.com/2/users/get_current_account"
readonly API_GET_SPACE_USAGE="https://api.dropboxapi.com/2/users/get_space_usage"
readonly API_DOWNLOAD="https://content.dropboxapi.com/2/files/download"
readonly API_DOWNLOAD_ZIP="https://content.dropboxapi.com/2/files/download_zip"
readonly API_LIST_FOLDER="https://api.dropboxapi.com/2/files/list_folder"
readonly API_LIST_FOLDER_CONTINUE="https://api.dropboxapi.com/2/files/list_folder/continue"
readonly API_MOVE="https://api.dropboxapi.com/2/files/move_v2"
readonly API_SEARCH="https://api.dropboxapi.com/2/files/search_v2"
readonly API_SEARCH_CONTINUE="https://api.dropboxapi.com/2/files/search/continue_v2"
readonly API_DELETE="https://api.dropboxapi.com/2/files/delete_v2"
readonly API_COPY="https://api.dropboxapi.com/2/files/copy_v2"
readonly API_CREATE_FOLDER="https://api.dropboxapi.com/2/files/create_folder_v2"
readonly API_UPLOAD="https://content.dropboxapi.com/2/files/upload"
readonly API_UPLOAD_SESSION_START="https://content.dropboxapi.com/2/files/upload_session/start"
readonly API_UPLOAD_SESSION_APPEND="https://content.dropboxapi.com/2/files/upload_session/append_v2"
readonly API_UPLOAD_SESSION_FINISH="https://content.dropboxapi.com/2/files/upload_session/finish"
readonly API_SAVE_URL="https://api.dropboxapi.com/2/files/save_url"
readonly API_SAVE_URL_CHECK_JOB_STATUS="https://api.dropboxapi.com/2/files/save_url/check_job_status"
readonly API_GET_METADATA="https://api.dropboxapi.com/2/files/get_metadata"
readonly API_GET_TEMPORARY_LINK="https://api.dropboxapi.com/2/files/get_temporary_link"
readonly API_GET_TEMPORARY_UPLOAD_LINK="https://api.dropboxapi.com/2/files/get_temporary_upload_link"

COMMAND=""
ARGUMENTS=()

function parse(){
    ${CMD_JQ} ${OPT_JQ} "$2" <<< "$1"
}

function authorize(){
    if [ -e ${APP_KEY_FILE} ]; then
        APP_KEY=$( <${APP_KEY_FILE})
    else
        read -p "Input key:" APP_KEY
        if [ -n ${APP_KEY} ]; then
            echo ${APP_KEY} >${APP_KEY_FILE}
        fi
    fi
    if [ -e ${ACCESS_TOKEN_FILE} ]; then
        ACCESS_TOKEN=$( <${ACCESS_TOKEN_FILE})
    else
        ${CMD_BROWSER} ${OPT_BROWSER} "${API_OAUTH2_AUTHORIZE}?client_id=${APP_KEY}&response_type=code"
        read -p "Input code:" ACCESS_TOKEN
        if [ -n ${ACCESS_TOKEN} ]; then
            echo ${ACCESS_TOKEN} >${ACCESS_TOKEN_FILE}
        fi
    fi
}

function _get_current_account(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_GET_CURRENT_ACCOUNT} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}"
}

function _get_space_usage(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_GET_SPACE_USAGE} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}"
}

function _download(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_DOWNLOAD} \
        --output "$2" \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Dropbox-API-Arg: {\"path\": \"$1\"}"
}

function _download_zip(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_DOWNLOAD_ZIP} \
        --output "$2" \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Dropbox-API-Arg: {\"path\": \"$1\"}"
}

function _list_folder(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_LIST_FOLDER} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"path\": \"$1\",
            \"recursive\": false,
            \"include_media_info\": false,
            \"include_deleted\": false,
            \"include_has_explicit_shared_members\": false,
            \"include_mounted_folders\": true,
            \"include_non_downloadable_files\": true}"
}

function _list_folder_continue(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_LIST_FOLDER_CONTINUE} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{\"cursor\": \"$1\"}"
}

function _move(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_MOVE} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"from_path\": \"$1\",
            \"to_path\": \"$2\",
            \"allow_shared_folder\": false,
            \"autorename\": false,
            \"allow_ownership_transfer\": false}"
}

function _search(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_SEARCH} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"query\": \"$1\",
            \"include_highlights\": false}"
}

function _search_continue(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_SEARCH_CONTINUE} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{\"cursor\": \"$1\"}"
}

function _delete(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_DELETE} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{\"path\": \"$1\"}"
}

function _copy(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_COPY} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"from_path\": \"$1\",
            \"to_path\": \"$2\",
            \"allow_shared_folder\": false,
            \"autorename\": false,
            \"allow_ownership_transfer\": false}"
}

function _create_folder(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_CREATE_FOLDER} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"path\": \"$1\",
            \"autorename\": false}"
}

function _upload(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_UPLOAD} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Dropbox-API-Arg: {
            \"path\": \"$2\",
            \"mode\": \"add\",
            \"autorename\": true,
            \"mute\": false,
            \"strict_conflict\": false}" \
        --header "Content-Type: application/octet-stream" \
        --data-binary @"$1"
}

function _upload_session_start(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_UPLOAD_SESSION_START} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Dropbox-API-Arg: {\"close\": false}" \
        --header "Content-Type: application/octet-stream" \
        --data-binary @"$1"
}

function _upload_session_append(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_UPLOAD_SESSION_APPEND} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Dropbox-API-Arg: {
            \"cursor\": {
                \"session_id\": \"$2\",
                \"offset\": $3},
            \"close\": false}" \
        --header "Content-Type: application/octet-stream" \
        --data-binary @"$1"
}

function _upload_session_finish(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_UPLOAD_SESSION_FINISH} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Dropbox-API-Arg: {
            \"cursor\": {
                \"session_id\": \"$2\",
                \"offset\": $3},
            \"commit\": {
                \"path\": \"$4\",
                \"mode\": \"add\",
                \"autorename\": true,
                \"mute\": false,
                \"strict_conflict\": false}}" \
        --header "Content-Type: application/octet-stream" \
        --data-binary @"$1"
}

function _save_url(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_SAVE_URL} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"path\": \"$2\",
            \"url\": \"$1\"}"
}

function _save_url_check_job_status(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_SAVE_URL_CHECK_JOB_STATUS} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{\"async_job_id\": \"$1\"}"
}

function _get_metadata(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_GET_METADATA} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"path\": \"$1\",
            \"include_media_info\": false,
            \"include_deleted\": false,
            \"include_has_explicit_shared_members\": false}"
}

function _get_temporary_link(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_GET_TEMPORARY_LINK} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{\"path\": \"$1\"}"
}

function _get_temporary_upload_link(){
    ${CMD_CURL} ${OPT_CURL} -X POST ${API_GET_TEMPORARY_UPLOAD_LINK} \
        --header "Authorization: Bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data "{
            \"commit_info\": {
                \"path\": \"$1\",
                \"mode\": \"add\",
                \"autorename\": true,
                \"mute\": false,
                \"strict_conflict\": false},
            \"duration\": 3600}"
}

function current_account(){
    local RESULT
    local DISPLAY_NAME
    local EMAIL
    RESULT=$(_get_current_account)
    DISPLAY_NAME=$(parse "${RESULT}" ".name.display_name")
    EMAIL=$(parse "${RESULT}" ".email")
    echo "Name: ${DISPLAY_NAME}"
    echo "Email: ${EMAIL}"
}

function space_usage(){
    local RESULT
    local USED
    local ALLOCATED
    RESULT=$(_get_space_usage)
    USED=$(parse "${RESULT}" ".used")
    ALLOCATED=$(parse "${RESULT}" ".allocation | .allocated")
    echo "Space usage: ${USED}/${ALLOCATED}"
}

function find(){
    local RESULT
    RESULT=$(_search "$*")
    parse "${RESULT}" ".matches[].metadata.metadata.path_display"
    while [ $(parse "${RESULT}" ".has_more") = "true" ]
    do
        RESULT=$(_search_continue $(parse "${RESULT}" ".cursor"))
        parse "${RESULT}" ".matches[].metadata.metadata.path_display"
    done
}

function list(){
    local RESULT
    local ENTRIES
    local INDEX
    RESULT=$(_list_folder "$*")
    ENTRIES=$(parse "${RESULT}" ".entries | length")
    INDEX=0
    while (( INDEX < ENTRIES ))
    do
        case $(parse "${RESULT}" ".entries[${INDEX}].\".tag\"") in
            "file" | "folder" | "deleted" )
                parse "${RESULT}" ".entries[${INDEX}].path_display"
                ;;
            *)
                parse "${RESULT}" ".entries[${INDEX}]"
                ;;
        esac
        (( INDEX++ ))
    done
    while [ $(parse "${RESULT}" ".has_more") = "true" ]
    do
        RESULT=$(_list_folder_continue $(parse "${RESULT}" ".cursor"))
        ENTRIES=$(parse "${RESULT}" ".entries | length")
        INDEX=0
        while (( INDEX < ENTRIES ))
        do
            case $(parse "${RESULT}" ".entries[${INDEX}].\".tag\"") in
                "file" | "folder" | "deleted" )
                    parse "${RESULT}" ".entries[${INDEX}].path_display"
                    ;;
                *)
                    parse "${RESULT}" ".entries[${INDEX}]"
                    ;;
            esac
            (( INDEX++ ))
        done
    done
}

function save(){
    local RESULT
    local TAG
    local ASYNC_JOB_ID
    local PATH_DISPLAY
    local SIZE
    if [ -z $1 ] || [ -z $2 ]; then
        echo "usage: $0 save URL PATH"
        return
    fi
#    if [[　! $2 =~ /(.|[\r\n])* ]]; then
#        echo "not match!!"
#    fi
    RESULT=$(_save_url "$1" "$2")
    TAG=$(parse "${RESULT}" ".\".tag\"")
    if [ ${TAG} = "async_job_id" ]; then
        ASYNC_JOB_ID=$(parse "${RESULT}" ".${TAG}")
        while :
        do
            RESULT=$(_save_url_check_job_status "${ASYNC_JOB_ID}")
            case $(parse "${RESULT}" ".\".tag\"") in
                "in_progress")
                    sleep 1s
                    continue
                    ;;
                "complete")
                    PATH_DISPLAY=$(parse "${RESULT}" ".path_display")
                    SIZE=$(parse "${RESULT}" ".size")
                    echo "Save URL to \""${PATH_DISPLAY}\"" ${SIZE}bytes"
                    break
                    ;;
                "failed")
                    parse "${RESULT}" "."
                    break
                    ;;
                *)
                    parse "${RESULT}" "."
                    break
                    ;;
            esac
        done
    elif [ ${TAG} = "complete" ]; then
        PATH_DISPLAY=$(parse "${RESULT}" ".path_display")
        SIZE=$(parse "${RESULT}" ".size")
        echo "Save URL to \""${PATH_DISPLAY}\"" ${SIZE}bytes"
    else
        parse "${RESULT}" "."
        return 1
    fi
}

function delete(){
    local RESULT
    local TAG
    local PATH_DISPLAY
    RESULT=$(_delete "$*")
    TAG=$(parse "${RESULT}" ".metadata.\".tag\"")
    case "${TAG}" in
        "file" | "folder" | "deleted")
            PATH_DISPLAY=$(parse "${RESULT}" ".metadata.path_display")
            echo "Delete ${TAG}:\"${PATH_DISPLAY}\""
            ;;
        *)
            parse "${RESULT}" "."
            ;;
    esac
}

function create_folder(){
    local RESULT
    RESULT=$(_create_folder "$*")
    if [ $(parse "${RESULT}" "has(\"error\")") = "true" ]; then
        parse "${RESULT}" "."
        return 1
    fi
    parse "${RESULT}" ".metadata.path_display"
}

function move(){
    local RESULT
    RESULT=$(_move "$1" "$2")
    if [ $(parse "${RESULT}" "has(\"error\")") = "true" ]; then
        parse "${RESULT}" "."
        return 1
    fi
}

function copy(){
    local RESULT
    RESULT=$(_copy "$1" "$2")
    if [ $(parse "${RESULT}" "has(\"error\")") = "true" ]; then
        parse "${RESULT}" "."
        return 1
    fi
}

function download(){
    local RESULT
    RESULT=$(_get_metadata "$1")
    case $(parse "${RESULT}" ".\".tag\"") in
        "file")
            RESULT=$(_download "$1" "$2")
            ;;
        "folder")
            RESULT=$(_download_zip "$1" "$2")
            ;;
        *)
            parse "${RESULT}" "."
            ;;
    esac
#    if [ $(check_error "${RESULT}") ]; then
#        parse "${RESULT}" "."
#        return 1
#    fi
#    parse "${RESULT}" "."
#    echo -n "${RESULT}" >"$2"
}

while (( $# > 0 ))
do
    case "$1" in
        -*)
            if [[ "$1" =~ 'n' ]]; then
                nflag='-n'
            fi
            if [[ "$1" =~ 'l' ]]; then
                lflag='-l'
            fi
            if [[ "$1" =~ 'p' ]]; then
                pflag='-p'
            fi
            shift
            ;;
        *)
            ARGUMENTS+=("$1")
            shift
            ;;
    esac
done

COMMAND="${ARGUMENTS[0]}"
ARGUMENTS=("${ARGUMENTS[@]:1}")

echo "Command: ${COMMAND}"
echo "Arguments: ${ARGUMENTS[@]}"

if [ -z ${COMMAND} ]; then
    exit 0
fi

authorize

case "${COMMAND}" in
    "account")
        current_account
        ;;
    "space")
        space_usage
        ;;
    "find")
        find ${ARGUMENTS[@]}
        ;;
    "list")
        list ${ARGUMENTS[@]}
        ;;
    "move")
        move ${ARGUMENTS[@]}
        ;;
    "copy")
        copy ${ARGUMENTS[@]}
        ;;
    "download")
        download ${ARGUMENTS[@]}
        ;;
    "upload")
        :${ARGUMENTS[@]}
        ;;
    "save")
        save ${ARGUMENTS[@]}
        ;;
    "mkdir")
        create_folder ${ARGUMENTS[@]}
        ;;
    "delete")
        delete ${ARGUMENTS[@]}
        ;;
    *)
        ;;
esac

