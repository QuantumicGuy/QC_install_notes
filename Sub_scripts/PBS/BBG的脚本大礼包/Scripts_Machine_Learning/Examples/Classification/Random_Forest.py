#!/usr/bin/python3
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn import datasets
from sklearn.metrics import accuracy_score


#载入红酒数据集，将所有特征变量指定为自变量X，红酒对应的分类标签指定为Y
wine = datasets.load_wine()
X = wine.data
Y = wine.target 

#划分训练集与测试集
X_train,X_test,Y_train,Y_test = train_test_split(X,Y,test_size=0.2,random_state=0)


#构建随机森林模型并训练
model = RandomForestClassifier(bootstrap=True, n_estimators=10,criterion='gini',random_state=1,max_depth=None)
model.fit(X_train, Y_train)
print(model)

#用测试集计算正确率并输出
y_test_pred = model.predict(X_test)
ac_score=accuracy_score(Y_test,y_test_pred)
print('ac_score:{0:>0.2%}'.format(ac_score))

# 计算每个变量的重要性并输出,顺序为每个变量在数据集中的位置从第0列到第13列
print('model.feature_importances_:',model.feature_importances_)
importances = model.feature_importances_

# 排序并将每个变量的名称按上述顺序进行排列
indices = np.argsort(importances)[::-1]
#names = [wine.feature_names[i] for i in indices]
#for i,j in zip(names,indices):
#    print('{0:>30s} {1:8.3f}'.format(i,importances[j]))
for i in indices:
    print('{0:>30s} {1:8.3f}'.format(wine.feature_names[i],importances[i]))


