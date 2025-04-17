
import subprocess
import os
import time
import sys


class filename_class:
	def __init__(self, fullpath):
		fullpath=fullpath.replace('\\','/')
		self.re_path_temp = re.match(r".+/", fullpath)
		if self.re_path_temp:
			self.path = self.re_path_temp.group(0) #包括最后的斜杠
		else:
			self.path = ""
		self.name = fullpath[len(self.path):]
		self.name_stem = self.name[:self.name.rfind('.')] # not including "."

		self.append = self.name[len(self.name_stem)-len(self.name)+1:]
		self.only_remove_append = self.path+self.name_stem  # not including "."

	def replace_append_to(self,new_append):
		return self.only_remove_append+'.'+new_append


input_filenames=[]
specified_queue = ""
if len(sys.argv)>1:
	input_filenames = sys.argv[1:]
		
if not input_filenames:
	print("Filenames (end with empty line):")
	while True:
		input_filename = input()
		if input_filename:
			input_filenames.append(input_filename)
		else:
			break



def split_list(input_list:list,separator,lower_case_match = False,include_separator = False,include_separator_after=False, include_empty = False):
    '''

    :param input_list:
    :param separator: a separator, either a str or function. If it's a function, it should take a str as input, and return
    :param lower_case_match:
    :param include_separator:
    :param include_empty:
    :return:
    '''
    ret = []
    temp = []

    if include_separator or include_separator_after:
        assert not (include_separator and include_separator_after), 'include_separator and include_separator_after can not be True at the same time'

    for item in input_list:

        split_here_bool = False
        if callable(separator):
            split_here_bool = separator(item)
        elif isinstance(item,str) and item == separator:
            split_here_bool = True
        elif lower_case_match and isinstance(item,str) and item.lower() == separator.lower():
            split_here_bool = True


        if split_here_bool:
            if include_separator_after:
                temp.append(item)
            ret.append(temp)
            temp = []
            if include_separator:
                temp.append(item)
        else:
            temp.append(item)
    ret.append(temp)

    if not include_empty:
        ret = [x for x in ret if x]

    return ret

for file in input_filenames:

	with open(file) as output_file_object:
		output_lines = output_file_object.readlines()

	output_steps = split_list(output_lines,lambda x:'Normal termination of Gaussian 09 ' in x,include_separator_after = True)
	
	output_steps_process = []
	for step in output_steps:
		if output_steps_process and True in ['Proceeding to internal job step' in x for x in step[:20]]:
			output_steps_process[-1] = output_steps_process[-1]+step
		else:
			output_steps_process.append(step)
	
	output_steps = output_steps_process
	
	output_filenames = []

	for step_count,step in enumerate(output_steps):
		chkfile_filename = ""
		for count,line in enumerate(step):
			if "%chk" in line:
				chkfile_filename+=(line.strip().lstrip('%chk='))
				for chk_lines in step[count+1:]:
					if '.chk' in chkfile_filename:
						break
					chkfile_filename+=chk_lines.strip()
				break
		chkfile_filename=chkfile_filename.strip()
		if chkfile_filename:
			output_filenames.append(os.path.join(filename_class(file).path, filename_class(chkfile_filename).name_stem+'.log'))
		else:
			output_filenames.append(filename_class(file).only_remove_append+'[Split'+str(step_count)+'].log')
	
	print(len(output_steps))
	
	for step_count,step in enumerate(output_steps):
		if output_filenames.count(output_filenames[step_count])>1:
			output_filename = filename_class(output_filenames[step_count]).only_remove_append+'[Split'+str(step_count)+'].log'
		else:
			output_filename = output_filenames[step_count]
		if filename_class(file).name == filename_class(output_filename).name:
			output_filename = filename_class(output_filenames[step_count]).only_remove_append+'[Split'+str(step_count)+'].log'
		with open(output_filename,'w') as output_file:
			output_file.write("".join(step))
			print(len(step),output_filename)
	





















