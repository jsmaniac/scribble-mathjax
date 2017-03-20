#!/bin/sh
set -e
set +x
if test "$(git config remote.origin.url)" != "https://github.com/jsmaniac/scribble-mathjax.git"; then
  echo "Not on official repo, will not deploy gh-pages."
elif test "$TRAVIS_PULL_REQUEST" != "false"; then
  echo "This is a Pull Request, will not deploy gh-pages."
elif test "$TRAVIS_BRANCH" != "v2.6-racket-mini-source"; then
  echo "Not on v2.6-racket-mini-source branch (TRAVIS_BRANCH = $TRAVIS_BRANCH), will not deploy gh-pages."
elif test -z "${encrypted_675a73236f08_key:-}" -o -z "${encrypted_675a73236f08_iv:-}"; then
  echo "Travis CI secure environment variables are unavailable, will not deploy gh-pages."
else
  set -x
  echo "Automatic push to gh-pages"

  # Git configuration:
  git config --global user.name "$(git log --format="%aN" HEAD -1) (Travis CI automatic commit)"
  git config --global user.email "(git log --format="%aE" HEAD -1)"

  # SSH configuration
  set +x
  if openssl aes-256-cbc -K $encrypted_675a73236f08_key -iv $encrypted_675a73236f08_iv -in travis-deploy-key-id_rsa.enc -out travis-deploy-key-id_rsa -d >/dev/null 2>&1; then
    echo "Dectypred key successfully."
  else
    echo "Error while decrypting key."
  fi
  set -x
  chmod 600 travis-deploy-key-id_rsa
  eval `ssh-agent -s`
  ssh-add travis-deploy-key-id_rsa


  npm install grunt grunt-cli grunt-contrib-clean grunt-regex-replace
  PATH="$PWD/node_modules/grunt-cli/bin:$PATH" grunt racket-mini
  git add -A . &> /dev/null
  git rm -f .gitignore || true
  git rm -f Gruntfile.js || true
  git commit -m "auto-commit" &>/dev/null
  git log --oneline --decorate --graph -10
  git push --force --quiet "git@github.com:jsmaniac/scribble-mathjax.git" HEAD:refs/heads/v2.6-racket-mini > /dev/null 2>&1
fi