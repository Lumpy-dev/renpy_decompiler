import pickle
import sys

out_index = pickle.loads(open(sys.argv[1], 'rb').read())

out_file = open('out_load_python.txt', 'w')

for (key, value) in out_index.items():
    for r in value:
        print(key + ' ' + str(r[0]) + '-' + str(r[1]), file=out_file)

out_file.close()
