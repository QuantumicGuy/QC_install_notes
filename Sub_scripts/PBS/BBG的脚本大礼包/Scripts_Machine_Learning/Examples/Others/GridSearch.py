#!/usr/bin/python3
import matplotlib.pyplot as plt
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.model_selection import GridSearchCV
from sklearn.datasets import load_iris
from sklearn.svm import SVC

#使用GridSearch进行交叉验证
iris = load_iris()

#指定超参数C和gamma的数值, 各6个，总计6*6=36种组合
param_grid={'C':[0.001,0.01,0.1,1,10,100],'gamma':[0.001,0.01,0.1,1,10,100]}

#定义gridsearch,使用SVC模型
grid_search = GridSearchCV(SVC(),param_grid,cv=5)
x_train,x_test,y_train,y_test = train_test_split(iris.data,iris.target,random_state=0)

#利用gridsearch找到最优组合，此时总共需要训练36次
grid_search.fit(x_train,y_train)

#计算每个组合的得分并找到最优解
grid_search.score(x_test,y_test)

#输出每个组合的平均测试得分以及最优的参数组合
print(grid_search.cv_results_['mean_test_score'])
print()
print('best_params:{0}'.format(grid_search.best_params_))



