#!/usr/bin/python3

def labels_convertion(input_string): 
  new_string = []
  tmp = input_string.split(",")
  for i in tmp:
    if "-" in i:
      start = int(i.split("-")[0]) - 1
      end = int(i.split("-")[1])
      for j in range(start,end):
        new_string.append(j)
    else:
      new_string.append(int(i) - 1)
  return new_string
  
fixed_atoms = "5"
print(labels_convertion(fixed_atoms))
print(type(labels_convertion(fixed_atoms)))
