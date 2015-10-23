import sys

if len(sys.argv) < 2:
    raise NameError, "Error: Not enough arguments!"


f = open(sys.argv[1], "r")
x = f.read()
f.close()

if len(x) < int(sys.argv[2]):
    for y in range(1, int(sys.argv[2]) - len(x)):
        x += ' '

if len(x) > int(sys.argv[2]):
    x = x[0:int(sys.argv[2])]

if len(x) != int(sys.argv[2]):
    raise NameError, "Error: Problem in resizing syntax!"

f = open(sys.argv[1], "w")
f.write(x[0:])
f.close()
