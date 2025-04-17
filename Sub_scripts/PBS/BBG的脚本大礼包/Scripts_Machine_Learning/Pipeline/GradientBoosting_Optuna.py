import optuna
import pandas as pd
import numpy as np
import datetime,time,os,sys,joblib
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import OneHotEncoder, LabelEncoder, OrdinalEncoder
from sklearn_pandas import DataFrameMapper


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
    if model_name == "GradientBoostingRegressor":
        from sklearn.ensemble import GradientBoostingRegressor
        model = GradientBoostingRegressor(**model_params)
        ML_type = "Regression"
        return "gbr", model
    elif model_name == "GradientBoostingClassifier":
        from sklearn.ensemble import GradientBoostingClassifier
        model = GradientBoostingClassifier(**model_params)
        ML_type = "Classification"
        return "gbc", model
    else:
        print('** Please choose a GradientBoosting model **\n-> Supported GradientBoosting models are as follows:')
        print('   (1) GradientBoostingRegressor\n   (2) GradientBoostingClassifier')
        exit(1)

def show_metrics(model, ML_type, y_train_pred, y_train, y_test_pred, y_test, X_train, X_test):
    print("\n>>>>  Metrics based on the best estimator  <<<<")
    if ML_type == "Classification":
        from sklearn.metrics import accuracy_score, classification_report
        accuracy_train = accuracy_score(y_train, y_train_pred)
        accuracy_test = accuracy_score(y_test, y_test_pred)
        print('> Accuracy on the training set:  {:.2%}'.format(accuracy_train))
        print('> Accuracy on the test set:  {:.2%}'.format(accuracy_test))
        print('> Score on the training set:  {:.2%}'.format(model.score(X_train, y_train)))
        print('> Score on the test set:  {:.2%}'.format(model.score(X_test, y_test)))
        print('> Classification report on the training set:')
        print(classification_report(y_train, y_train_pred))
        print('> Classification report on the test set:')
        print(classification_report(y_test, y_test_pred))
    elif ML_type == "Regression":
        from sklearn.metrics import mean_squared_error, mean_absolute_error
        mse_train = mean_squared_error(y_train, y_train_pred)
        mse_test = mean_squared_error(y_test, y_test_pred)
        mae_train = mean_absolute_error(y_train, y_train_pred)
        mae_test = mean_absolute_error(y_test, y_test_pred)
        print('> Mean squared error (MSE) on the training set:  {:.6f}'.format(mse_train))
        print('> Mean squared error (MSE) on the test set:  {:.6f}'.format(mse_test))
        print('> Mean absolute error (MAE) on the training set:  {:.6f}'.format(mae_train))
        print('> Mean absolute error (MAE) on the test set:  {:.6f}'.format(mae_test))
        print('> R-squared (R^2) value on the training set:  {:.6f}'.format(model.score(X_train, y_train)))
        print('> R-squared (R^2) value on the test set:  {:.6f}\n'.format(model.score(X_test, y_test)))


###############  Set required parameters and load data here  ###############
'''basic parameters'''
save_model = True   # the best model is saved as the *_best.pkl file
model_name = "GradientBoostingRegressor"  #  "GradientBoostingRegressor" or "GradientBoostingClassifier"
model_params = {'random_state':0} 
scoring_metircs = "neg_mean_squared_error" #   https://scikit-learn.org/stable/modules/model_evaluation.html#scoring-parameter
score_opt_direction = "maximize"   # "minimize" or "maximize"
timeout = None # time limit in seconds for the search of appropriate models. 
n_trials = 100
cv_fold = 3
n_jobs = 6

'''load the dataset'''
df = pd.read_csv('TZ038-41.csv').fillna(0)
data_X = df.iloc[:,1:8]
data_y = df['MA300']

'''preprocessing of the dataset'''
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
                      (columns_list, OneHotEncoder(categories=[ZnO2,DC01,DC01T,ZnO1,WS,PCZ70,SL7025], sparse=False))],
                        None
                        )

# print(column_trans.fit_transform(data_X)[0:10,:])
#print(df)
#exit()

'''pipeline scheme'''
# pipe_model = Pipeline([('ct', column_trans),
#                     model_choice(model_name, model_params)
#                   ])

pipe_model = Pipeline([
                        model_choice(model_name, model_params)
                      ])

'''parameters to be optimized'''
pipe_params = {}
pipe_params['gbr__loss'] = optuna.distributions.CategoricalDistribution(['huber'])
pipe_params['gbr__learning_rate'] = optuna.distributions.LogUniformDistribution(1e-3,1e2)
pipe_params['gbr__n_estimators'] = optuna.distributions.IntUniformDistribution(50,250,5)
pipe_params['gbr__max_features'] = optuna.distributions.CategoricalDistribution(['auto', 4, 5, 6, 7])
pipe_params['gbr__max_depth'] = optuna.distributions.IntUniformDistribution(2,8,1)
pipe_params['gbr__min_samples_split'] = optuna.distributions.IntUniformDistribution(2,4,1)
pipe_params['gbr__min_samples_leaf'] = optuna.distributions.IntUniformDistribution(1,4,1)
pipe_params['gbr__ccp_alpha'] = optuna.distributions.UniformDistribution(0,5)
if pipe_params['gbr__loss'] == 'huber':
    pipe_params['gbr__alpha'] = optuna.distributions.UniformDistribution(0,1)


###############  The ML training script starts from here  ###############
start_time = time.time()
start_date = datetime.datetime.now()
print('***  Scikit-learn script ({0}) started at {1}  ***\n'.format(model_name, start_date.strftime("%Y-%m-%d %H:%M:%S")))

'''split training/test sets'''
X_train, X_test, y_train, y_test = train_test_split(data_X, data_y, test_size=0.2, random_state=0)

study = optuna.create_study(sampler=optuna.samplers.TPESampler(), direction=score_opt_direction, study_name=model_name)
optuna_search = optuna.integration.OptunaSearchCV(pipe_model, pipe_params, cv=cv_fold, scoring=scoring_metircs, n_jobs=n_jobs, n_trials=n_trials, study=study, timeout=timeout)

optuna_search.fit(X_train, y_train)

best_trial = optuna_search.best_trial_
n_trials = optuna_search.n_trials_
best_score = optuna_search.best_score_
best_params = optuna_search.best_params_
print("\n-> Best trial: {}\n".format(best_trial))
print("-> Sampling algorithm: {}".format(study.sampler.__class__.__name__))
print("-> Number of completed trials: {}".format(n_trials)) 
print("-> Best CV score: {:.5f}  ({})".format(best_score, scoring_metircs)) 
print("-> Best params: ")
for key, value in best_params.items(): 
    print("  {:>25s}: {}".format(key, value))

best_estimator = optuna_search.best_estimator_
y_train_pred = best_estimator.predict(X_train)
y_test_pred = best_estimator.predict(X_test)
show_metrics(best_estimator, ML_type, y_train_pred, y_train, y_test_pred, y_test, X_train, X_test)

if save_model == True:
    filename = sys.argv[0].split(os.sep)[-1].split(".")[0]
    file_pkl = filename + "_best.pkl"
    joblib.dump(best_estimator, file_pkl)
    print('~~ Target model is saved as the \'{0}\' file in the current working directory (CWD) ~~'.format(file_pkl))
    print('   CWD: {0}\n'.format(os.getcwd()))

end_time = time.time()
end_date = datetime.datetime.now()
print('***  Scikit-learn script ({0}) terminated at {1}  ***\n'.format(model_name, end_date.strftime("%Y-%m-%d %H:%M:%S")))
total_running_time(end_time, start_time)


