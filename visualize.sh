#!/bin/bash

#spruce json pcf.yml | jq -r '.instance_groups | map(select(.instances != 0)) | map({name: .name, instances: .instances, azs: (.azs | length), type: .vm_type, jobs: (.jobs | map(.name))})'

# https://www.planttext.com/

manifest=${1}
uml=""

manifest() {
    spruce json ${manifest}
}

id_escape() {
    sed 's/-/_/g'
}

uml() {
    uml="${uml}\n${1}"
}

deployment=$(manifest | jq -r '.name')

uml "@startuml\n"

uml "center header
= Deployment: $deployment
endheader\n"

for az in $(manifest | jq -r '.instance_groups | map(.azs) | flatten | unique | .[]'); do
    uml "frame $az {"
    groups=$(manifest | jq -c --arg az $az '.instance_groups | map(select((.instances != 0) and (.azs | contains([$az])))) | map(@base64) | _nwise(3)')
    last_group_link_name=""
    for group in $(echo "$groups"); do
        uml "together {"
        for instance in $(echo "$group" | jq -c -r '.[]'); do
            _jq() {
                echo "${instance}" | base64 --decode | jq -r "$@"
            }
            id="$(_jq '.name' | id_escape)_$az"
            name=$(_jq '.name')
            jobs=$(_jq '.jobs | map("|_ \(.name)") | join("\n")')
            networks=$(_jq '.networks | map("<&cloud> \(.name)") | join("\n")')
            type=$(_jq '.vm_type')
            iazs=$(_jq -c '. as $ig | [$ig.azs, ([[range(0;$ig.instances)] | _nwise($ig.instances / ($ig.azs | length) | ceil)] | map(length))] | transpose')
            instances=$(echo $iazs | jq -r --arg az $az 'map(select(.[0] == $az))[0][1] // 0')

            uml "\
            node ${id} [
            **${name}** ${type} <&x> ${instances}
            ${jobs}

            ----
            ${networks}
            ]\n"
        done
        last_group_current_name="$(echo "$group" | jq -r '.[0]' | base64 --decode | jq -r '.name' | id_escape)_$az"
        if [ "${last_group_last_name}" != "" ]; then
            uml "${last_group_last_name} -[hidden]- ${last_group_current_name}"
        fi
        last_group_last_name="${last_group_current_name}"

        uml "}" # close together
    done
    last_group_last_name=""
    uml "}" # close az frame
done

uml "@enduml"

if [[ ! -z "$DEBUG" ]]; then
    echo -e "${uml}"
fi

echo -e "${uml}" | plantuml -p > "${deployment}.png"
echo "Generated $(pwd)/${deployment}.png"
