#!/usr/bin/env python3
import os,time
import joblib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import shap
#from sklearn.model_selection import train_test_split

def pipeline_shap(pipeline, X_all, X_selected, KernelExplainer=False, interaction=False):
    model = pipeline._final_estimator
    feature_values = X_selected
    sort_cols, onehot_cols = [], []
    OneHot_flag = False
    Select_flag = False

    if "ct" in pipeline.named_steps:
        col_trans_flag = True
        mapper = pipeline.named_steps["ct"]
    else:
        col_trans_flag = False

    # sort columns according to the DataFrameMapper or ColumnTransformer
    if col_trans_flag:
        if "DataFrameMapper" in str(mapper):
            ct_name = "DataFrameMapper"
            colname_iloc = 0
            all_transformers = mapper.features
        elif "ColumnTransformer" in str(mapper):
            ct_name = "ColumnTransformer"
            colname_iloc = 2
            all_transformers = mapper.transformers_
        print("Info: The {0} module is employed to preprocess data...\n".format(ct_name))

        for i in all_transformers:
            if 'Select' in str(i[1]):
                Select_flag = True
                inp_col = i[colname_iloc]
                for j in i[1]:
                    if 'Select' in str(j):
                        sel_col_index = j.get_support(indices=True)
                        break
                sel_cols = [inp_col[index] for index in sel_col_index]
                sort_cols += sel_cols
            else:
                sort_cols += i[colname_iloc]
            if 'OneHot' in str(i[1]):
                OneHot_flag = True
                if 'Select' in str(i[1]):
                    onehot_cols += sel_cols
                else:
                    onehot_cols += i[colname_iloc]
   
        feature_values = feature_values[sort_cols]
        print("Sorted feature values of the first five samples:\n{0}\n".format(feature_values.head()))

        if Select_flag:
            feature_values_mapper = mapper.transform(X_selected)
            print("Info: The Select* transformer is detected! The number of sorted features may be reduced...\n")
        else:
            feature_values_mapper = mapper.transform(feature_values)
        print("Mapped feature values of the first five samples:\n{0}\n".format(feature_values_mapper[:5,:]))

        if OneHot_flag:
            print("Info: The OneHotEncoder is detected! Therefore, merge the mapped shap values...\n")

    # select the explainer module and obtain expected_values
    if KernelExplainer:
        if col_trans_flag:
            explainer = shap.KernelExplainer(model.predict, mapper.transform(X_all))
        else:
            explainer = shap.KernelExplainer(model.predict, X_all)
        expected_values = explainer.expected_value
    else:
        explainer = shap.Explainer(model)
        expected_values = explainer.expected_value[0]

    # calculate shap_values or shap_interaction_values
    if interaction == True and col_trans_flag == True:
        mapper_shap_values = explainer.shap_interaction_values(feature_values_mapper)
        total_samples = len(mapper_shap_values)
        shap_values = []
        index_map = []

        index = 0
        for col in sort_cols:
            if col in onehot_cols:
                col_index_span = len(X_all[col].unique())
            else:
                col_index_span = 1
            index_map.append((index, col_index_span))
            index += col_index_span

        for s in range(total_samples):
            shap_values_one_sample = np.zeros((len(sort_cols),len(sort_cols)))
            for i in range(len(sort_cols)):
                for j in range(len(sort_cols)):
                    shap_values_one_sample[i,j] = mapper_shap_values[s][
                        index_map[i][0]:index_map[i][0]+index_map[i][1], index_map[j][0]:index_map[j][0]+index_map[j][1]
                         ].sum()
            shap_values.append(shap_values_one_sample)
        shap_values = np.array(shap_values)
         
    elif interaction == False and col_trans_flag == True:
        mapper_shap_values = explainer.shap_values(feature_values_mapper)
        shap_values = pd.DataFrame(index=feature_values.index, columns=feature_values.columns)

        col_index = 0
        for col in sort_cols:
            if col in onehot_cols:
                col_index_span = len(X_all[col].unique())
                shap_values[col] = mapper_shap_values[:, col_index: col_index + col_index_span].sum(1)
                col_index += col_index_span
            else:
                shap_values[col] = mapper_shap_values[:, col_index]
                col_index += 1

    elif interaction == True and col_trans_flag == False:
        shap_values = explainer.shap_interaction_values(feature_values)

    elif interaction == False and col_trans_flag == False:
        shap_values = explainer.shap_values(feature_values)
        shap_values = pd.DataFrame(shap_values, index=feature_values.index, columns=feature_values.columns)

    return feature_values, shap_values, expected_values

def total_running_time(end_time, start_time):
    tot_seconds = round(end_time - start_time,2)
    days = tot_seconds // 86400
    hours = (tot_seconds % 86400) // 3600
    minutes = (tot_seconds % 86400 % 3600)// 60
    seconds = tot_seconds % 60
    print("Info: Elapsed time: {0:2d} day(s) {1:2d} hour(s) {2:2d} minute(s) {3:5.2f} second(s)".format(int(days),int(hours),int(minutes),seconds))

