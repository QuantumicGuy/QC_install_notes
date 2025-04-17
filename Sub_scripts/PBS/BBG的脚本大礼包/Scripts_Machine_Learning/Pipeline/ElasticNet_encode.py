#!/usr/bin/env python3
import pandas as pd
import numpy as np
import os,sys,datetime,time,joblib
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler,PolynomialFeatures
from sklearn.preprocessing import LabelEncoder,OneHotEncoder,OrdinalEncoder
#from sklearn.compose import ColumnTransformer
from sklearn_pandas import DataFrameMapper
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
    if model_name == "LinearRegression":
        from sklearn.linear_model import LinearRegression
        model = LinearRegression(**model_params)
        ML_type = "Regression"
        return "lr", model
    elif model_name == "Ridge":
        from sklearn.linear_model import Ridge
        model = Ridge(**model_params)
        ML_type = "Regression"
        return "ridge", model
    elif model_name == "Lasso":
        from sklearn.linear_model import Lasso
        model = Lasso(**model_params)
        ML_type = "Regression"
        return "lasso", model
    elif model_name == "ElasticNet":
        from sklearn.linear_model import ElasticNet
        model = ElasticNet(**model_params)
        ML_type = "Regression"
        return "en", model
    elif model_name == "LogisticRegression":
        from sklearn.linear_model import LogisticRegression
        model = LogisticRegression(**model_params)
        ML_type = "Classification"
        return "lr", model
    else:
        print('** Please choose a LinearRegression/LogisticRegression model **\n-> Supported LinearRegression/LogisticRegression models are as follows:')
        print('   (1) LinearRegression\n   (2) Ridge\n   (3) Lasso\n   (4) ElasticNet\n   (5) LogisticRegression')
        exit(1)

def show_metrics(model, ML_type, y_train_pred, y_train, y_test_pred, y_test, X_train, X_test):
    if ML_type == "Classification":
        from sklearn.metrics import accuracy_score,classification_report
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
        from sklearn.metrics import mean_squared_error,mean_absolute_error
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
'''script parameters'''
save_model = False 
filename = sys.argv[0].split(os.sep)[-1].split(".")[0]  # the target model will be saved as the filename.pkl file

'''SearchCV parameters'''
SearchCV_flag = True  # True: optimize model parameters; False: use specific parameters
SearchCV_method = "GridSearchCV" # "GridSearchCV" or "RandomizedSearchCV"
searchCV_other_params = {"verbose":2, "refit":True, "cv":3, "n_jobs":-1, "scoring":'neg_mean_squared_error'}  # cv: k-fold cross validation; n_jobs: parallel CPU cores; n_iter=300 (for RandomizedSearchCV) "scoring":'neg_mean_squared_error' or 'accuracy'

'''model parameters'''
model_name = "ElasticNet"  # "LinearRegression", "Ridge", "Lasso", "ElasticNet", and "LogisticRegression"
model_params = {'max_iter':10000}

'''load datasets'''
df = pd.read_csv('TZ038-41.csv').fillna(0)
data_X = df.iloc[:,1:8] 
data_y = df['Hardness']

print(df)
exit()


'''Pipeline scheme'''
ZnO2 = np.sort(df['ZnO2'].unique()).tolist()
DC01 = np.sort(df['DC01'].unique()).tolist()
DC01T = np.sort(df['DC01T'].unique()).tolist()
ZnO1 = np.sort(df['ZnO1'].unique()).tolist()
WS = np.sort(df['WS'].unique()).tolist()
PCZ70 = np.sort(df['PCZ70'].unique()).tolist()
SL7025 = np.sort(df['SL7025'].unique()).tolist()

columns_list = ['ZnO-2','DC-01','DC-01T','ZnO-1','WS','PCZ-70','SL-7025']   

# column_trans = ColumnTransformer(
                         # [
                          # ('ohe', OneHotEncoder(categories=[ZnO2,DC01,DC01T,ZnO1,WS,PCZ70,SL7025], sparse=False), column_list)],
                            # remainder='passthrough'
                            # )
                            
               
