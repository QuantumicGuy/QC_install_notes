#!/usr/bin/env python3
import pandas as pd
from sklearn.model_selection import train_test_split
from shapash import SmartExplainer
import joblib

'''load models'''
filename = "pd_RFR_best"  # input the name of the *.pkl file
models = joblib.load(filename + ".pkl") 
model = models._final_estimator

'''load datasets'''
df = pd.read_csv('TZ038-41.csv').fillna(0)
data_X = df.iloc[:,1:8]
data_y = df['permanent deformation']

X_train, X_test, y_train, y_test = train_test_split(data_X, data_y, test_size=0.2, random_state=0)

'''creat and compile SmartExplainer'''
if "ct" in models.named_steps:
    column_trans = models.named_steps['ct']
    xpl = SmartExplainer(model=model, preprocessing=column_trans)
    X_final = pd.DataFrame(column_trans.transform(data_X), index=data_X.index)
    y_pred = pd.DataFrame(model.predict(X_final), columns=['pred'], index=X_final.index)
else:
    xpl = SmartExplainer(model=model)
    X_final = data_X

xpl.compile(x=X_final, y_pred=y_pred)

'''output results'''
summary_contrib = xpl.to_pandas(max_contrib=5)
print(summary_contrib.head())
summary_contrib.to_csv(filename + '_sum_contrib.csv', encoding ='utf_8')

#result = xpl.plot.features_importance(max_features=5)
#result = xpl.plot.local_plot(index=11)
#result = xpl.plot.top_interactions_plot(nb_top_interactions=5)
result = xpl.plot.interactions_plot('ohe_SL7025', 'ohe_DC01T')
result.show()

#app = xpl.run_app(title_story='title',port=5010,host='127.0.0.2')
#xpl.save('xpl.pkl')
