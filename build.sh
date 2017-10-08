#!/bin/sh -e

function extraline {
  echo
}

function red {
  RED="$(tput setaf red)"
  NC="$(tput sgr0)"

 echo "${RED}${1}${NC}"
}

function interupt {
  extraline
  red "Interupt Detected. Exiting Now."
  exit $1
}

trap 'interupt $?' INT

function check_bundler {
  if ! bundle check &>/dev/null; then
    if ! bundle install --quiet; then
      echo 'Error: Bundler Failed. Run `bundle install` interactively.'
      exit 1
    fi
  fi 
}

function run_app {
  bundle exec rake run --silent
}

#=================
# Execution Begins
#=================

check_bundler
run_app
