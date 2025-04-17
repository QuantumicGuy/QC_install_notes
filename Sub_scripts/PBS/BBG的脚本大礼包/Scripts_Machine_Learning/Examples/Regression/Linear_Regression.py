#!/usr/bin/python3
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error

df = pd.read_csv('http://archive.ics.uci.edu/ml/machine-learning-databases/housing/housing.data',header=None,sep='\s+')

df.columns = ['CRIM','ZN','INDUS','CHAS','NOX','RM','AGE','DIS','RAD','TAX','PTRARIO','B','LSTAT','MEDV']

# 以pandas的dataframe的格式打印前5行内容
print(pd.DataFrame(df.head()))
print()

# 第1-13列为自变量X，第14列为因变量Y
X = df.iloc[:,0:13].values  # ','前为取的行数；后为取的列数
Y = df['MEDV'].values
print('X[0-2]:',X[:3],'\n')
print('Y[0-2]:',Y[:3],'\n')

x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size = 0.2, random_state = 0)
print('X_train shape',x_train.shape,'Y_train shape',y_train.shape)
print('X_test shape',x_test.shape,'Y_test shape',y_test.shape)

sc = StandardScaler()
X_train_std = sc.fit_transform(x_train)
X_test_std = sc.transform(x_test)
print('\nX_train_std[0]')
print(X_train_std[0])

LR = LinearRegression()
LR.fit(X_train_std,y_train)
print('\nLR')
print(LR)
print('LR.coef:',LR.coef_,'\n')
print('LR.intercept:',LR.intercept_,'\n')

# 采用MSE与残差来评价预测模型
y_train_pred = LR.predict(X_train_std)
y_test_pred = LR.predict(X_test_std)
MSE_train = mean_squared_error(y_train,y_train_pred)
MSE_test = mean_squared_error(y_test,y_test_pred)
print('MSE_train:',MSE_train,'\n')
print('MSE_test:',MSE_test,'\n')


