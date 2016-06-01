import sys
import os 
pwd = os.path.realpath(".")
pwd = os.path.dirname(pwd)
sys.path.append(pwd)
del sys, os, pwd
