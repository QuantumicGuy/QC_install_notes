#!/usr/bin/env python3
import pandas as pd
import numpy as np
import itertools as it
import datetime,time,joblib

###############  Set required parameters here  ###############
input_filename = 'Hardness_EN_best' # the filename.pkl file to be load as target model
ML_type = 'Regression' # machine-learning(ML) type: "Classification" or "Regression"
features_number = 7  # the number of the features
target_classification_label = '0' # only for classification jobs
show_more_results = True  # whether to print more information of the results or not
show_rows = 20  # set the total number of rows of more results


# load datasets
#df = pd.read_csv('Q199.csv',dtype = 'float')
#data_X = df.iloc[:,0:12]
#data_X = [[0,11.5,0,1]]
X = list(range(features_number))
X[0] = [0,2.5,5]            #ZnO2
X[1] = [0,1]                #DC01
X[2] = [0,1]                #DC01T
X[3] = [0,2.5,5]            #ZnO1
X[4] = [0,10]               #WS
X[5] = [0,10,14.29]         #PCZ70
X[6] = [0,10]               #SL7025
columns = ['ZnO2','DC01','DC01T','ZnO1','WS','PCZ70','SL7025']

combinations = it.product(*X)
data_X_raw = np.array(list(combinations))
data_X_raw = pd.DataFrame(data_X_raw,columns=columns)

# constraint condition: 
data_X_raw_aug = data_X_raw.copy()
data_X_raw_aug['ZnO_all'] = data_X_raw_aug['ZnO2'] + data_X_raw_aug['ZnO1'] 
data_X_raw_aug['DC01_all'] = data_X_raw_aug['DC01'] + data_X_raw_aug['DC01T']

cond1 = (data_X_raw_aug['ZnO_all'].round(1) == 0.0)|(data_X_raw_aug['ZnO_all'].round(1) == 5.0)
cond2 = (data_X_raw_aug['DC01_all'].round(1) > 0.0)
cond3 = (data_X_raw_aug['WS'].round(1) > 0.0)&(data_X_raw_aug['PCZ70'].round(1) == 0.0)&(data_X_raw_aug['SL7025'].round(1) == 0.0)
cond4 = (data_X_raw_aug['WS'].round(1) == 0.0)&(data_X_raw_aug['PCZ70'].round(1) > 0.0)&(data_X_raw_aug['SL7025'].round(1) == 0.0)
cond5 = (data_X_raw_aug['WS'].round(1) == 0.0)&(data_X_raw_aug['PCZ70'].round(1) == 0.0)&(data_X_raw_aug['SL7025'].round(1) > 0.0)

conditions = (cond1)&(cond2)&(cond3|cond4|cond5)

data_X = data_X_raw[conditions].reset_index(drop=True)

###############  Some user-defined functions  ###############
def total_running_time(end_time,start_time):
    tot_seconds = round(end_time - start_time,2)
    days = tot_seconds // 86400
    hours = (tot_seconds % 86400) // 3600
    minutes = (tot_seconds % 86400 % 3600)// 60
    seconds = tot_seconds % 60
    print(">> Elapsed time: {0:2d} day(s) {1:2d} hour(s) {2:2d} minute(s) {3:5.2f} second(s) <<".format(int(days),int(hours),int(minutes),seconds))

def get_results(y_pred,data_X,ML_type):
    if ML_type == 'Regression':
        data_y = pd.DataFrame(y_pred, columns=['predictions'])
        data_X_y = pd.concat([data_X, data_y],axis=1)
        data_X_y_sorted = data_X_y.sort_values('predictions',ascending=False,ignore_index=True)
        y_max = data_X_y_sorted.iloc[0,-1]
        y_min = data_X_y_sorted.iloc[-1,-1]
        X_max = data_X_y_sorted.iloc[0,0:-1].values
        X_min = data_X_y_sorted.iloc[-1,0:-1].values

        print('> Maximum of the predictions (y_max):\n {:.8f}'.format(y_max))
        print('> Features (X) at the y_max:\n {}\n'.format(X_max))
        print('> Minimum of the predictions (y_min):\n {:.8f}'.format(y_min))
        print('> Features (X) at the y_min:\n {}\n'.format(X_min))

        if show_more_results == True:
            pd.set_option('max_colwidth', 100)
            pd.set_option('display.max_columns', None)
            pd.set_option('display.min_rows', show_rows)
            pd.set_option('display.width', 1000)
            print('> More results shown in descending order by the \'predictions\' column:\n {0}\n'.format(data_X_y_sorted))

    elif ML_type == 'Classification':
        target_indexes = np.where(y_pred == target_classification_label)[0]

        print('> Target prediction label (y):\n {}'.format(target_classification_label))
        if len(target_indexes) == 0:
            print('> Features of the target label (X):\n {}\n'.format('None'))
        else:
            print('> Features of the target label (X):\n {}\n'.format(data_X.iloc[target_indexes].values))


###############  The ML prediction script starts from here  ###############
start_time = time.time()
start_date = datetime.datetime.now()
print('***  Scikit-learn predictions (finding max/min Y) script started at {0}  ***\n'.format(start_date.strftime("%Y-%m-%d %H:%M:%S")))

# load the model from the *.pkl file
filename = input_filename + ".pkl"
model = joblib.load(filename) 

# predict the unknown data set
y_pred = model.predict(data_X)
X_str = ' '
for i,j in enumerate(X):
    X_str += 'X[' + str(i) + ']: ' + str(j) + '\n    '

print('---------- Results based on the current loaded model ----------')
print('> Current parameters:\n {}\n'.format(model.get_params()))
print('>>> The ranges of features to be searched:\n   {}'.format(X_str))
get_results(y_pred,data_X,ML_type)

end_time = time.time()
end_date = datetime.datetime.now()
print('***  Scikit-learn predictions (finding max/min Y) script terminated at {0}  ***\n'.format(end_date.strftime("%Y-%m-%d %H:%M:%S")))
total_running_time(end_time,start_time)





