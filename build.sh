#!/usr/bin/env zsh

# Copyright (c) Stéphane FEUGA OSHIMA
#  stephane [@] feuga-oshima.com
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

FILES=('flow' 'flow.js')

if which asdf &> /dev/null; then
  echo 'Setup Build env...'
  asdf plugin-add opam && asdf install opam latest && asdf global opam latest
else
  echo "Please install asdf version manager & opam"
  exit 1
fi

for file in "${FILES[@]}"; do
  if [[ -e "$file" ]]; then
    mv "$file" /tmp/
  fi
done

cd .. || exit 2

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
opam install -y js_of_ocaml.3.9.0
make js

for file in "${FILES[@]}"; do
  if [[ -e "$file" ]]; then
    rm /tmp/"$file"
  fi
done

cd bin || exit 2

if [[ -e .env ]]; then
  RELEASE='Default build on Mac M1'
  API_URL='https://api.github.com/repos'

  source .env

  LATEST_RELEASE=$(curl -sSL --request GET "$API_URL/$GITHUB_USERNAME/$REPO/releases" | grep tag_name | awk -F ': ' '{print $2}' | sed 's/"//g' | sed 's/,//g')
  APP_VERSION=$(./"${FILES[1]}" --version | awk -F 'version ' '{print $2}')

  if [[ "$LATEST_RELEASE" == "v$APP_VERSION" ]]; then
    echo 'There is no new version'
    exit 0
  else
    git add "${FILES[@]}"
    git commit -m "build: v$APP_VERSION"
    git tag "v$APP_VERSION"
    git push --tags

    curl --location --request POST "$API_URL/$GITHUB_USERNAME/$REPO/releases" \
         --header 'Accept: application/vnd.github.v3+json' \
         --header "Authorization: token $TOKEN" \
         --header 'Content-Type: application/json' \
         --data-raw "{\"tag_name\": \"v$APP_VERSION\",
                      \"target_commitish\": \"main\",
                      \"name\": \"v$APP_VERSION\",
                      \"body\": \"$RELEASE\",
                      \"draft\": false,
                      \"prerelease\": false,
                      \"generate_release_notes\": false}"
  fi
else
  echo "Please Create a new Release on https://github.com/$GITHUB_USERNAME/$REPO/releases"
fi
