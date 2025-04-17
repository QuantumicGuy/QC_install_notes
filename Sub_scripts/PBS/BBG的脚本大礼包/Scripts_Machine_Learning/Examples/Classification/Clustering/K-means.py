#!/usr/bin/python3
import matplotlib.pyplot as plt
import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn import datasets

#根据红酒数据集中颜色和proline两个特征变量,使用K-means算法对红酒数据集进行聚类分析
#数据集有178个样本,因此我们计算的数据样本为m=178,n为特征变量的次元,n=2
wine = datasets.load_wine()
X = wine.data[:,[9,12]]
Y = wine.target 

#特征变量的标准化
sc=StandardScaler()
x_std = sc.fit_transform(X)

#构建K-means模型,类别分别设为2,3,4
model2 = KMeans(n_clusters=2,random_state=103)
model3 = KMeans(n_clusters=3,random_state=103)
model4 = KMeans(n_clusters=4,random_state=103)

#训练模型
model2.fit(x_std)
model3.fit(x_std)
model4.fit(x_std)

#在已知数据集分类数为3点前提下，将数据集点正解分类图与K-Means的图绘制后进行比较
plt.figure(figsize=(8,8))
#特征变量颜色与proline的散点图
plt.subplot(2,1,1)    
plt.scatter(x_std[:,0],x_std[:,1],c=Y)
plt.title('training data Y')
#K-means的散点图
plt.subplot(2,1,2)    
plt.scatter(x_std[:,0],x_std[:,1],c=model3.labels_)
plt.scatter(model3.cluster_centers_[:,0],model3.cluster_centers_[:,1],c='red',s=250,marker='*')
plt.title('K-means(n_clusters=3)')

plt.show()