#!/usr/bin/python3
import matplotlib.pyplot as plt
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
from mlxtend.plotting import plot_decision_regions
from sklearn import datasets

#下载红酒,将13个特征变量用X表示,然后划分训练集和测试集并对数据进行标准化处理
wine = datasets.load_wine()
X = wine.data
Y = wine.target 
X_train,X_test,Y_train,Y_test = train_test_split(X,Y,test_size=0.2,random_state=0)

#特征变量的标准化
sc=StandardScaler()
x_train_std = sc.fit_transform(X_train)
x_test_std = sc.transform(X_test)
print(x_train_std.shape,x_test_std.shape)

#指定削减后的次元为2，进行主成分分析
PCA=PCA(n_components=2)
#PCA=PCA(n_components=None)

#利用训练数据构建PCA模型
x_train_pca = PCA.fit_transform(x_train_std)

#利用训练数据构建好的PCA模型对测试数据进行PCA
x_test_pca = PCA.transform(x_test_std)

print('explained_variance:',PCA.explained_variance_)
print('explained_variance_ratio:',PCA.explained_variance_ratio_)

#输出第1主成分和第2主成分的特征向量的形状
print('components_.shape',PCA.components_.shape)

#输出第1主成分和第2主成分的特征向量
print('components_',PCA.components_)

#确认削减后的特征变量的形状，输出训练集和测试集数据的形状
print(x_train_pca.shape,x_test_pca.shape)


#构建逻辑回归模型并训练
model = LogisticRegression(multi_class='ovr',max_iter=100,solver='liblinear',penalty='l2',random_state=0)
model.fit(x_train_pca,Y_train)

#利用测试集中的数据计算正确率
y_test_pred = model.predict(x_test_pca)
ac_score = accuracy_score(y_test_pred,Y_test)
print('ac_score:{0:>0.2%}'.format(ac_score))


#将第1主成分和第2主成分设为X,Y轴,分别绘制训练数据和测试数据的结果
plt.figure(figsize=(8,8))
plt.subplot(2,1,1) 
plot_decision_regions(x_train_pca,Y_train,model)
plt.title('train_data')
plt.subplot(2,1,2) 
plot_decision_regions(x_test_pca,Y_test,model)
plt.title('test_data')
plt.show()


#将主成分的次元作为横轴,累计贡献率作为纵轴绘图
# plt.figure(figsize=(8,4))
# ratio = PCA.explained_variance_ratio_
# ratio = np.hstack([0,ratio.cumsum()])
# plt.plot(ratio)
# plt.ylabel('Cumulative contribution rate')
# plt.xlabel('Principal component index k')
                                              
# plt.title('Wine dataset')
# plt.show()