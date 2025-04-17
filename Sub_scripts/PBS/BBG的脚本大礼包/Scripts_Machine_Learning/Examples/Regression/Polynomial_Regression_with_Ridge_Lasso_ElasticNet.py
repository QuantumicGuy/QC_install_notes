#!/usr/bin/python3
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression, Ridge, Lasso, ElasticNet
from sklearn.preprocessing import StandardScaler, PolynomialFeatures
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
x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size = 0.2, random_state = 0)

# 将变量x转换为2次多项式
poly = PolynomialFeatures(degree = 2, include_bias = False)
x_train_pol = poly.fit_transform(x_train)
x_test_pol = poly.transform(x_test)

sc = StandardScaler()
X_train_std = sc.fit_transform(x_train_pol)
X_test_std = sc.transform(x_test_pol)

# 定义线性回归模型model和Lasso模型model2, alpha代表正则化的强度
model = LinearRegression()
model2 = Lasso(alpha = 0.1)
model3 = ElasticNet(alpha = 0.1, l1_ratio = 0.6)   # 定义Elastic Net模型

model.fit(X_train_std,y_train)
model2.fit(X_train_std,y_train)
model3.fit(X_train_std,y_train)

print('model.coef_.shape:',model.coef_.shape)
print('model.coef_:',model.coef_)
print('model.intercept:',model.intercept_)
print()
print('model2.coef_.shape:',model2.coef_.shape)
print('model2.coef_:',model2.coef_)
print('model2.intercept:',model2.intercept_)

# 采用MSE与残差来评价预测模型
y_train_pred = model.predict(X_train_std)
y_test_pred = model.predict(X_test_std)
MSE_train = mean_squared_error(y_train,y_train_pred)
MSE_test = mean_squared_error(y_test,y_test_pred)
print('\nMSE_train_model:',MSE_train)
print('MSE_test_model:',MSE_test)
y_train_pred2 = model2.predict(X_train_std)
y_test_pred2 = model2.predict(X_test_std)
MSE_train = mean_squared_error(y_train,y_train_pred2)
MSE_test = mean_squared_error(y_test,y_test_pred2)
print('MSE_train_model2:',MSE_train)
print('MSE_test_model2:',MSE_test)
y_train_pred3 = model3.predict(X_train_std)
y_test_pred3 = model3.predict(X_test_std)
MSE_train = mean_squared_error(y_train,y_train_pred3)
MSE_test = mean_squared_error(y_test,y_test_pred3)
print('MSE_train_model3:',MSE_train)
print('MSE_test_model3:',MSE_test)
