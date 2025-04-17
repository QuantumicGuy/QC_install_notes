#!/usr/bin/python3
import numpy as np
from sklearn.svm import SVR
from sklearn.neural_network import MLPRegressor
import matplotlib.pyplot as plt
 
# #############################################################################
# Generate sample data
X = np.sort(7 * np.random.rand(40, 1), axis=0)
y = np.sin(X).ravel() * 20
# #############################################################################
# Add noise to targets
noise = 9 * (0.5 - np.random.rand(40))
y_noise = y + noise
# #############################################################################
# Fit regression model
svr_rbf = SVR(kernel='rbf', C=10)
svr_lin = SVR(kernel='linear', C=10)
mlp=MLPRegressor(solver='lbfgs',hidden_layer_sizes=(5,5))
y_SVM_rbf = svr_rbf.fit(X, y_noise).predict(X)
y_SVM_lin = svr_lin.fit(X, y_noise).predict(X)
y_MLPR_mlp = mlp.fit(X, y_noise).predict(X)
 
# #############################################################################
# Show results
lw = 2
plt.scatter(X, y_noise, color='b', label='Input data')
plt.plot(X, y_SVM_rbf, color='y', lw=lw, label='SVM_RBF C=10 ')
plt.plot(X,y_SVM_lin, color='c', lw=lw, label='SVM_Linear C=10')
plt.plot(X, y_MLPR_mlp, color='r', lw=lw, label='y_MLPR_mlp lbfgs_hilayer(5,5)')
plt.xlabel('data')
plt.ylabel('target')
plt.title('Support Vector Regression')
plt.legend()
plt.show()

