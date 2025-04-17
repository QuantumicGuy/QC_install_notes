#!/usr/bin/env python3
# 配置cron(需要root权限),每10分钟检测一次,可自己按习惯定。
#    crontab -e
#    输入:
#         */10 * * * *  python3  xxx.py 
#        
# 每晚18:00执行一次
# 0 18 * * * python3 /home/yjy/softwares/OMST_LIMS_reports.py

import smtplib
import datetime
from email.mime.text import MIMEText

import pandas as pd
import pymysql

class Mysqlpython:
    def __init__(self, database='lims', host='192.168.0.110', user="omst",
        password='omst', port=3306, charset="utf8"):
        self.host = host
        self.user = user
        self.password = password
        self.port = port
        self.database = database
        self.charset = charset

    def open(self):
        self.db = pymysql.connect(host=self.host, user=self.user,
        password=self.password, port=self.port,
        database=self.database,
        charset=self.charset)
        self.cur = self.db.cursor()

    def close(self):
        self.cur.close()
        self.db.close()

    def Operation(self, sql):
        try:
            self.open()
            self.cur.execute(sql)
            self.db.commit()
            print("ok!")
        except Exception as e:
            self.db.rollback()
            print("Failed: {0}".format(e))
            self.close()

    def Search(self, sql):
        try:
            self.open()
            self.cur.execute(sql)
            result = self.cur.fetchall()
            return result
        except Exception as e:
            print("Failed: {0}".format(e))
            self.close()

def sendMail(subject, contents, receiver):
    for body_charset in 'US-ASCII', 'ISO-8859-1', 'UTF-8':
        try:
            contents.encode(body_charset)
        except UnicodeError:
            pass
        else:
            break
    #toMailList= [members_dicts("email", "yuan")]
    toMailList= [members_dicts("email", receiver)]
    mySmtp = {"host": "smtp.163.com", "user": "omst_system", "pwd": "JSKXKEHJCHXZFPMU"}
    msg = MIMEText(contents.encode(body_charset), "html", body_charset)
    msg['Subject'] = subject
    msg['From'] = "OMST LIMS Database"
    msg['To'] = ";".join(toMailList)
    try:
        s = smtplib.SMTP()
        s.connect(mySmtp['host'])
        s.login(mySmtp['user'], mySmtp['pwd'])
        s.sendmail("omst_system@163.com", toMailList, msg.as_string())
        s.close()
    except Exception as e:
        print("Error: {0}".format(e))

def members_dicts(dict_name, key):
    exp_symbol_dict = {"tian":"TZ_%", "yan":"Y_%", "wang":"WH_%","zhan":"ZB_%", "zhang":"ZG_%", 
                       "yuan":"LY_%","he":"H_%", "jinqu":"TR_%"}
    full_name_dict = {"tian":"Tian, Ruizhu", "yan":"Yan, Fahui", "wang":"Wang, Hong",
					  "yuan":"Yuan, Jianyong", "zhan":"Zhan, Bicai", "zhang":"Zhang, Gui",
					    "he":"He, Jionghao", "jinqu":"Tsumagari, Rie", "xuyinyin":"Xu, Yinyin"}
    email_dict = {"tian":"tianruizhu@cn.otsuka.com", "yan":"yanfahui@cn.otsuka.com", "wang":"wanghong@cn.otsuka.com",
				  "yuan":"yuanjianyong@cn.otsuka.com", "zhan":"zhanbicai@cn.otsuka.com", "zhang":"zhanggui@cn.otsuka.com",
					"he":"hejionghao@cn.otsuka.com", "jinqu":"rie.tsumagari@cn.otsuka.com", "xuyinyin":"xuyinyin@otsukafoods.com.cn"}
    if dict_name == "exp_No":
        return exp_symbol_dict[key]
    elif dict_name == "full_name":
        return full_name_dict[key]
    elif dict_name == "email":
        return email_dict[key]

def data_frame_settings():
    pd.set_option('max_colwidth', 50)
    pd.set_option('display.max_columns', None)
    pd.set_option('display.min_rows', 200)
    pd.set_option('display.max_rows', None)
    pd.set_option('display.width', 500)
    pd.set_option('display.unicode.ambiguous_as_wide', True)
    pd.set_option('display.unicode.east_asian_width', True)
    pd.set_option('display.colheader_justify', 'center')

