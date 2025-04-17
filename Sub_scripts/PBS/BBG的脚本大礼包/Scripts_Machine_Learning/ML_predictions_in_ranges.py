#!/usr/bin/env python3
import pandas as pd
import numpy as np
import itertools as it
import os,datetime,time,joblib

###############  Set required parameters here  ###############
input_filename = ['Hardness_EN_best','MA300_EN_best','pd_EN_best']  # the filename.pkl files in the current working directory to be load as target models
output_filename = 'EN_predictions' # the results are saved to the *.csv file
ML_type = 'Regression' # machine-learning(ML) type: "Classification" or "Regression"
features_number = 7  # the number of the features
target_classification_label = ['0','A']  # only for classification jobs
sorting_choice = 'descending' # "ascending" or "descending"

'''load datasets'''
df = pd.read_csv('TZ038-41.csv').fillna(0)
X = list(range(features_number))
X[0] = np.sort(df['ZnO2'].unique()).tolist()
X[1] = np.sort(df['DC01'].unique()).tolist()
X[2] = np.sort(df['DC01T'].unique()).tolist()
X[3] = np.sort(df['ZnO1'].unique()).tolist()
X[4] = np.sort(df['WS'].unique()).tolist()
X[5] = np.sort(df['PCZ70'].unique()).tolist()
X[6] = np.sort(df['SL7025'].unique()).tolist()
# X[0] = [0,2.5,5]            #ZnO2
# X[1] = [0,1]                #DC01
# X[2] = [0,1]                #DC01T
# X[3] = [0,2.5,5]            #ZnO1
# X[4] = [0,10]               #WS
# X[5] = [0,10,14.29]         #PCZ70
# X[6] = [0,10]               #SL7025
columns = ['ZnO2','DC01','DC01T','ZnO1','WS','PCZ70','SL7025']

combinations = it.product(*X)
data_X_raw = np.array(list(combinations))
data_X_raw = pd.DataFrame(data_X_raw,columns=columns)

'''constraint condition'''
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

# print(conditions)
# exit()

'''set target Y ranges; 'all' for all ranges'''
# y_ranges = "(data_X_y['Hardness_EN_best'] > 60.5)&(data_X_y['Hardness_EN_best'] < 61)&(data_X_y['MA300_EN_best'] > 1)"
y_ranges = "all"

###############  Some user-defined functions and variables  ###############
sorting = True if sorting_choice == 'ascending' else False

def total_running_time(end_time, start_time):
    tot_seconds = round(end_time - start_time,2)
    days = tot_seconds // 86400
    hours = (tot_seconds % 86400) // 3600
    minutes = (tot_seconds % 86400 % 3600)// 60
    seconds = tot_seconds % 60
    print(">> Elapsed time: {0:2d} day(s) {1:2d} hour(s) {2:2d} minute(s) {3:5.2f} second(s) <<".format(int(days),int(hours),int(minutes),seconds))

def model_predictions(input_filename):
    filename = input_filename + ".pkl"
    model = joblib.load(filename) 
    y_pred = model.predict(data_X)
    data_y = pd.DataFrame(y_pred, columns=[input_filename])
    data_X_y = pd.concat([data_X, data_y], axis=1)
    data_X_y_sorted = data_X_y.sort_values(input_filename,ascending=sorting,ignore_index=True)

    print('---------- Information of the {0} model ----------'.format(filename))
    print('> Parameters of the {0} model:\n {1}\n'.format(filename, model.get_params()))
    print('> Results based on the {0} model:\n {1}\n'.format(filename, data_X_y_sorted))
    return y_pred

def get_results(y_preds, data_X, ML_type, input_filename, y_ranges='all'):
    print('-------->> FINAL RESULTS BASED ON THE ABOVE {0} MODELS <<--------'.format(len(input_filename)))
    print('> Target Y ranges:\n  {0}\n'.format(y_ranges))
    pd.set_option('max_colwidth', 50)
    pd.set_option('display.max_columns', None)
    pd.set_option('display.max_rows', None)
    pd.set_option('display.width', 1000)
    data_X_y = pd.concat([data_X,y_preds], axis=1)

    y_ranges = eval(y_ranges)
    final_results = data_X_y[y_ranges] if type(y_ranges).__name__ == "Series" else data_X_y

    if ML_type == 'Regression':
        final_results = final_results.sort_values(input_filename,ascending=sorting,ignore_index=True)
        final_results = final_results if len(final_results.index) != 0 else ' @@ No record falls in the target Y ranges! @@'
        print('> Final results shown in {0} orders of target Y columns:\n {1}\n'.format(sorting_choice,final_results))
    elif ML_type == 'Classification':
        final_results = final_results if len(final_results.index) != 0 else ' @@ No record falls in the target Y ranges! @@'
        final_results = final_results.reset_index(drop=True)
        print('> Final results:\n {}\n'.format(final_results))
    
    if type(final_results).__name__ == "DataFrame":
        filename = output_filename + ".csv"
        final_results.to_csv(filename, encoding ='utf_8')
        print('~~ The results are saved as the \'{0}\' file in the current working directory ~~'.format(filename))
        print('   CWD: {0}\n'.format(os.getcwd()))


###############  The ML prediction script starts from here  ###############
start_time = time.time()
start_date = datetime.datetime.now()
print('***  Scikit-learn predictions (in target Y ranges) script started at {0}  ***\n'.format(start_date.strftime("%Y-%m-%d %H:%M:%S")))

X_str = ' '
for i,j in enumerate(X):
    X_str += 'X[' + str(i) + ']: ' + str(j) + '\n    '
print('>>> The ranges of features to be searched:\n   {}'.format(X_str))

y_preds = []
for i in input_filename:
    y_preds.append(model_predictions(i)[:,np.newaxis])
y_preds = pd.DataFrame(np.hstack(y_preds), columns=input_filename)
get_results(y_preds,data_X,ML_type,input_filename,y_ranges)


end_time = time.time()
end_date = datetime.datetime.now()
print('***  Scikit-learn predictions (in target Y ranges) script terminated at {0}  ***\n'.format(end_date.strftime("%Y-%m-%d %H:%M:%S")))
total_running_time(end_time,start_time)





