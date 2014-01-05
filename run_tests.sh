#!/usr/bin/env bash

function usage {
  echo "Usage: $0 [OPTION]..."
  echo "Run Tempest unit tests"
  echo ""
  echo "  -V, --virtual-env        Always use virtualenv.  Install automatically if not present"
  echo "  -N, --no-virtual-env     Don't use virtualenv.  Run tests in local environment"
  echo "  -n, --no-site-packages   Isolate the virtualenv from the global Python environment"
  echo "  -f, --force              Force a clean re-build of the virtual environment. Useful when dependencies have been added."
  echo "  -u, --update             Update the virtual environment with any newer package versions"
  echo "  -t, --serial             Run testr serially"
  echo "  -p, --pep8               Just run pep8"
  echo "  -h, --help               Print this usage message"
  echo "  -d, --debug              Debug this script -- set -o xtrace"
  echo "  -- [TESTROPTIONS]        After the first '--' you can pass arbitrary arguments to testr "
}

testrargs=""
just_pep8=0
venv=.venv
with_venv=tools/with_venv.sh
serial=0
always_venv=0
never_venv=0
no_site_packages=0
force=0
wrapper=""
config_file=""
update=0

if ! options=$(getopt -o VNnfutphd -l virtual-env,no-virtual-env,no-site-packages,force,update,serial,pep8,help,debug -- "$@")
then
    # parse error
    usage
    exit 1
fi

eval set -- $options
first_uu=yes
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit;;
    -V|--virtual-env) always_venv=1; never_venv=0;;
    -N|--no-virtual-env) always_venv=0; never_venv=1;;
    -n|--no-site-packages) no_site_packages=1;;
    -f|--force) force=1;;
    -u|--update) update=1;;
    -d|--debug) set -o xtrace;;
    -p|--pep8) let just_pep8=1;;
    -t|--serial) serial=1;;
    --) [ "yes" == "$first_uu" ] || testrargs="$testrargs $1"; first_uu=no  ;;
    *) testrargs="$testrargs $1"; noseargs+=" $1" ;;
  esac
  shift
done


cd `dirname "$0"`

if [ $no_site_packages -eq 1 ]; then
  installvenvopts="--no-site-packages"
fi

function testr_init {
  if [ ! -d .testrepository ]; then
      ${wrapper} testr init
  fi
}

function run_tests {
  testr_init
  ${wrapper} find . -type f -name "*.pyc" -delete
  export OS_TEST_PATH=./tempest/tests
  if [ $serial -eq 1 ]; then
      ${wrapper} testr run --subunit $testrargs | ${wrapper} subunit-2to1 | ${wrapper} tools/colorizer.py
  else
      ${wrapper} testr run --parallel --subunit $testrargs | ${wrapper} subunit-2to1 | ${wrapper} tools/colorizer.py
  fi
}

function run_pep8 {
  echo "Running flake8 ..."
  if [ $never_venv -eq 1 ]; then
      echo "**WARNING**:" >&2
      echo "Running flake8 without virtual env may miss OpenStack HACKING detection" >&2
  fi
  ${wrapper} flake8
}

if [ $never_venv -eq 0 ]
then
  # Remove the virtual environment if --force used
  if [ $force -eq 1 ]; then
    echo "Cleaning virtualenv..."
    rm -rf ${venv}
  fi
  if [ $update -eq 1 ]; then
      echo "Updating virtualenv..."
      python tools/install_venv.py $installvenvopts
  fi
  if [ -e ${venv} ]; then
    wrapper="${with_venv}"
  else
    if [ $always_venv -eq 1 ]; then
      # Automatically install the virtualenv
      python tools/install_venv.py $installvenvopts
      wrapper="${with_venv}"
    else
      echo -e "No virtual environment found...create one? (Y/n) \c"
      read use_ve
      if [ "x$use_ve" = "xY" -o "x$use_ve" = "x" -o "x$use_ve" = "xy" ]; then
        # Install the virtualenv and run the test suite in it
        python tools/install_venv.py $installvenvopts
        wrapper=${with_venv}
      fi
    fi
  fi
fi

if [ $just_pep8 -eq 1 ]; then
    run_pep8
    exit
fi

run_tests
retval=$?

if [ -z "$testrargs" ]; then
    run_pep8
fi

exit $retval
