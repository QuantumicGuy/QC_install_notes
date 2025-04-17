#!/usr/bin/python3
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression, Ridge, Lasso, ElasticNet,SGDRegressor
from sklearn.preprocessing import StandardScaler, PolynomialFeatures
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.datasets import load_boston

boston = load_boston()
X = boston.data
Y = boston.target

x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size = 0.2, random_state = 0)

sc = StandardScaler()
x_train_std = sc.fit_transform(x_train)
x_test_std = sc.transform(x_test)

# 概率梯度下降法的回归模型制作
model = SGDRegressor(loss='squared_loss', max_iter=100, eta0=0.01,learning_rate='constant', alpha=1e-09, penalty='l2', l1_ratio=0, random_state=0)
model.fit(x_train_std, y_train)


# 采用MSE与残差来评价预测模型
y_train_pred = model.predict(x_train_std)
y_test_pred = model.predict(x_test_std)
MSE_train = mean_squared_error(y_train,y_train_pred)
MSE_test = mean_squared_error(y_test,y_test_pred)
print('\nMSE_train_model:',MSE_train)
print('MSE_test_model:',MSE_test)

