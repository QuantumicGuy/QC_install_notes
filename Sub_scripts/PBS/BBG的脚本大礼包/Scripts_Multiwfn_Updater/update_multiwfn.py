import requests
import re
import os
import shutil
import time
from unrar import rarfile

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4252.0 Safari/537.36'}
months = {'Jan':'01','Feb':'02','Mar':'03','Apr':'04','May':'05','Jun':'06','Jul':'07','Aug':'08','Sep':'09','Oct':'10','Nov':'11','Dec':'12'}

def compare_update_time(url, path):
	html = requests.get(url+'download.html').text
	last_update = re.search('Last update: \d+-\w+-\d+', html).group().split(': ')[1]
	month = months[last_update.split('-')[1]]
	new_time = last_update.split('-')[0] + '-' + month + '-' + last_update.split('-')[2]
	# print(time.strptime(new_time,'%Y-%m-%d'))

	now_time = os.path.getmtime(os.path.join(path,'Multiwfn.exe'))
	# print(time.gmtime(now_time))

	if time.strptime(new_time,'%Y-%m-%d') != time.gmtime(now_time):
		print('Your Multiwfn is not up-to-date.')
		time.sleep(1)
		print('The package of Win64 version and manual is downloading......')
		time.sleep(1)
		delete_rename_old_settings(path)
		get_package(url)
		release_rar_file(path)
		modify_settings(path)
		get_manual(url)

def get_manual(url):
	print('Starting downloading the manual......')
	html = requests.get(url+'download.html').text
	# print(html)
	pdf = re.search('href=".*?\.pdf"', html)
	pdf_url = url + pdf.group().split('"')[1]
	# print(pdf_url)

	with open(os.path.join(path, 'Multiwfn_manual.pdf'), 'wb') as f:
		content = requests.get(pdf_url).content
		f.write(content)

	print('Manual download complete.')

def get_package(url):
	print('Starting downloading the pacakge......')
	html = requests.get(url+'download.html').text
	package = re.search('href=".*?Win64\.rar"', html)
	package_url = url + package.group().split('"')[1]
	# print(package_url)

	with open(os.path.join(path, 'Multiwfn_package.rar'), 'wb') as f:
		content = requests.get(package_url).content
		f.write(content)

	print('package download complete.')

def delete_rename_old_settings(path):
	shutil.rmtree(os.path.join(path,'examples'))
	for i in os.listdir(path):
		if i == 'settings.ini':
			os.rename(os.path.join(path,'settings.ini'), os.path.join(path,'settings_old.ini'))
		else:
			os.remove(os.path.join(path,i))

def release_rar_file(path):
	print('Starting release the rar file......')
	file = rarfile.RarFile(os.path.join(path,'Multiwfn_package.rar'))
	file.extractall(path)
	os.remove(os.path.join(path,'Multiwfn_package.rar'))

	for i in os.listdir(path):
		if i != 'settings_old.ini':
			folder = os.path.join(path, i)
			print(folder)
			for i in os.listdir(folder):
				# print(i)
				shutil.move(os.path.join(path,folder,i),path)

	os.rename(os.path.join(path,'settings.ini'), os.path.join(path,'settings_new.ini'))
	empty_folder = os.listdir(path)
	# print(empty_folder)
	for i in empty_folder:
		if 'Win64' in i:
			shutil.rmtree(os.path.join(path,i))

	print('Release the rar file complete.')


def modify_settings(path):
	with open(os.path.join(path, 'settings_new.ini'), 'r') as new:
		with open(os.path.join(path, 'settings_old.ini'), 'r') as old:
			new_data = new.readlines()
			old_data = old.readlines()

			new_list = []

			for i in new_data:
				for j in old_data:
					if i == j:
						if i == '\n':
							pass
						else:
							new_list.append(i)
					elif i.split('//')[0] != '':
						if i.split('//')[0].split('=')[0] == j.split('//')[0].split('=')[0]:
							new_list.append(j)

			# print(new_list)
			with open(os.path.join(path, 'settings.ini'),'a') as f:
				for i in new_list:
					f.write(i)

	os.remove(os.path.join(path, 'settings_old.ini'))
	os.remove(os.path.join(path, 'settings_new.ini'))

if __name__ == '__main__':
	print('Welcome to the automatic update script for Multiwfn.')
	print('Auther: I was a baby.')
	time.sleep(1)
	path = 'D:\\Multiwfn'
	url = 'http://sobereva.com/multiwfn/'
	compare_update_time(url,path)
	time.sleep(1)
	print('Congratulations! Your Multiwfn is up-to-date.\n')