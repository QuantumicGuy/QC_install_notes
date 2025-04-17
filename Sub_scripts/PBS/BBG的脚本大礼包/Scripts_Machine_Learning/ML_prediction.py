#!/usr/bin/env python3
import pandas as pd
import numpy as np
import datetime,time,joblib
from sklearn import datasets

###############  Set required parameters here  ###############
input_filename = 'SVR_TAND_best' # the filename.pkl file to be load as target model
ML_type = 'Regression' # machine-learning(ML) type: "Classification" or "Regression"

# load datasets
#df = pd.read_csv('Q199.csv',dtype = 'float')
#data_X = df.iloc[:,0:12]
data_X = [[0,11.5,0,1]] 
data_y = None
#data_y = df['Hardness']


###############  Some user-defined functions  ###############
def total_running_time(end_time,start_time):
    tot_seconds = round(end_time - start_time,2)
    days = tot_seconds // 86400
    hours = (tot_seconds % 86400) // 3600
    minutes = (tot_seconds % 86400 % 3600)// 60
    seconds = tot_seconds % 60
    print(">> Elapsed time: {0:2d} day(s) {1:2d} hour(s) {2:2d} minute(s) {3:5.2f} second(s) <<".format(int(days),int(hours),int(minutes),seconds))

def show_metrics(model, ML_type, y_pred, y_data, X_data):
    if ML_type == "Classification":
        from sklearn.metrics import accuracy_score,classification_report
        accuracy = accuracy_score(y_data, y_pred)
        print('> Accuracy on the unknown data set:    {:.2%}\n'.format(accuracy))
        print('> Classification report on the unknown data set:')
        print(classification_report(y_data, y_pred))
    elif ML_type == "Regression":
        from sklearn.metrics import mean_squared_error,mean_absolute_error
        mse = mean_squared_error(y_pred, y_data)
        mae = mean_absolute_error(y_pred, y_data)
        print('> Mean squared error (MSE) on the unknown data set:  {:.6f}\n'.format(mse))
        print('> Mean absolute error (MAE) on the unknown data set:  {:.6f}\n'.format(mae))
        print('> R-squared (R^2) value on the unknown data set:  {:.6f}\n'.format(model.score(X_data, y_data)))
    else:
        print('** Please choose the machine-learning(ML) type: **\n   \
               Choose one of the following ML types:')
        print('   (1) Classification\n   (2) Regression')
        exit(1)


###############  The ML training script starts from here  ###############
start_time = time.time()
start_date = datetime.datetime.now()
print('***  Scikit-learn prediction script started at {0}  ***\n'.format(start_date.strftime("%Y-%m-%d %H:%M:%S")))

# load the model from the *.pkl file
filename = input_filename  + ".pkl"
model = joblib.load(filename) 

# predict the unknown data set
y_pred = model.predict(data_X)
print('---------- Results based on the current loaded model ----------')
print('> Current parameters:\n {}\n'.format(model.get_params()))
print('> Prediction on the unknown data set:\n {}\n'.format(y_pred))

if isinstance(data_y, np.ndarray) or data_y:
    show_metrics(model, ML_type, y_pred, data_y, data_X)

end_time = time.time()
end_date = datetime.datetime.now()
print('***  Scikit-learn prediction script terminated at {0}  ***\n'.format(end_date.strftime("%Y-%m-%d %H:%M:%S")))
total_running_time(end_time, start_time)





