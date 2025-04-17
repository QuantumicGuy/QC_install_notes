#!/usr/bin/python3
import numpy as np
import pandas as pd
from sklearn.svm import SVR
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import mean_squared_error
from sklearn.datasets import load_boston

boston = load_boston()

X = boston.data   
Y = boston.target   

x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size = 0.2, random_state = 0)

# 支持向量机SVM是必须要做标准化的
sc = StandardScaler()
x_train_std = sc.fit_transform(x_train)
x_test_std = sc.transform(x_test)

# 构建线性回归模型（LinearRegression）与支持向量回归模型(SVR)
model = LinearRegression()
model2 = SVR(kernel='linear', C=10.0, epsilon=5.0)
model3 = SVR()
model.fit(x_train_std, y_train)
model2.fit(x_train_std, y_train)

# 启动 gridsearch，将不同数值的超参数分别组合,分开训练,需要计算7*6*6=252个组合
param_grid = [{'kernel':['rbf'],'C':[1.,3.,10.,30.,100.,300.,1000.],'gamma':[0.01,0.03,0.1,0.3,1.,3.],'epsilon':[0.01,0.03,0.1,0.3,1.,3.]}]
grid_search = GridSearchCV(model3,param_grid,cv=5,scoring='neg_mean_squared_error',verbose=2,n_jobs=-1)
grid_search.fit(x_train_std,y_train)
print(grid_search.best_params_)
print(grid_search.best_estimator_)
model3 = grid_search.best_estimator_

# 采用MSE来评价预测模型
y_train_pred = model.predict(x_train_std)
y_test_pred = model.predict(x_test_std)
MSE_train = mean_squared_error(y_train,y_train_pred)
MSE_test = mean_squared_error(y_test,y_test_pred)
print('\nMSE_train_model(LR):',MSE_train)
print('MSE_test_model(LR):',MSE_test)
y_train_pred2 = model2.predict(x_train_std)
y_test_pred2 = model2.predict(x_test_std)
MSE_train2 = mean_squared_error(y_train,y_train_pred2)
MSE_test2 = mean_squared_error(y_test,y_test_pred2)
print('\nMSE_train_model(SVR):',MSE_train2)
print('MSE_test_model(SVR):',MSE_test2)
y_train_pred3 = model3.predict(x_train_std)
y_test_pred3 = model3.predict(x_test_std)
MSE_train3 = mean_squared_error(y_train,y_train_pred3)
MSE_test3 = mean_squared_error(y_test,y_test_pred3)
print('\nMSE_train_model(SVR_gridsearch):',MSE_train3)
print('MSE_test_model(SVR_gridsearch):',MSE_test3)
