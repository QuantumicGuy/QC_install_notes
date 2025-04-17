#!/usr/bin/python3
import numpy as np
from sklearn.svm import SVC
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from sklearn import datasets

#载入红酒数据集
wine = datasets.load_wine()

#特征变量选取第9、12列，分别对应红酒颜色与proline
X = wine.data[:,[9,12]]
Y = wine.target  #正确的标签对应的数据设为Y

#划分训练集和测试集
x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size = 0.2, random_state = 0)

#将特征变量标准化
sc = StandardScaler()
x_train_std = sc.fit_transform(x_train)
x_test_std = sc.transform(x_test)

#构建Gaussian SVC模型
model = SVC(kernel='rbf',decision_function_shape='ovr',gamma=2.5,C=100.0,random_state=0,max_iter=50000)
model.fit(x_train_std, y_train)
print(model)

#预测测试数据并计算正确率
y_test_pred = model.predict(x_test_std)
ac_score = accuracy_score(y_test_pred,y_test)   # 输出ac_score:0.916666
print('ac_score = {0:.2%}'.format(ac_score))






