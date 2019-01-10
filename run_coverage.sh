#!/bin/bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

CPYTHON_HOME=$PWD
CPYTHON_COV_HOME=$HOME/repos/cpython_coverage
COVERAGE_PROCESS_START=$HOME/repos/$CPYTHON_REPO/.coveragerc

PYTHON=python3.8
HTML_DIR="$CPYTHON_COV_HOME"/"$CPYTHON_REPO"/"$CURRENT_BRANCH"

if [ -z "${VIRTUAL_ENV}" ]; then
    echo "you should have a virtual environment activated to run this script"
    return 1
fi

# enable subprocess coverage requires:
# - creating a .pth file that quickly imports coverage and
#   coverage.process_startup()
# - adding COVERAGE_PROCESS_START as an environment variable before running the
#   tests

$PYTHON "$0"/install_coverage_subprocess_pth.py

COVERAGE_PROCESS_START=${COVERAGE_PROCESS_START} $PYTHON -mcoverage run \
    "$CPYTHON_HOME"/Lib/test/regrtest.py test_pickle -v
    # -m test_method_in_main


$PYTHON remove_coverage_pth_code.py

$PYTHON -m coverage combine
$PYTHON -m coverage report


# make a coverage directory for each branch
if [ ! -d "$HTML_DIR" ]; then
    mkdir "$HTML_DIR"
fi

$PYTHON -m coverage html --directory="$HTML_DIR"

# open the coverage summary
xdg-open "$HTML_DIR/index.html"
