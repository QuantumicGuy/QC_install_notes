#!/usr/bin/python3
import matplotlib.pyplot as plt
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score
from sklearn.datasets import load_iris

#下载鸢尾花数据集并选择逻辑回归模型
iris = load_iris()
model = LogisticRegression(max_iter=100000)

#初期设定划分为3折
scores = cross_val_score(model,iris.data,iris.target,cv=3)
print(scores)   # 输出:[0.98 0.96 0.98]

#cv设定划分为5折
scores = cross_val_score(model,iris.data,iris.target,cv=5)
print(scores)   # 增加cv数达到了更优的划分组合

