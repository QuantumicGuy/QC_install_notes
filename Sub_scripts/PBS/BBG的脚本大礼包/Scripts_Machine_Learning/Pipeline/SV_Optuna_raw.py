#!/usr/bin/env python3
import pandas as pd
import numpy as np
import datetime, time
import optuna
from optuna.samplers import TPESampler 
from sklearn.pipeline import Pipeline
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import LabelEncoder, OneHotEncoder
from sklearn_pandas import DataFrameMapper
#from sklearn.compose import ColumnTransformer
#from sklearn.decomposition import PCA
#from sklearn import datasets

###############  Some user-defined functions  ###############
def total_running_time(end_time, start_time):
    tot_seconds = round(end_time - start_time,2)
    days = tot_seconds // 86400
    hours = (tot_seconds % 86400) // 3600
    minutes = (tot_seconds % 86400 % 3600)// 60
    seconds = tot_seconds % 60
    print(">> Elapsed time: {0:2d} day(s) {1:2d} hour(s) {2:2d} minute(s) {3:5.2f} second(s) <<".format(int(days),int(hours),int(minutes),seconds))

def model_choice(model_name, model_params):
    global ML_type
    if model_name == "SVR":
        from sklearn.svm import SVR
        model = SVR(**model_params)
        ML_type = "Regression"
        return "svr", model
    elif model_name == "SVC":
        from sklearn.svm import SVC
        model = SVC(**model_params)
        ML_type = "Classification"
        return "svc", model
    else:
        print('** Please choose a SV model **\n-> Supported SV models are as follows:')
        print('   (1) SVR\n   (2) SVC')
        exit(1)

def objective(trial):
    '''parameters of target model'''
    model_params = { 'kernel': trial.suggest_categorical("kernel", ['rbf','linear','poly']),
                          'C': trial.suggest_float("C", 1e-5, 1e3, log=True),
                      'gamma': trial.suggest_float("gamma", 1e-5, 1e3, log=True),
                    'epsilon': trial.suggest_float("epsilon", 1e-5, 1e3, log=True)
                    }
    if model_params["kernel"] == "poly": 
        model_params["degree"] = trial.suggest_int("degree", 2, 4) 
    
    '''pipeline scheme'''
    pipe_model = Pipeline([('ct', column_trans),
                    model_choice(model_name, model_params)
                  ])

    '''cross-validation'''
    cv_scores = cross_val_score(pipe_model, X_train, y_train, cv=cv_fold, n_jobs=cv_n_jobs, pre_dispatch=cv_n_jobs, scoring=scoring_metircs)
    average_cv_score = cv_scores.mean()

    return average_cv_score


###############  Set required parameters and load data here  ###############
'''basic parameters'''
model_name = "SVR"  #  "SVR" or "SVC"
scoring_metircs = "neg_mean_squared_error" #   https://scikit-learn.org/stable/modules/model_evaluation.html#scoring-parameter
score_opt_direction = "maximize"   # "minimize" or "maximize"
n_trials = 100
cv_fold = 3
cv_n_jobs = 6

'''load datasets'''
df = pd.read_csv('TZ038-41.csv').fillna(0)
data_X = df.iloc[:,1:8]
data_y = df['MA300']

'''Pipeline scheme'''
columns_list = ['ZnO-2','DC-01','DC-01T','ZnO-1','WS','PCZ-70','SL-7025'] 
ZnO2 = np.sort(df['ZnO-2'].unique()).tolist()
DC01 = np.sort(df['DC-01'].unique()).tolist()
DC01T = np.sort(df['DC-01T'].unique()).tolist()
ZnO1 = np.sort(df['ZnO-1'].unique()).tolist()
WS = np.sort(df['WS'].unique()).tolist()
PCZ70 = np.sort(df['PCZ-70'].unique()).tolist()
SL7025 = np.sort(df['SL-7025'].unique()).tolist()

column_trans = DataFrameMapper(
                     [
                      (columns_list, OneHotEncoder(categories=[ZnO2,DC01,DC01T,ZnO1,WS,PCZ70,SL7025]))],
                        None
                        )


# print(column_trans.fit_transform(data_X)[0:10,:])
# exit()

#print(df)
#exit()


###############  The ML training script starts from here  ###############
start_time = time.time()
start_date = datetime.datetime.now()
print('***  Scikit-learn script ({0}) started at {1}  ***\n'.format(model_name, start_date.strftime("%Y-%m-%d %H:%M:%S")))

'''split training/test sets'''
X_train, X_test, y_train, y_test = train_test_split(data_X, data_y, test_size=0.2, random_state=0)

'''find best paramters by using optuna'''
study = optuna.create_study(sampler=TPESampler(), direction=score_opt_direction, study_name=model_name)
study.optimize(objective, n_trials=n_trials)
best_trial = study.best_trial

print("\n-> Best trial: {}\n".format(best_trial))
print("-> Sampling algorithm: {}".format(study.sampler.__class__.__name__))
print("-> Number of completed trials: {}".format(len(study.trials))) 
print("-> Best CV score: {:.5f}  ({})".format(best_trial.value, scoring_metircs)) 
print("-> Best params: ")
for key, value in best_trial.params.items(): 
    print("  {:>15s}: {}".format(key, value))


end_time = time.time()
end_date = datetime.datetime.now()
print('\n***  Scikit-learn script ({0}) terminated at {1}  ***\n'.format(model_name, end_date.strftime("%Y-%m-%d %H:%M:%S")))
total_running_time(end_time, start_time)


