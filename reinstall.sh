CPYTHON_HOME=$(git rev-parse --show-toplevel)
CPYTHON_REPO=$(basename $CPYTHON_HOME)
VENV=$CPYTHON_REPO

# install folder of cpython; not the repository.
PREFIX=$HOME/$CPYTHON_HOME

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

        sudo ./configure --prefix="$PREFIX" --with-pydebug
        sudo make && sudo make altinstall

    else
        echo "exiting the script"
        return 1
    fi
else
    echo "starting a partial reinstall. This can be dangerous as not all pyc files
          are deleted"

    # remove old bytecodes (pyc files) (lighter make clean)
    echo "removing old pickle bytecode..."
    # from inside the cpython repo
    # bash exits with 1 if not found, -> unable to use the errexit option
    # without crashing the bash session. Better check if file exists using
    # either -f or find
    sudo rm "./build/lib.linux-x86_64-3.8-pydebug/_pickle.cpython-38dm-x86_64-linux-gnu.so"
    sudo rm "./build/temp.linux-x86_64-3.8-pydebug$HOME/repos/cpython/Modules/_pickle.o"
    sudo rm "./Lib/__pycache__/pickle.cpython-38.pyc"
    sudo rm "./Lib/__pycache__/pickle.cpython-38.pyc"


    # from inside the destination folder
    sudo rm "$PREFIX/lib/python3.8/__pycache__/pickle.cpython-38.pyc"
    sudo rm "$PREFIX/lib/python3.8/__pycache__/pickle.cpython-38.opt-2.pyc"
    sudo rm "$PREFIX/lib/python3.8/__pycache__/pickle.cpython-38.opt-1.pyc"

    # use clinc on pickle before compiling
    echo "calling clinic on _pickle.c"
    python3.8 "$CPYTHON_HOME"/Tools/clinic/clinic.py Modules/_pickle.c

    echo "re-compiling python"
    # re-compile pickle
    sudo make -C $CPYTHON_HOME -s

    # install the tests
    echo "installing pickle tests and libraries"
    # make altinstall, but trimmed down to only modified files
    sudo /usr/bin/install -c -m 644 $CPYTHON_HOME/Lib/pickle.py "$HOME/$VENV/lib/python3.8"
    sudo /usr/bin/install -c -m 644 $CPYTHON_HOME/Lib/pickletools.py "$HOME/$VENV/lib/python3.8"
    sudo /usr/bin/install -c -m 644 .CPYTHON_HOME/Lib/test/pickletester.py "$HOME/$VENV/lib/python3.8/test"
    sudo /usr/bin/install -c -m 644 .CPYTHON_HOME/Lib/test/test_pickle.py "$HOME/$VENV/lib/python3.8/test"

fi

# re-create a clean virtualenv. This is done because the python executables are
# not updated in the virtualenv.
PYTHON="$HOME/$VENV/bin/python3.8"
rmvirtualenv "$VENV"
mkvirtualenv "$VENV" --python="$PYTHON"
setvirtualenvproject "$VIRTUAL_ENV" "$HOME/repos/cpython"
python -mpip install coverage
