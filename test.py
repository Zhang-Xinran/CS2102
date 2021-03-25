f = open('input.txt', 'r')

string = f.read()
res = ''
prev = ''
for i in string:
	if (prev == ' ' and i == ' '):
		prev = ' '
		continue
	if (i == '"'):
		res += '\''
	else:
		res += i

	if (i == ','):
		res += ' '
		prev = ' '
		continue
	prev = i
writer = open('./output.txt', 'w')
writer.write(res)
writer.close()