'''set plots'''
plot_type = "waterfall" # "importance", "summary", "force", "waterfall", "dependence", and "interaction"
show_fig = True  # whether to show figures after plotting results
sample_index = 7  # only for the force and waterfall plots with the specific sample
feature_dependence = ['R1502','DS']  # only for the dependence plot with specific two features, e.g.:['DS','R1502']
feature_interaction = [] # only for the interaction plot with the specific two features, e.g.:['DC01T','DC01T']

'''load pipline'''
filename = "CUTLOSS_RFR_oh"  # input the name of the *.pkl file
pipeline = joblib.load(filename + ".pkl") 
model = pipeline._final_estimator

'''load dataset'''
df = pd.read_csv('1502_LYL.csv').fillna(0)
data_X = df.iloc[:,0:4]
data_y = df['CUTLOSS']

'''select data'''
# X_train, X_test, y_train, y_test = train_test_split(data_X, data_y, test_size=0.2, random_state=0)

X_all = data_X
X_selected = data_X


#exit()

'''creat explainer and get shap_values and expected_values'''
start_time = time.time()
try :
    explainer = shap.Explainer(model)
    print("Use the smart Explainer to analyse the target model...\n")
    kernel_flag = False
    if plot_type == "interaction":
        feature_values, shap_interaction_values, expected_values = pipeline_shap(pipeline, X_all, X_selected, KernelExplainer=False, interaction=True)
    else:
        feature_values, shap_values, expected_values = pipeline_shap(pipeline, X_all, X_selected, KernelExplainer=False, interaction=False)
except TypeError as e:
    print("Warning: {0}\nTherefore, use the KernelExplainer instead to analyse the target model...\n".format(e))
    kernel_flag = True
    if plot_type == "interaction":
        pass
    else:
        feature_values, shap_values, expected_values = pipeline_shap(pipeline, X_all, X_selected, KernelExplainer=True, interaction=False)

'''results and plots'''
save_plot_name = filename + "_" + plot_type + ".png"

if plot_type == "importance":
    feature_importance = pd.DataFrame()
    feature_importance['feature'] = shap_values.columns
    feature_importance['importance'] = feature_importance['feature'].map(np.abs(shap_values).mean(0))
    feature_importance = feature_importance.sort_values('importance', ascending=False)
    print("Feature importance:\n{0}\n".format(feature_importance))
    shap.summary_plot(shap_values.values, feature_values, plot_type="bar", show=False)
    for x,y in enumerate(feature_importance.sort_values('importance', ascending=True).values):
        plt.text(y[1], x, '%s' %round(y[1],3), ha='left')

elif plot_type == "summary":
    shap.summary_plot(shap_values.values, feature_values, show=False)

elif plot_type == "force" or plot_type == "waterfall":
    y_pred = pd.DataFrame(pipeline.predict(X_selected), columns=['pred'], index=X_selected.index)
    print("Target sample:\n{0}\n".format(feature_values.iloc[sample_index,:]))
    print("Expected [base] value:   {:.4f}".format(expected_values))
    print("Predicted [f(x)] value:  {:.4f}\n".format(y_pred.iloc[sample_index,0]))
    if plot_type == "force":
        shap.force_plot(expected_values, shap_values.values[sample_index,:], feature_values.iloc[sample_index,:], matplotlib=True, show=False)
    elif plot_type == "waterfall":
        shap.waterfall_plot(shap.Explanation(values=shap_values.values[sample_index,:], base_values=expected_values, data=feature_values.iloc[sample_index,:]), max_display=20, show=False)

elif plot_type == "interaction":
    if kernel_flag == False:
        if feature_interaction:
            shap.dependence_plot(tuple(feature_interaction), shap_interaction_values, feature_values, show=False)
            save_plot_name = filename + "_main_effect.png" if feature_interaction[0] == feature_interaction[1] else filename + "_target_interactions.png"
        else:
            shap.summary_plot(shap_interaction_values, feature_values, plot_type="compact_dot", max_display=20, show=False)
            save_plot_name = filename + "_top20_interactions.png"
    elif kernel_flag == True:
        print("\nError: The KernelExplainer cannot output the interaction plot (shap_interaction_values)!")
        show_fig = None

elif plot_type == "dependence":
    shap.dependence_plot(feature_dependence[0], shap_values.values, feature_values, interaction_index=feature_dependence[1], show=False)

else:
    print("Error: Please input one of the following plot types:")
    print("       'importance', 'summary', 'force', 'waterfall', 'dependence', and 'interaction'")
    show_fig = None


'''output figures'''
end_time = time.time()
if show_fig != None:
    plt.savefig(save_plot_name, bbox_inches='tight', dpi=300)
    print('Info: The target plot is saved in the following path:'.format(save_plot_name))
    print('      {0}\n'.format(os.getcwd() + os.sep + save_plot_name))
    total_running_time(end_time, start_time)
    
    if show_fig == True:
        plt.show()



