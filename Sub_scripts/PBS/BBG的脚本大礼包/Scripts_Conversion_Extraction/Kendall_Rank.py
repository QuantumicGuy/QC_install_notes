#!/usr/bin/python3

# 在统计学中，肯德尔相关系数是以Maurice Kendall命名的，并经常用希腊字母τ（tau）表示其值。
# 肯德尔相关系数是一个用来测量两个随机变量相关性的统计值。
# 一个肯德尔检验是一个无参数假设检验，它使用计算而得的相关系数去检验两个随机变量的统计依赖性。
# 肯德尔相关系数的取值范围在-1到1之间，当τ为1时，表示两个随机变量拥有一致的等级相关性；
# 当τ为-1时，表示两个随机变量拥有完全相反的等级相关性；当τ为0时，表示两个随机变量是相互独立的。

from pandas import DataFrame
import os,sys,time,pandas

print("The Kendall rank correlation coefficient (τ) measures the correlation between X and Y data ...")
print("τ ->  1: positive correlation")
print("τ -> -1: negative correlation")
print("τ ->  0: no correlation\n")

choice = input("Whether import X-Y data directly from the *.csv file or not? (y/n)\nP.s. Directly input the enter key to manually input data\n")

while choice not in ["y","n",""]:
    choice = input("Please reinput your choice... (y/n)\n")
if choice == "n" or choice == "":
    x_input = input("Please input a set of X variables, separated by a space:\n")
    y_input = input("Please input a set of corresponding Y variables, separated by a space:\n")
    x = list(map(eval, x_input.split()))
    y = list(map(eval, y_input.split()))
elif choice == "y":   
    print("Please input the filename of the *.csv to be used: e.g. test.csv")
    print("Note that the content format in the *.csv file should follow below:")
    print("compound,X,Y")
    print("A,1,1.3")
    print("B,2,2.2")
    print(".,.,.")
    print(".,.,.")
    print(".,.,.\n")
    filename = input()
    df = pandas.read_csv(filename)
    x = df['X'].values
    y = df['Y'].values
    
print("Please check the following imported X-Y data, and then press any key to start the calculation... ^_^\n")
data=DataFrame({'x':x,'y':y})
print(data)
input()
start_time = time.time()
matrix = data.corr(method='kendall')
results = matrix['y'].values.tolist()
print("τ = {0:5.4f}".format(results[0]))

end_time = time.time()
tot_seconds = round(end_time - start_time,2)
days = tot_seconds // 86400
hours = (tot_seconds % 86400) // 3600
minutes = (tot_seconds % 86400 % 3600)// 60
seconds = tot_seconds % 60
print("")
print(">> Elapsed time: {0:2d} days {1:2d} hours {2:2d} minutes {3:5.2f} seconds <<".format(int(days),int(hours),int(minutes),seconds))
