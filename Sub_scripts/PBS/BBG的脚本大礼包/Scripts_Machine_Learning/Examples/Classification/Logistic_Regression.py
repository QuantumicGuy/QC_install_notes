#!/usr/bin/python3
import numpy as np
import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

#下载保存并读入红酒数据
df_wine=pd.read_csv('http://archive.ics.uci.edu/ml/machine-learning-databases/wine/wine.data',header=None)
df_wine.columns=['Class label','Alcohol','Malic acid','Ash','Alcalinity of ash','Magnesium','Total phenols','Flavanoids','Nonflavanoid phenols','Proanthocyanins','Color intensity','Hue','OD280/OD315 of diluted wines','Proline']

print(pd.DataFrame(df_wine.head()))    #打印前五组数据
print('wine shape:', df_wine.shape)
#取178组特征变量中第10、13列第数据为X，第0列第数据为y，y值减一，正确标签为0,1,2
X = df_wine.iloc[:,[10,13]].values  
Y = df_wine.iloc[:,0].values-1
print(X[:5],Y[:5])   #输出前5组数据
   
x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size = 0.2, random_state = 0)

#将特征变量标准化
sc = StandardScaler()

#用变化器对训练数据进行标准化
x_train_std = sc.fit_transform(x_train)

#用已经构建好的变换器对测试数据标准化
x_test_std = sc.transform(x_test)


#构建逻辑回归模型
model = LogisticRegression(max_iter=100,multi_class='ovr',solver='liblinear',C=0.1,penalty='l2',l1_ratio=None,random_state=0)
model.fit(x_train_std, y_train)
print(model)

#使用训练好的模型对测试集进行预测，并计算accuracy_score函数得到正确率
y_test_pred = model.predict(x_test_std)
ac_score = accuracy_score(y_test,y_test_pred)
print('\nac_score:{0:.2%}'.format(ac_score))
print()


#构建自定义数据(0.1,-0.1)来测试其位于哪个标签下
new_data = [[0.1,-0.1]]
print('predict:',model.predict(new_data))
print('score:',model.decision_function(new_data))
print('probability:',model.predict_proba(new_data))
print(sc.inverse_transform(new_data))


#构建softmax回归模型
model2 = LogisticRegression(max_iter=100,multi_class='multinomial',solver='lbfgs',C=1.0,penalty='l2',l1_ratio=None,random_state=0)
model2.fit(x_train_std, y_train)

#使用训练好的模型对测试集进行预测，并计算accuracy_score函数得到正确率
y_test_pred = model2.predict(x_test_std)
ac_score2 = accuracy_score(y_test,y_test_pred)
print('\nac_score:{0:.2%}'.format(ac_score2))
print()


#使用softmax回归模型预测自定义数据所属的红酒种类
print('predict:',model2.predict(new_data))
print('score:',model2.decision_function(new_data))
print('probability:',model2.predict_proba(new_data))




