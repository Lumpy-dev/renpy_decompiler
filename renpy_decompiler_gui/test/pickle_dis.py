import pickletools
import sys

pickletools.dis(open(sys.argv[1], 'rb').read(), out=open('out_dis_python.txt', 'w'))
