#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Author:      heidanine
# File:        checkWapIp.py
# Modified:  2022/02/11 01:40  by Jianyong Yuan
#
###########################################
# 检测外网的Ip，发送到指定邮箱
###########################################
# 初期设置：
#    1. 填写 myMail -> 发件人邮箱哦
#    2. 填写 mySmtp -> host 发邮件的smtp服务器。 user/pwd 用户名和密码
#    3. 填写 testUrlParams -> 这个除了保留的地址，你可以多找几个，防止哪个网站不好用了。
# 测试脚本可否执行：
#    python checkWanIp.py
#    如果没什么问题就可以把这个脚本的执行交给cron了。
# 配置cron(需要root权限),每10分钟检测一次,可自己按习惯定。
#    crontab -e
#    输入:
#         */10 * * * *  python3  checkWapIp.py 
#
# 早上7点到下午17点之间，每隔一小时检测一次
# 0 7-17/2 * * * python3  checkWapIp.py

import os
import time
import http.client
import urllib
import urllib.request
import smtplib
from email.mime.text import MIMEText

################
# 我发邮件的邮箱地址
myMail = "omst_system@163.com"
################
# 收件人邮箱地址
toMailList= ['404283110@qq.com'\
            ,'zhanbicai@cn.otsuka.com'\
            ,'xychina.jia@gmail.com'\
]
################
# 发邮件的SMTP服务器设置
mySmtp = {"host": "smtp.163.com"\
     ,"user": "omst_system"\
     ,"pwd": "JSKXKEHJCHXZFPMU"\
}

################
#检测外网IP的网站列表
testUrlParams = [{'domain': 'ifconfig.me', 'uri': '/ip'}\
                ,{'domain': 'icanhazip.com', 'uri': ''}\
                ]
# log文件名
logFileName = 'checkWanIp.log'
# log初始内容
logList = ['']
# 保存上次IP信息的文件
lastInfoFileName = '.lastInfo'

def getWanIpInfo():
    '''
    取得外网IP
    '''
    ipInfo = ['']
    for urlParam in testUrlParams:
        ipInfo.append("\n----------")
        ipInfo.append("\nTest Server: http://" + urlParam['domain'] + urlParam['uri'])
        
        ip = str(getRequestIpInfo(urlParam), encoding="utf-8")    # 字节转字符串
        
        if ip is None:
            ipInfo.append("\nTest Result: Failed!")
            ipInfo.append("\n----------\n")
        else:
            ipInfo.append("\nTest Result: OK!")
            ipInfo.append("\nCurrent IP:  ")
            ipInfo.append(ip)
            ipInfo.append("\n----------\n")
            return "".join(ipInfo)

def getRequestIpInfo(urlParam):
    '''
    从指定的测试IP的网站得到当前电脑所在网络的外网IP
    param['domain'] : 域名 (用httplib这个包访问不要加"http://")
    param['uri'] : URI
    '''
    global logList
    ip = None
    try:
        con = http.client.HTTPConnection(urlParam['domain'])
        con.request('GET', urlParam['uri'])
        res = con.getresponse()
        if res.status == 200 :
            ip = res.read()
        con.close()
    except Exception as e:
        logList.append(str(e))
    return ip  # ip 为字节，不是字符串！

def sendMail(subject, info):
    '''
    发送邮件到指定的邮箱
    subject: 主题
    info:  邮件内容
    '''
    global logList
    msg = MIMEText(info)
    msg['Subject'] = subject
    msg['From'] = myMail
    msg['To'] = ";".join(toMailList)
    
    try:
        s = smtplib.SMTP()
        s.connect(mySmtp['host'])
        s.login(mySmtp['user'], mySmtp['pwd'])
        s.sendmail(myMail, toMailList, msg.as_string())
        s.close()
        return True
    except Exception as e:
        logList.append(str(e))
        return False

def readFile(fileName):
    '''
    读文件内容
    '''
    global logList
    try:  
        # 打开文件读取文件内容
        f = open(fileName, 'r')
        try:
            return f.read()
        finally:
            f.close()
    except IOError:
        logList.append("\n" + fileName + " - Can't open the file! Your maybe first run the script, or confirm the Read permission!")
        return None

def writeFile(fileName, str):
    return writeFileByMode(fileName, str, 'w') # 写入模式

def writeLog(str):
    '''
    写Log文件
    '''
    print(str)
    return writeFileByMode(logFileName, str, 'a') # 追加模式

def writeFileByMode(fileName, str, mode):
    '''
    写文件内容
    '''
    global logList
    if mode is None:
        mode = 'w' # 默认写模式
    try:
        # 写入文件内容
        f= open(fileName, mode)
        try:
            f.write(str)
            return True
        finally:
            f.close()
    except IOError:
        logList.append("\n" + fileName + " - Can't write the file! Please confirm the write permission")
        return False

if __name__ == '__main__':
    try:
        # 从网站上取得IP
        ipInfo = getWanIpInfo()
        logList.append(ipInfo)
        
        #读取上次保存的内容
        lastInfo = readFile(lastInfoFileName)

        # 判断和上次取得的内容是否有变化    
        if lastInfo == ipInfo: 
            timeStr = time.strftime('%Y-%m-%-d %H:%M:%S', time.localtime(time.time()))
            logList.append("\nDatetime: " + timeStr + "\n" + ":) IP is not changed!")
            logList.append("\n##########################\n")
            writeLog("".join(logList))
        else:
            # 把取得的内容存入文件中，下次用来进行比较
            writeFile(lastInfoFileName, ipInfo)
            logList.append("\n\nWrite new IP to '" + lastInfoFileName + "'")
            # 取得开始时间字符串
            timeStr = time.strftime('%Y-%m-%-d %H:%M:%S', time.localtime(time.time()))
            # 设置邮件主题
            subject = '[OSRI] Reminder: The IP of the OSRI-VPN is changed!'
            # 发送到指定邮箱
            sendMail(subject, timeStr + '\n' + ipInfo)
            #写入log
            logList.append("\n Datetime: " + timeStr)
            logList.append("\n Subject: " + subject)   
            logList.append("\n Send mail ok!")
            logList.append("\n##########################\n")
            writeLog("".join(logList))
    except Exception as e:
        writeLog(str(e))
        
        
        