def data_inquire(date_start, date_end, job_status, type="omst", exp_symbol="none", device_name="none"):
    omst_lims = Mysqlpython()
    date_type_dict = {"wait":"openedDate", "done":"finishedDate"}

    if type == "omst":
        sql = 'SELECT `zt_arrangement`.`id`, `zt_arrangement`.`name`,`zt_arrangement`.`deviceName`, `zt_arrangement`.`status`, `zt_arrangement`.`openedDate`, `zt_arrangement`.`assignedDate`, `zt_arrangement`.`finishedDate`, `zt_story`.`experimentno`, `zt_projecttest`.`ageingTemp`, `zt_projecttest`.`ageingTime` FROM `zt_story`, `zt_arrangement`, `zt_projecttest` WHERE (`zt_arrangement`.`storyId`=`zt_story`.`id` && `zt_arrangement`.`ptestId`=`zt_projecttest`.`id` && `zt_arrangement`.`deviceName`="{0}" && TO_DAYS(`zt_arrangement`.`{5}`) >= TO_DAYS("{1}") && TO_DAYS(`zt_arrangement`.`{5}`) <= TO_DAYS("{2}") && `zt_story`.`experimentno` LIKE "{3}" && `zt_arrangement`.`status`="{4}") ORDER BY `zt_story`.`experimentno` ASC, `zt_arrangement`.`name` ASC'.format(device_name, date_start, date_end, exp_symbol, job_status, date_type_dict[job_status])
        data = omst_lims.Search(sql)
        table = pd.DataFrame(data, columns=['ID','Task Name','Device Name','Status','Queued Datetime','Assigned Datetime','Finished Datetime','Exp. No.','ageingTemp','ageingTime'])
    elif type == "otsukafoods":
        sql = 'SELECT `zt_arrangement`.`id`, `zt_arrangement`.`name`,`zt_arrangement`.`deviceName`, `zt_arrangement`.`status`, `zt_arrangement`.`openedDate`, `zt_arrangement`.`assignedDate`, `zt_arrangement`.`finishedDate`, `zt_story`.`experimentno`, `zt_projecttest`.`ageingTemp`, `zt_projecttest`.`ageingTime` FROM `zt_story`, `zt_arrangement`, `zt_projecttest`  WHERE (`zt_arrangement`.`storyId`=`zt_story`.`id` && `zt_arrangement`.`ptestId`=`zt_projecttest`.`id` && (`zt_arrangement`.`deviceName` LIKE "%奥兹凯%" || `zt_arrangement`.`name` LIKE "%奥兹凯%") && TO_DAYS(`zt_arrangement`.`{3}`) >= TO_DAYS("{0}") && TO_DAYS(`zt_arrangement`.`{3}`) <= TO_DAYS("{1}") && `zt_arrangement`.`status`="{2}") ORDER BY `zt_story`.`experimentno` ASC, `zt_arrangement`.`name` ASC'.format(date_start, date_end, job_status, date_type_dict[job_status])
        data = omst_lims.Search(sql)
        table = pd.DataFrame(data, columns=['ID','Task Name','Device Name','Status','Queued Datetime','Assigned Datetime','Finished Datetime','Exp. No.','ageingTemp','ageingTime'])

    return table

