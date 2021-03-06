#!/bin/bash
# Run script within the directory
BINDIR=$(dirname "$(readlink -fn "$0")")
cd "$BINDIR"

. ./mastercomfig-vars

# Get old release version
old_release=$(curl https://api.github.com/repositories/69422496/releases/latest)
old_release=$(echo $old_release | jq '.tag_name' | sed -e 's/^"//' -e 's/"$//')

# Create release
assets_url=$(curl -u $GH_USERNAME:$GH_TOKEN -X POST -H 'Content-type: application/json' \
  --data "{\"tag_name\":\"$1\",\"target_commitish\":\"release\",\"name\":\"$1\",\"body\":\"**Highlights:** $2\n\n[Support me](https://docs.mastercomfig.com/en/latest/support_me/)\n\n[**How to install**](https://docs.mastercomfig.com/en/$1/setup/install/)\n\n[**How to update**](https://docs.mastercomfig.com/en/$1/next_steps/update/)\n\n[Documentation](https://docs.mastercomfig.com/en/$1/)\n\n***\n\n***\n\n[View the code changes](https://github.com/mastercoms/mastercomfig/compare/${old_release}...$1)\"}" \
  https://api.github.com/repositories/69422496/releases)
assets_url=$(echo $assets_url | jq '.assets_url' | sed -e 's/^"//' -e 's/"$//' | sed "s/\bapi\b/uploads/g")

# Upload files
uploadFileToGitHub () {
    file=$1
    name=${1##*/}
    label=${2// /%20}
    url="$assets_url?name=$name&label=$label"
    echo "$url"
    curl -u $GH_USERNAME:$GH_TOKEN -X POST -H 'Content-type: application/octet-stream' \
      -T $file \
      "$url"
}

for f in $(find -name '*.vpk'); do
    basename=${f##*/}
    basename=${basename%.*}
    basename=${basename//-/ }
    uploadFileToGitHub "$f" "$basename"
    basename=""
done

uploadFileToGitHub "./comfig/template.cfg" "user config template"

uploadFileToGitHub "./comfig/autoexec.cfg" "empty autoexec file"

uploadFileToGitHub "./comfig/modules.cfg" "modules template"

uploadFileToGitHub "./comfig/mastercomfig.zip" "mastercomfig zip package"

printf "\n"
