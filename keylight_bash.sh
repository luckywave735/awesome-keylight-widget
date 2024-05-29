#!/bin/bash

## keylight_bash.sh
# 

declare call='curl --silent --show-error --location --header "Accept: application/json" --request'
declare devices_ctrl="/elgato/lights"
declare accessory_info="/elgato/accessory-info"
declare settings="/elgato/lights/settings"

declare -A lights

parse_params() {
    # default values of variables set from params

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    args=("$@")

    # check required params and arguments
    declare -A actions=([help]=1 [list]=1 [on]=1 [off]=1 [brightness]=1 [temperature]=1 [change_settings_mini]=1 [battery_bypass]=1)
    [[ ${#args[@]} < 1 ]] && die "Incorrect argument count"
    [[ -n "${actions[${args[0]}]}" ]] && action="${args[0]}"

    return 0
}

usage() {
    cat <<EOF
Usage: keylight_bash.sh [-h] <action> args

Elgato Lights controller.

Available actions:
    list                    List available lights
    on                      Turn light on               
    off                     Turn light off              
    temperature             Set temperature level (143-344 which range is between 2900 - 7000k)  
    brightness              Set brightness level (0-100)
    change_settings_mini    Change the settings of Keylight Mini 
    battery_bypass          Set battery bypass of Keylight Mini (Studio Mode)


Available options:

-h, --help               Print this help and exit
EOF
    exit
}


die() {
    echo >&2 -e "${1-}"
    exit "${2-1}"
}

dependencies() {
    for var in "$@"; do
        if ! command -v ${var} &>/dev/null; then
            die "Dependency ${var} was not found, please install and try again"
        fi
    done
}

find_lights() {
    # Scan the network for Elgato devices
    declare -a avahi
    readarray -t avahi < <(avahi-browse -d local _elg._tcp --resolve -t -p | grep -v "^+")

    for l in "${avahi[@]}"; do
        declare ipv4="N/A"
        declare cfg="{}"
        declare url="N/A"
        declare info="{}"
        declare light="{}"

        IFS=';' read -ra data <<<"$l" # split line into array

        # Gather information about the light
        device="${data[3]//\\032/ }"
        port="${data[8]}"
        hostname="${data[6]}"

        ipv4=${data[7]}

        txt=$(eval echo "${data[9]}") # eval to strip quotes
        [[ $txt =~ mf=([^[[:space:]]*]*) ]] && manufacturer=${BASH_REMATCH[1]}
        [[ $txt =~ id=([^[[:space:]]*]*) ]] && mac=${BASH_REMATCH[1]}
        [[ $txt =~ md=.+[[:space:]]([^[[:space:]]*]*)[[:space:]]id= ]] && sku=${BASH_REMATCH[1]}

        url="http://${ipv4}:${port}"

        protocol="--ipv4"

        # Get information from the light
        cfg=$(eval "${call} GET ${protocol} ${url}${settings}") >/dev/null
        info=$(eval "${call} GET ${protocol} ${url}${accessory_info}") >/dev/null
        light=$(eval "${call} GET ${protocol} ${url}${devices_ctrl}") >/dev/null

        # Build json
        json=$(jq -n \
            --arg dev "${device}" \
            --arg hn "${hostname}" \
            --arg ipv4 "${ipv4}" \
            --argjson port "${port}" \
            --arg mf "${manufacturer}" \
            --arg mac "${mac}" \
            --arg sku "${sku}" \
            --arg url "${url}" \
            --argjson cfg "${cfg}" \
            '{device: $dev, manufacturer: $mf, hostname: $hn, url: $url, address: $ipv4,
                port: $port, mac: $mac, sku: $sku, settings: $cfg}')

        # Store the light as json and merge info + light into base object
        lights["${device}"]=$(echo "${info} ${light} ${json}" | jq -s '. | add')
    done
    # Fail if we cannot find lights
    [[ ${#lights[@]} -eq 0 ]] && die "No lights found"

    echo ${lights[@]}
}

on() {
    local address=$1
    local port=$2
    data='{"numberOfLights":1,"lights":[{"on":1}]}'
    # Send command
    eval "${call} PUT -d '${data}' http://${address}:${port}${devices_ctrl}" >/dev/null
}

off() {
    local address=$1
    local port=$2
    data='{"numberOfLights":1,"lights":[{"on":0}]}'
    # Send command
    eval "${call} PUT -d '${data}' http://${address}:${port}${devices_ctrl}" >/dev/null
}

brightness() {
    local address=$1
    local port=$2
    local level=$3
    data='{"numberOfLights":1,"lights":[{"brightness":'"${level}"'}]}'
    # Send command
    eval "${call} PUT -d '${data}' http://${address}:${port}${devices_ctrl}" >/dev/null
}

temperature() {
    # Make sure to convert input from k values with : int(round(987007 * val ** -0.999, 0))
    # Inverse operation can be : int(round(1000000 * val ** -1, -2))
    local address=$1
    local port=$2
    local level=$3
    if [[ $level < 143 ]]; then
        level=143
    elif [[ $level > 344 ]]; then
        level=344
    fi
    data='{"numberOfLights":1,"lights":[{"temperature":'"${level}"'}]}'
    # Send command
    eval "${call} PUT -d '${data}' http://${address}:${port}${devices_ctrl}" >/dev/null
}

change_settings_mini() {
    local address=$1
    local port=$2
    local powerOnBehavior=$3
    local powerOnBrightness=$4
    local powerOnTemperature=$5
    local switchOnDurationMs=$6
    local switchOffDurationMs=$7
    local colorChangeDurationMs=$8
    local esEnable=$9
    local esMinimumBatteryLevel=$10
    local esDisableWifi=$11
    local esAdjustBrightnessEnable=$12
    local esAdjustBrightnessBrightness=$13
    local bypass=$14
    data='{"powerOnBehavior":'"${powerOnBehavior}"',"powerOnBrightness":'"${powerOnBrightness}"',"powerOnTemperature":'"${powerOnTemperature}"',"switchOnDurationMs":'"${switchOnDurationMs}"',"switchOffDurationMs":'"${switchOffDurationMs}"',"colorChangeDurationMs":'"${colorChangeDurationMs}"',"battery":{"energySaving":{"enable":'"${esEnable}"',"minimumBatteryLevel":'"${esMinimumBatteryLevel}"',"disableWifi":'"${esDisableWifi}"',"adjustBrightness":{"enable":'"${esAdjustBrightnessEnable}"',"brightness":'"${esAdjustBrightnessBrightness}"'}},"bypass":'"${bypass}"'}}'
    # Send command
    eval "${call} PUT -d '${data}' http://${address}:${port}${settings}" >/dev/null
}

battery_bypass() {
    local address=$1
    local port=$2
    local state=$3
    data='{"battery":{"bypass":'"${state}"'}}'
    # Send command
    eval "${call} PUT -d '${data}' http://${address}:${port}${settings}" >/dev/null
}

# Quit if script is run by root
[[ "${EUID}" -eq 0 ]] && die "Not allowed to run as root"

# Manage user parameters
parse_params "$@"

# Make sure dependencies are installed
dependencies avahi-browse curl jq

# Dispatch actions
case ${action} in
list) find_lights ;;
on) on $2 $3;;
off) off $2 $3;;
brightness) brightness $2 $3 $4;;
temperature) temperature $2 $3 $4;;
change_settings_mini) change_settings_mini $2 $3 $4 $5  $6 $7 $8 $9 $10 $11 $12 $13 $14;;
battery_bypass) battery_bypass $2 $3 $4;;
-?*) die "Unknown action" ;;
esac