def report_person(person, job_status, days_ago, type="omst"):
    now = datetime.datetime.now()
    date_start = (now - datetime.timedelta(days=days_ago)).strftime('%Y-%m-%d')
    date_end =  now.strftime('%Y-%m-%d')
    job_type = "FINISHED" if job_status == "done" else "QUEUED"
    datetime_label = "Queued Datetime" if job_status == "wait" else "Finished Datetime"
    
    if days_ago == 0:
        title = "All the {0} tests on {1}:\n".format(job_type, str(date_end))
    else:
        title = "All the {0} tests from {1} to {2}:\n".format(job_type, str(date_start), str(date_end))

    if type == "omst":
        tables = []
        exp_symbol = members_dicts("exp_No", person)
        devices = ["Akron磨耗机", "DIN磨耗机", "DMA", "DynaMess", "TGA", "摆式摩擦仪", "比重仪", "常温持粘力机", "屈挠疲劳机",
                    "刺扎试验机", "动态切割试验机", "电阻仪", "回弹仪", "拉伸疲劳机", "拉伸试验机Zwick", "拉伸试验机Tinuis", 
                        "流变仪", "门尼机","摆式摩擦仪", "摩擦系数仪", "磨耗机", "气密性试验机", "热老化箱", "炭黑分散度仪",
                        "硬度计", "Others", "外送", "滚筒疲劳机（青岛）", "送ZOC", "送奥兹凯", "压缩生热（阳谷）"]
        for device_name in devices:
            table = data_inquire(date_start, date_end, job_status, type, exp_symbol, device_name)
            if not table.empty:
                tables.append(table)
            results = pd.DataFrame() if tables == [] else pd.concat(tables, axis=0, ignore_index=True)[['Device Name','Exp. No.','Task Name','ageingTemp','ageingTime', datetime_label]]
    elif type == "otsukafoods":
        table = data_inquire(date_start, date_end, job_status, type)
        results = pd.DataFrame() if table.empty else table[['Device Name','Exp. No.','Task Name','ageingTemp','ageingTime', datetime_label]].copy()

    if results.empty:
        results = pd.DataFrame([["None","None","None","None","None"]], 
                                columns= ['Device Name','Exp. No.','Task Name','Ageing Condition', datetime_label])
    else:
        results['ageingTemp'] = results['ageingTemp'].str.extract('(\d*)')
        results['ageingTime'] = results['ageingTime'].str.extract('(\d*)')
        results['Ageing Condition'] = [str(temperature) + "°C x " + str(time) + "h" if (temperature != '' and time != '') else 'None' for temperature,time in zip(results['ageingTemp'].values, results['ageingTime'].values)]
        results = results[['Device Name','Exp. No.','Task Name','Ageing Condition', datetime_label]]

    results.index = results.index + 1

    return title, results

def report_send(person, type="omst"):
    (finished_title, finished_results) = report_person(person, job_status="done", days_ago=0, type=type)
    (queued_title, queued_results) = report_person(person, job_status="wait", days_ago=29, type=type)
    data_frame_settings()
    html_finished_results = finished_results.to_html(bold_rows=False, border=1)
    html_queued_results = queued_results.to_html(bold_rows=False, border=1)
    if type == "omst":
        introduction = "Dear {}: </br>&nbsp&nbsp  The latest status of your experiments is listed as follows:</br></br>".format(members_dicts("full_name", person))
        comments = "</br> ** All the above information is collected from the OMST LIMS Database (http://192.168.0.104/lp.php) **"
        subject = "[LIMS] Daily Experiment Status Report (OMST)"
    elif type == "otsukafoods":
        introduction = "Dear {}: </br>&nbsp&nbsp  The latest status of the experiments delegated to the OtsukaFoods is listed as follows:</br></br>".format(members_dicts("full_name", person))
        comments = "</br> ** All the above information is collected from the OMST LIMS Database (http://192.168.0.104/lp.php) **"
        subject = "[LIMS] Daily Experiment Status Report (OtsukaFoods)"

    html_finished_results = "<head><b><font color='green'>" + finished_title + "</font></b></head></br>" + html_finished_results
    html_queued_results = "</br>" + "<head><b><font color='red'>" + queued_title + "</font></b></head>" + html_queued_results
    html_results = introduction + html_finished_results + html_queued_results + comments
    
    #print(finished_results)
    #print(queued_results)
    #print(html_finished_results)
    sendMail(subject, html_results, person)


# Send LIMS reports to all OMST researchers
for person in ["tian", "yan", "wang", "zhan", "jinqu"]:
    report_send(person)
# report_send("yuan")

# Send experiment tasks to the Otsukafoods (Xu, Yinyin)
report_send("xuyinyin", "otsukafoods")
report_send("zhang", "otsukafoods")
report_send("yuan", "otsukafoods")