column_trans = DataFrameMapper(
                         [
                         (columns_list, OneHotEncoder(categories=[ZnO2,DC01,DC01T,ZnO1,WS,PCZ70,SL7025]))],
                          None
                            )

pipe_model = Pipeline([ 
                        ('ct', column_trans),
                        model_choice(model_name, model_params)
                      ])
                      
#print(np.array(column_trans.fit_transform(data_X)))

'''Pipeline parameters'''
pipe_params_tests =  [{ 'en__alpha':[0.001,0.002,0.005,0.01,0.02,0.05,0.08,0.09,0.1,0.12,0.15,0.2,0.5,1], 
                        'en__l1_ratio':[i*0.05 for i in range(1,20,1)]
                        }
                     ]


###############  The ML training script starts from here  ###############
start_time = time.time()
start_date = datetime.datetime.now()
print('***  Scikit-learn script ({0}) started at {1}  ***\n'.format(model_name, start_date.strftime("%Y-%m-%d %H:%M:%S")))

'''split training/test sets'''
X_train, X_test, y_train, y_test = train_test_split(data_X, data_y, test_size=0.2, random_state=0)

if SearchCV_flag == True:
    '''pipeline scheme (scaling -> dimensionality reduction -> learning algorithm -> predictive model)
    perform grid/randomized search with pipeline scheme to find the optimal parameters for the target model'''
    print('----- Using the {0} method with pipeline scheme to optimize model parameters -----'.format(SearchCV_method))
    print('+ Pipeline model:\n     {0}'.format(pipe_model))
    print('+ Pipeline params:\n     {0}'.format(pipe_params_tests))

    if SearchCV_method == "GridSearchCV":
        from sklearn.model_selection import GridSearchCV
        searchCV = GridSearchCV(pipe_model, pipe_params_tests, **searchCV_other_params)  
    elif SearchCV_method == "RandomizedSearchCV":
        from sklearn.model_selection import RandomizedSearchCV
        searchCV = RandomizedSearchCV(pipe_model, pipe_params_tests, **searchCV_other_params)

    print('+ {0} params:\n     {1}\n'.format(SearchCV_method, searchCV))
    searchCV.fit(X_train, y_train)
    best_model = searchCV.best_estimator_
    y_train_pred = best_model.predict(X_train)
    y_test_pred = best_model.predict(X_test)
    print('\n> Best estimator:\n     {0}\n'.format(searchCV.best_estimator_))
    print('> Best parameters:\n     {0}\n'.format(searchCV.best_params_))
    print('> Best CV score:  {:.6f}  ({})'.format(searchCV.best_score_, searchCV.scoring))
    show_metrics(best_model, ML_type, y_train_pred, y_train, y_test_pred, y_test, X_train, X_test)

elif SearchCV_flag == False:
    '''use the specific parameters to set up the new model'''
    print('----- Results based on the specific model parameters by using pipeline scheme -----')
    pipe_model.fit(X_train, y_train)
    y_train_pred = pipe_model.predict(X_train)
    y_test_pred = pipe_model.predict(X_test)
    print('> Current parameters:\n     {0}\n'.format(pipe_model.get_params))
    show_metrics(pipe_model, ML_type, y_train_pred, y_train, y_test_pred, y_test, X_train, X_test)

if save_model == True:
    if SearchCV_flag == True:
        opt_type = "GS" if SearchCV_method == "GridSearchCV" else "RS"
        filename1 = filename + "_" + opt_type + ".pkl"
        joblib.dump(searchCV, filename1)
        filename2 = filename + "_best.pkl"
        joblib.dump(best_model, filename2)
        files = filename1 + "' and '" + filename2
    elif SearchCV_flag == False:
        filename1 = filename  + ".pkl"
        joblib.dump(pipe_model, filename1)
        files = filename1
    print('~~ Target model is saved as the \'{0}\' file(s) in the current working directory ~~'.format(files))
    print('   CWD: {0}\n'.format(os.getcwd()))

end_time = time.time()
end_date = datetime.datetime.now()
print('***  Scikit-learn script ({0}) terminated at {1}  ***\n'.format(model_name, end_date.strftime("%Y-%m-%d %H:%M:%S")))
total_running_time(end_time, start_time)


