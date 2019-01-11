set breakpoint pending on
dir ~/repos/pythonic_cpython
break Modules/_pickle.c:7922
break Modules/_pickle.c:1747
break Modules/_pickle.c:4367
break Modules/_pickle.c:4255

run -m pdb test_nested_function.py

