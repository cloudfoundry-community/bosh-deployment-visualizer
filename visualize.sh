#!/bin/bash

#spruce json pcf.yml | jq -r '.instance_groups | map(select(.instances != 0)) | map({name: .name, instances: .instances, azs: (.azs | length), type: .vm_type, jobs: (.jobs | map(.name))})'

# https://www.planttext.com/

echo -e "@startuml\n"

manifest=${1}

manifest() {
    spruce json ${manifest}
}

id_escape() {
    sed 's/-/_/g'
}

for network in $(manifest | jq -r '.instance_groups | map(.networks[].name) | flatten | unique | .[]'); do
    id="$(echo $network | id_escape)"
    echo -e "\
        cloud ${id} [
    <b>network: ${network}
    ]\n" | sed 's/^[ ]*/  /g'
done

for az in $(manifest | jq -r '.instance_groups | map(.azs) | flatten | unique | .[]'); do
    echo "frame $az {"
    groups=$(manifest | jq -c --arg az $az '.instance_groups | map(select((.instances != 0) and (.azs | contains([$az])))) | map(@base64) | _nwise(3)')
    last_group_link_name=""
    for group in $(echo "$groups"); do
        echo "together {"
        for instance in $(echo "$group" | jq -c -r '.[]'); do
            _jq() {
                echo "${instance}" | base64 --decode | jq -r "$@"
            }
            id="$(_jq '.name' | id_escape)_$az"
            name=$(_jq '.name')
            jobs=$(_jq '.jobs | map(.name) | join("\n")')
            iazs=$(_jq -c '. as $ig | [$ig.azs, ([[range(0;$ig.instances)] | _nwise($ig.instances / ($ig.azs | length) | ceil)] | map(length))] | transpose')
            instances=$(echo $iazs | jq -r --arg az $az 'map(select(.[0] == $az))[0][1] // 0')

            echo -e "\
            node ${id} [
            <b>${name} ${instances}
            ----
            ${jobs}
            ]\n" | sed 's/^[ ]*/  /g'
            # echo "$id -0- default_$az"
            for network in $(_jq '.networks[].name'); do
                nid=$(echo $network | id_escape)
                echo "$id -0- $nid"
            done
        done
        last_group_current_name="$(echo "$group" | jq -r '.[0]' | base64 --decode | jq -r '.name' | id_escape)_$az"
        if [ "${last_group_last_name}" != "" ]; then
            echo "${last_group_last_name} -[hidden]---> ${last_group_current_name}"
        fi
        last_group_last_name="${last_group_current_name}"

        echo "}" # close together
    done
    echo "}" # close az frame
done

# echo "z1 -[hidden]----> z2"
# echo "z2 -[hidden]----> z3"
# echo "default_z1 -0- default_z2"
# echo "default_z1 -0- default_z3"
# echo "default_z2 -0- default_z1"
# echo "default_z2 -0- default_z3"
# echo "default_z3 -0- default_z1"
# echo "default_z3 -0- default_z2"
echo "@enduml"
