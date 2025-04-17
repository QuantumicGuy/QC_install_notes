#!/usr/bin/python3

import random,time

def random_pick(seq,probabilities):
    x = random.uniform(0,1)   #首先随机生成一个0，1之间的随机数
    cumulative_probability = 0.0
    for item, item_probability in zip(seq,probabilities):   #seq代表待输入的字符串，probabilities代表各自字符串对应的概率
        cumulative_probability += item_probability   #只有当累加的概率比刚才随机生成的随机数大时候，才跳出，并输出此时对应的字符串
        if x < cumulative_probability:
            break
    return item

def view_bar(num):
  a = "#"*int(num/2)
  b = "-"*(50-int(num/2))
  print("\r[{:s}{:s}] {:3d}%".format(a,b, int(num)),end='')
  # r = '\r[%s%s] %d%%  ' % ("#"*int(num/2), "-"*(50-int(num/2)), int(num))
  # sys.stdout.write(r)
  # sys.stdout.flush()

flag = 0
string = []
probabilities_array = []
print("C -> cis(c)      S -> styrene(sa)    s -> styrene(sb)")
print("T -> trans(t)    V -> vinyl(va)      v -> vinyl(vb)")
inp = input("Please input the proportions of C, S, s, T, V, and v:\n[Press enter key to use default settings: 0.2 0.15 0.15 0.2 0.15 0.15]\n")
if inp == "":
    inp = "0.2 0.15 0.15 0.2 0.15 0.15"
    probabilities_array = list(map(float,inp.split()))
else:
    probabilities_array = list(map(float,inp.split()))
    while round(sum(probabilities_array),12) != 1:
        probabilities_array = list(map(float,input("Please reinput the proportions of C, S, s, T, V, and v, and make sure that the total proportion equals 1:\n").split()))
length = input("Please input the length of the string to be generated:\n[Press enter key to use default settings: 10000000]\n")
if length == "":
    length = 10000000
else:
    length = int(length)
print_chain = input("Whether output the randomly generated SBR chain?\n[Press \"Y\" or \"y\" key to show]\n")
if print_chain in ["Y","y"]:
    print_flag = "Yes"
else:
    print_flag = "No"
print()
print("***************** Input Info. ******************")
print("     C = %.3f     S = %.3f      s = %.3f" % (probabilities_array[0],probabilities_array[1],probabilities_array[2]))
print("     T = %.3f     V = %.3f      v = %.3f" % (probabilities_array[3],probabilities_array[4],probabilities_array[5]))
print("     Total Length: %d units" % length)
print("     Show Generated SBR Chain: %s" % print_flag)
print("************************************************")
input("Press enter key to continue...\n")

print("Generating a random SBR chain...")
for i in range(length):   #生成指定长度的字符串
    string.append(random_pick("CSsTVv",probabilities_array))
    j = int(100*(i + 1)/length)
    if length < 1000:
        view_bar(j)
    elif length >= 1000:
        if j == flag:
            view_bar(j)
            flag += 1
if print_chain in ["Y","y"]:
    print("\n")
    time.sleep(1)
    print("Outputting the randomly generated SBR chain:")
    for unit in string:
        print(unit,end = '')   #打印字符串

print("\n")
models = []
counters = []
labels = []
conversion = {'C': 'c', 'T': 't', 'S': 'sa','s':'sb','V':'va','v':'vb'}
conversion_V = {'C': 'c', 'T': 't', 'S': 'sb','s':'sa','V':'vb','v':'va'}
flag = 0
print("Counting and classifying reaction sites in the SBR chain... ")
for i in range(1,length-1):
    if string[i] == 'C':
        current = conversion[string[i-1]] + '-cis-' + conversion[string[i+1]]
        if current not in models:
            models.append(current)
            counters.append(1)
            labels.append('C' + conversion[string[i-1]] + conversion[string[i+1]])
        else:
            counters[models.index(current)] += 1
    elif string[i] == 'T':
        current = conversion[string[i-1]] + '-trans-' + conversion[string[i+1]]
        if current not in models:
            models.append(current)
            counters.append(1)
            labels.append('T' + conversion[string[i-1]] + conversion[string[i+1]])
        else:
            counters[models.index(current)] += 1
    elif string[i] == 'V':
        current = conversion_V[string[i+1]] + '-vinyl-' + conversion_V[string[i-1]]
        if current not in models:
            models.append(current)
            counters.append(1)
            labels.append('V' + conversion_V[string[i+1]] + conversion_V[string[i-1]])
        else:
            counters[models.index(current)] += 1
    elif string[i] == 'v':
        current = conversion[string[i-1]] + '-vinyl-' + conversion[string[i+1]]
        if current not in models:
            models.append(current)
            counters.append(1)
            labels.append('V' + conversion[string[i-1]] + conversion[string[i+1]])
        else:
            counters[models.index(current)] += 1 
    j = int(100*i/(length-2))
    if length < 1000:
        view_bar(j)
    elif length >= 1000:
        if j == flag:
            view_bar(j)
            flag += 1

time.sleep(1)
print("\n")
print("Outputting the proportions of each model in the random SBR chain:")
time.sleep(1)
array_2D = [['' for i in range(3)] for j in range(len(models))]
for i in range(len(models)):
    array_2D[i][0] = models[i]
    array_2D[i][1] = "{:.6f}".format(counters[i]/sum(counters))
    array_2D[i][2] = labels[i]
array_2D.sort(key=lambda x:x[2]) 
j = 0
for i in range(len(models)):
    j += 1
    print("%11s -> %-8s" % (array_2D[i][0],array_2D[i][1]),end = '  ')
    if j == 6:
         print("")
         j = 0
print("\n")
time.sleep(1)
print("Total Reaction Sites / Total Length (units): %d / %d" % (sum(counters),length))
print("Current Available Models / Theoretic Total Models : %d / 108" % len(models))
print("")



