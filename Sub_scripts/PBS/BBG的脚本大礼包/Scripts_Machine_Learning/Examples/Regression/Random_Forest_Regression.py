#!/usr/bin/python3
import numpy as np
import pandas as pd
from sklearn.svm import SVR
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.datasets import load_boston

boston = load_boston()

X = boston.data   
Y = boston.target   

x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size = 0.2, random_state = 0)


# 构建随机森林回归模型
model = RandomForestRegressor(bootstrap=True,n_estimators=1000,criterion='mse',max_depth=None,random_state=0,n_jobs=-1)
model.fit(x_train, y_train)
print(model)

# 采用MSE来评价预测模型
y_train_pred = model.predict(x_train)
y_test_pred = model.predict(x_test)
MSE_train = mean_squared_error(y_train,y_train_pred)
MSE_test = mean_squared_error(y_test,y_test_pred)
print('\nMSE_train_model(RF):',MSE_train)
print('MSE_test_model(RF):',MSE_test)
print()

# 计算每个变量的重要性并输出,顺序为每个变量在数据集中的位置从第0列到第13列
print('model.feature_importances_:',model.feature_importances_)
importances = model.feature_importances_

# 排序并将每个变量名称按上述顺序进行排列
indices = np.argsort(importances)[::-1]
names = [boston.feature_names[i] for i in indices]
for i,j in zip(names,indices):
    print('{0:>8s} {1:8.3f}'.format(i,importances[j]))



