#!/usr/bin/env zsh

# Copyright (c) Stéphane FEUGA OSHIMA
#  stephane [@] feuga-oshima.com
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

API_URL='https://api.github.com/repos'
FILES=('flow' 'flow.js')

LATEST_RELEASE=$(curl -sSL --request GET "$API_URL/facebook/flow/releases?per_page=1" | grep tag_name | awk -F ': ' '{print $2}' | sed 's/"//g' | sed 's/,//g' | sed 's/v//g')
LOCAL_RELEASE=$(./"${FILES[1]}" --version | awk -F 'version ' '{print $2}')

if [[ "$LATEST_RELEASE" == "$LOCAL_RELEASE" ]]; then
  echo 'There is no new version'
  exit 0
else
  if which asdf &> /dev/null; then
    echo 'Setup Build env...'
    asdf plugin-add opam &> /dev/null && asdf install opam latest &> /dev/null && asdf global opam latest &> /dev/null
  else
    echo "Please install asdf version manager & opam"
    exit 1
  fi

  for file in "${FILES[@]}"; do
    if [[ -e "$file" ]]; then
      mv "$file" /tmp/
    fi
  done

  cd ..

  echo 'Pull latest code'
  git pull

  if [[ ! -d "$HOME"/.opam ]]; then
    echo 'Init...'
    opam init
  fi
  echo 'Init Dependencies...'
  make deps
  echo "Build ${FILES[1]}..."
  eval "$(opam env)"
  make
  echo "Build ${FILES[2]}..."
  opam install -y js_of_ocaml.3.9.0 &> /dev/null
  make js

  for file in "${FILES[@]}"; do
    if [[ -e "$file" ]]; then
      rm /tmp/"$file"
    fi
  done

  cd bin && unset LOCAL_RELEASE

  if [[ -e .env ]]; then
    LOCAL_RELEASE=$(./"${FILES[1]}" --version | awk -F 'version ' '{print $2}')

    RELEASE='Default build on Mac M1'

    source .env

    git add "${FILES[@]}"
    git commit -m "build: v$LOCAL_RELEASE"
    git tag "v$LOCAL_RELEASE"
    git push --tags

    curl --location --request POST "$API_URL/$GITHUB_USERNAME/$REPO/releases" \
         --header 'Accept: application/vnd.github.v3+json' \
         --header "Authorization: token $TOKEN" \
         --header 'Content-Type: application/json' \
         --data-raw "{\"tag_name\": \"v$LOCAL_RELEASE\",
                      \"target_commitish\": \"main\",
                      \"name\": \"v$LOCAL_RELEASE\",
                      \"body\": \"$RELEASE\",
                      \"draft\": false,
                      \"prerelease\": false,
                      \"generate_release_notes\": false}"
  else
    echo "Please Create a new Release on https://github.com/$GITHUB_USERNAME/$REPO/releases"
  fi
fi
