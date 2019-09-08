#!/usr/bin/env bash

# droplet.sh - get info about or create a droplet with Vagrant & Ansible

# author  : Chad Mayfield (chad@chd.my)
# license : gplv3

if [ ! $# -ge 1 ]; then
    echo "ERROR: You must supply an argument! <get|create|help>"
    exit 1
fi

avail_regions=
avail_sizes=
avail_distros=

fail() {
    echo -e "ERROR:" "$@"
    exit 1
}

check_curl() {
    command -v curl >/dev/null 2>&1 || fail "curl is not installed! (Get started: https://curl.haxx.se)"
}

check_jq() {
    command -v jq >/dev/null 2>&1 || fail "jq is not installed! (Get started: https://stedolan.github.io/jq/)"
}

check_vagrant() {
    command -v vagrant >/dev/null 2>&1 || fail "vagrant is not installed! (Get started: https://www.vagrantup.com)"
}

check_key() {
    # for security use API key set as env variable in .bashrc
    if [ -z ${DO_KEY+x} ]; then
        fail "A DigitalOcean API key must be set as \$DO_KEY in your .bashrc!";
    fi
}

check_ssh_configd() {
    ssh_config="${HOME}/.ssh/config"
    directory="${HOME}/.ssh/config.d"
    configlet="${HOME}/.ssh/config.d/digitalocean"

    if [ ! -e "$ssh_config" ]; then
        printf "ERROR: You aren't using a %s!\n" "$ssh_config"
        fail "Please create one, run man 5 ssh_config for reference."
    fi

    if [ "$(grep -c "Include config.d" "$ssh_config")" -eq 0 ]; then
        printf "ERROR: config.d is not enabled in %s!\n" "$ssh_config"
        fail "You must enable it to proceed. See man 5 ssh_config for details."
    fi

    if [ -f "$configlet" ]; then
        # check if we need to remove old settings
        :
    fi
}

check_deps_get() {
    check_curl
    check_jq
    check_vagrant
    check_key
}

check_deps_create() {
    check_deps_get
    check_ssh_configd
}

# TODO: Fix these, they don't work properly
check_args() {
    # check that we have an available region
    get_available_regions
    if [ -z "${region}+x" ]; then
        region="sfo2"
        printf "No region specified, using default: %s\n" "$region"
    else
        if ! [[ $region =~ $avail_regions ]]; then
            fail "Region '$region' is not available or invalid!"
        fi
    fi

    # check that we have an available size in $region
    get_available_sizes
    if [ -z "${size}+x" ]; then
        size="s-1vcpu-1gb"
        printf "No size specified, using default: %s\n" "$size"
    else
        if ! [[ $region =~ $avail_sizes ]]; then
            fail "Size '$size' is invalid or not available in region $region!"
        fi
    fi

    # check that we have a distro (not community)
    if [ -z "${distro}+x" ]; then
        distro="ubuntu-18-04-x64"
        printf "No size specified, using default: %s\n" "$distro"
    else
        if ! [[ $distro =~ x64|x32|stable|beta|alpha|rancher ]]; then
            fail "Distro $distro is invalid! Check for valid distro using: $0 get distros"
        fi
    fi

    # check that we have a machine name
    if [ -z "${name}+x" ]; then
        name="test-vps1"
        printf "No size specified, using default: %s\n" "$name"
    else
#        if ! [[ $name =~ ^[a-zA-Z0-9-_]+$ ]]; then
        # TODO: improve regexp
        if ! [[ $name =~ ^[[:alnum:]]+$ ]]; then
            fail "Name $name invalid! Please use only letters, numbers, dash, & underscores."
        fi
    fi
}

create_vps() {
    machine="${region}-${size}-$(date "+%Y%m%d-%H%M")"
    vagrantfile="deployments/${machine}/Vagrantfile"

    printf "Deploying machine: %s\n" "$machine"

    # make sure we don't kill another deployment
    if [ -d "$machine" ]; then
        fail "Directory $machine already exists in ./deployments!"
    else
        cp -R ./skeleton ./deployments/"${machine}"
    fi

    # modify Vagrantfile with user vars
    sed -i -e "s/DROPLET_REGION/${region}/g" "$vagrantfile" || fail "Unable update region!"
    sed -i -e "s/DROPLET_SIZE/${size}/g" "$vagrantfile" || fail "Unable to update size!"
    sed -i -e "s/DROPLET_DISTRO/${distro}/g" "$vagrantfile" || fail "Unable to update distro!"
    sed -i -e "s/DROPLET_NAME/${name}/g" "$vagrantfile" || fail "Unable to update name!"
    rm -f "${vagrantfile}-e"

    #run the machine
    cwd="$(pwd)"
    cd "./deployments/${machine}/" || fail "Change directory failed!"
    vagrant --provider=digitalocean up || fail "Vagrant up failed!"
    cd "$cwd" || fail "Failed to change directory to $cwd"
}

add_ssh_config() {
    directory="${HOME}/.ssh/config.d"
    if [ ! -d "$directory" ]; then
        printf "Directory %s not found, creating it.\n" "$directory"
        mkdir -p "$directory"
    fi

    cwd="$(pwd)"
    cd "./deployments/${machine}/" || fail "Change directory failed!"
    vagrant ssh-config >> "${directory}/digitalocean"
    cd "$cwd" || fail "Failed to change directory to $cwd"
}

get_available_regions() {
    # https://developers.digitalocean.com/documentation/v2/#regions
    url_regions="https://api.digitalocean.com/v2/regions?page=1&per_page=999"

    avail_regions="$(curl -s -H "Authorization: Bearer ${DO_KEY}" "$url_regions" | \
                    jq -r '.regions[].slug' 2>&1 | tr '\r\n' '|')"
    avail_regions="${avail_regions%?}"
}

get_regions() {
    # https://developers.digitalocean.com/documentation/v2/#regions
    url_regions="https://api.digitalocean.com/v2/regions?page=1&per_page=999"

    # compat for ancient version of bash on macOS
    list=()
    while IFS= read -r line; do
        list+=( "$line" )
    done < <( curl -s -H "Authorization: Bearer ${DO_KEY}" "$url_regions" | \
            jq '.regions[] | "\(.slug)|\(.name)"' | sort )

    # for newer versions of bash (v4.2+)
    #mapfile -t regions < <( curl -H "Authorization: Bearer ${DO_KEY}" $url_regions | \
    #                        jq '.regions[] | "\(.slug)|\(.name)"' | sort )

    printf "==========================\n"
    printf "%15s  ||  %4s\n" "ACTIVE LOCATION" "SLUG"
    printf "==========================\n"

    for i in "${list[@]}"
    do
        # stip quotes
        i=$(sed -e 's/^"//' -e 's/"$//' <<<"$i")
        # strip prefix/suffix
        printf "%15s  =>  %4s\n" "${i#*|}" "${i%%|*}"
    done
}

get_available_sizes() {
    # https://developers.digitalocean.com/documentation/v2/#sizes
    url_sizes="https://api.digitalocean.com/v2/sizes?page=1&per_page=999"

    avail_sizes="$(curl -s -H "Authorization: Bearer ${DO_KEY}" "$url_sizes" | \
                jq -c --arg size $size '.sizes[] | select(.available==true) | select(.slug == $size) | .regions' 2>&1 | \
                sed 's/[]"[]//g' | sed 's/,/|/g')"
}

get_sizes() {
    # https://developers.digitalocean.com/documentation/v2/#sizes
    url_sizes="https://api.digitalocean.com/v2/sizes?page=1&per_page=999"

    # compat for ancient version of bash on macOS
    list=()
    while IFS= read -r line; do
        list+=( "$line" )
    done < <(curl -s -H "Authorization: Bearer ${DO_KEY}" "$url_sizes" | \
            jq '.sizes[] | "\(.slug)|\(.memory)|\(.vcpus)|\(.disk)|\(.transfer)|\(.price_monthly)"')
            #jq --arg region $region .regions[] | select(.available==true) | select(.slug == $region) | .sizes

    # for newer versions of bash (v4.2+)
    #mapfile -t slist < <( curl -s -H "Authorization: Bearer ${DO_KEY}" "$url_sizes" | \
    #                      jq '.sizes[] | "\(.slug)|\(.memory)|\(.vcpus)|\(.disk)|\(.transfer)|\(.price_monthly)"')

    printf "=======================================================================\n"
    printf "%15s : %5s %9s %11s %10s %14s\n" "DROPLET SLUG" "CPU" "MEM" "STORAGE" "BANDWIDTH" "PRICE"
    printf "=======================================================================\n"

    for i in "${list[@]}"
    do
        # stip quotes
        i=$(sed -e 's/^"//' -e 's/"$//' <<<"$i")
        read -r plug mem vcpus disk trans price <<< "$(echo "$i" | awk -F "|" '{ print $1, $2, $3, $4, $5, $6 }')"
        printf "%15s : %2scpu %7sMB %5sGB SSD %3sTB Xfer %6s/monthly\n" "$plug" "$vcpus" "$mem" "$disk" "$trans" "\$$price"
    done
}

get_distros() {
    # https://developers.digitalocean.com/documentation/v2/#list-all-distribution-images
    url_distros="https://api.digitalocean.com/v2/images?page=1&per_page=999&type=distribution"

    printf "==============================================\n"
    printf " %26s  ||  %4s\n" "DISTRIBUTION NAME/VERSION" "SLUG"
    printf "==============================================\n"

    # compat for ancient version of bash on macOS
    list=()
    while IFS= read -r line; do
        list+=( "$line" )
    done < <( curl -s -H "Authorization: Bearer ${DO_KEY}" "$url_distros" | \
            jq '.images[] | "\(.distribution) \(.name)|\(.slug)"' | sort )

    # for newer versions of bash (v4.2+)
    #mapfile -t list < <( curl -H "Authorization: Bearer ${DO_KEY}" $url_distros | \
    #                     jq '.images[] | "\(.distribution) \(.name)|\(.slug)"' | sort )

    for i in "${list[@]}"
    do
        # stip quotes
        i=$(sed -e 's/^"//' -e 's/"$//' <<<"$i")
        # strip prefix/suffix
        printf "%27s  =>  %s\n" "${i%%|*}" "${i#*|}"
    done
}

case $1 in
    get)
        case $2 in
            help|--help|-h|--h|-h)
                echo "Help comming soon!"
                ;;
            regions)
                check_deps_get
                get_regions
                ;;
            sizes)
                check_deps_get
                get_sizes
                ;;
            distros)
                check_deps_get
                get_distros
                ;;
            *)
                fail "You must supply a valid argument! $0 get <regions|sizes|distros>"
                ;;
        esac
        ;;
    create)
        case $2 in
            help|--help|-h|--h|-h)
                echo "Help comming soon!"
                ;;
            *)
                region="$2"
                size="$3"
                distro="$4"
                name="$5"

                check_deps_create
                check_args
                create_vps
                add_ssh_config
                ;;
        esac
        ;;
    help|--help|-h|--h|-h)
        echo "Help comming soon!"
        ;;
    *)
        fail "You must supply an argument! <get|create|help>"
        ;;
esac

#EOF
