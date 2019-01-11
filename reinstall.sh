CPYTHON_HOME=$(git rev-parse --show-toplevel)
CPYTHON_REPO=$(basename $CPYTHON_HOME)
VENV=$CPYTHON_REPO

# install folder of python; not the repository.
PREFIX=$HOME/$CPYTHON_REPO

FULL_REINSTALL=0

echo "verifying the Makefile options..."

if [ ! -f ./Makefile ]; then
    echo "No Makefile generated"
    FULL_REINSTALL=1
fi


# exit current virtualenv
if [ ! -z "$VIRTUAL_ENV" ]; then
    echo "exiting current virtualenv"
    deactivate
fi;


if [ "$FULL_REINSTALL" = 1 ]; then
    read -p "A full reinstall is necessary. Do you want to do it (y/n)?" -r
    echo # optional: start a new line
    if [ "$REPLY" = "y" ]; then
        echo "cleaning the repo, doing a full reinstall..."
        sudo git clean -xdf

        echo "recreating cpython_utils install/test symlinks"
        pushd ../cpython_utils
        CPYTHON_REPO=$CPYTHON_HOME ./infect_cpython_repo.sh
        popd

        sudo ./configure --prefix="$PREFIX" --with-pydebug
        sudo make coverage
        sudo make altinstall
        sudo make tags

    else
        echo "exiting the script"
        return 1
    fi
else
    echo "starting a partial reinstall. This can be dangerous as not all pyc files
          are deleted"

    # remove old bytecodes (pyc files) (lighter make clean)
    echo "removing old pickle bytecode..."

    sudo find .  -type f -wholename '*pickle*.*o' -exec rm -vf {} \;
    sudo find .  -type f -wholename '*__pycache__*/*pickle*' -exec rm -vf {} \;

    # from inside the destination folder
    sudo find $PREFIX -type f -wholename '*pickle*.*o' -exec rm -vf {} \;
    sudo find $PREFIX -type f -wholename '*__pycache__*/*pickle*' -exec rm -vf {} \;

    # use clinc on pickle before compiling
    echo "calling clinic on _pickle.c"
    ./python ./Tools/clinic/clinic.py ./Modules/_pickle.c

    echo "re-compiling python"
    sudo make -s

    # install the tests
    echo "installing pickle tests and libraries"
    # make altinstall, but trimmed down to only modified files
    sudo /usr/bin/install -c -m 644 ./Lib/pickle.py "$HOME/$VENV/lib/python3.8"
    sudo /usr/bin/install -c -m 644 ./Lib/pickletools.py "$HOME/$VENV/lib/python3.8"
    sudo /usr/bin/install -c -m 644 ./Lib/test/pickletester.py "$HOME/$VENV/lib/python3.8/test"
    sudo /usr/bin/install -c -m 644 ./Lib/test/test_pickle.py "$HOME/$VENV/lib/python3.8/test"

fi

# re-create a clean virtualenv. This is done because the python executables are
# not updated in the virtualenv.
PYTHON="$PREFIX"/bin/python3.8
rmvirtualenv "$VENV"
mkvirtualenv "$VENV" --python="$PYTHON"
setvirtualenvproject "$VIRTUAL_ENV" "$HOME/repos/cpython"
python -mpip install coverage
