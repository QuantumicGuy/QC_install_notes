#!/usr/bin/python
#coding=utf-8
import re
import sys
import ast
import math
import time
import os
import glob

def get_info(text):
  head='T      S           MS= 0                  -1                    \+1'
  tail='CALCULATED REDUCED SOCME BETWEEN TRIPLETS AND SINGLETS'
  data_content=re.findall(head+'(.*)'+tail,text,re.S)
  return data_content

start = time.time()
path_vec = glob.glob(r'*.out')
for k in range(0,len(path_vec)):
    print("源文件：" + path_vec[k])
    portion = os.path.splitext(path_vec[k])#将文件名拆成名字和后缀
    newname = os.path.join(portion[0] + '-SOC.out') 
    newname1 = os.path.join(portion[0] + '-SOC-raw.out') 
    print("数据汇总：" + newname)
    with open(path_vec[k], 'r') as f:
      text=f.read()
      content=get_info(text)
      str2 = ''.join(content)
      str1 = re.findall("[-+]?[0-9]*\.?[0-9]+",str2)
      str3=[]
      for x in range(0,len(str1),8):
          i=str1[x]
          j=str1[x+1]
          i = int (i)
          j = int (j)
          b = 0
          for c in range(6):
            a = str1[x+c+2]
            a =float (a)
            b = a*a+b
          g = math.sqrt(b)
          str4=[i,j,g]
          str3.append(str4)
      str3 = ''.join('%s' %id for id in str3)
      str3 = str3.replace('][','\n')
      str3 = str3.strip('[')
      str3 = str3.strip(']')
      with open(newname,"w") as f:
              f.write(str3)
      str2.split('\n')
      with open(newname1,"w") as f:
              f.write(str2+'\n')    
print ("第一列为三线态，第二列为单线态！")     
end = time.time()
time = end-start
print ("elapsed time(s):"+ str(time))

