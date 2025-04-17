#!/usr/bin/python3
import matplotlib.pyplot as plt
import numpy as np
from sklearn.cluster import KMeans
from sklearn.mixture import GaussianMixture
from sklearn.mixture import BayesianGaussianMixture
from sklearn.preprocessing import StandardScaler
from sklearn import datasets

#根据红酒数据集中颜色和proline两个特征变量,使用混合高斯分布GMM算法对红酒数据集进行聚类分析
#数据集有178个样本,共计3种不同红酒使用混合高斯分布进行聚类
wine = datasets.load_wine()
X = wine.data[:,[9,12]]
Y = wine.target 

#特征变量的标准化
sc=StandardScaler()
x_std = sc.fit_transform(X)

#GMM模型的构建与训练,指定covariance_type为‘diag’
model = GaussianMixture(n_components=3,covariance_type='diag',random_state=1)
model.fit(x_std)

#GMM模型的构建与训练,指定covariance_type为‘full’
model2 = GaussianMixture(n_components=3,covariance_type='full',random_state=1)
model2.fit(x_std)

#绘制共分散分别为diag和full时的混合高斯分布图
plt.figure(figsize=(8,8))
#特征变量颜色与proline的散点GMM(diag)图
plt.subplot(2,1,1)    
x = np.linspace(x_std[:,0].min()-1,x_std[:,0].max()+1,100)
y = np.linspace(x_std[:,0].min()-1,x_std[:,0].max()+1,100)
X,Y = np.meshgrid(x,y)
XX = np.array([X.ravel(),Y.ravel()]).T
Z = -model.score_samples(XX)
print(X)
Z = Z.reshape(X.shape)
plt.contour(X,Y,Z,levels=[0.5,1,2,3,4,5])
#绘制红酒数据集数据散点图
plt.scatter(x_std[:,0],x_std[:,1],c=model.predict(x_std))
#绘制高斯分布的平均,以红色星号表示
plt.scatter(model.means_[:,0],model.means_[:,1],s=250,marker='*',c='red')
plt.title('GMM(covariance_type=diag)')

#特征变量颜色与proline的散点GMM(full)图
plt.subplot(2,1,2)    
x = np.linspace(x_std[:,0].min()-1,x_std[:,0].max()+1,100)
y = np.linspace(x_std[:,0].min()-1,x_std[:,0].max()+1,100)
X,Y = np.meshgrid(x,y)
XX = np.array([X.ravel(),Y.ravel()]).T
Z = -model2.score_samples(XX)
Z = Z.reshape(X.shape)
plt.contour(X,Y,Z,levels=[0.5,1,2,3,4,5])
#绘制红酒数据集数据散点图
plt.scatter(x_std[:,0],x_std[:,1],c=model2.predict(x_std))
#绘制高斯分布的平均,以红色星号表示
plt.scatter(model2.means_[:,0],model2.means_[:,1],s=250,marker='*',c='red')
plt.title('GMM(covariance_type=full)')
plt.show()