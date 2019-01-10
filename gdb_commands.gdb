set breakpoint pending on
dir ~/repos/cpython
break Modules/_pickle.c:6668
break Modules/_pickle.c:7157
break Modules/_pickle.c:3050
run -m pdb test_module.py
