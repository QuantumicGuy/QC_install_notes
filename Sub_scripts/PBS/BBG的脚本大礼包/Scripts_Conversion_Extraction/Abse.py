#!/usr/bin/env python3
# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import argparse
import basis_set_exchange as bse
from collections import defaultdict, Counter
import datetime
import numpy as np
import glob
import copy
import re
import sys
import os

parser=argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
                               description='extract/filter basis set from basis set exchange\n'
                               'estimate the cost of Gaussian inp file with given Basis set\n'
                               'Append basis set or gbs file to gjf file')
parser.add_argument("-f",dest='inpfile',metavar='inpfile',type=str,default='',
                    help='gjf file, elements info from which will be read\n'
                         'Sperate multiple files by comma, * and ? are supported')
parser.add_argument("-e",dest='element',metavar='element',default='',type=str,
                    help = 'Seperate multiple elements by comma, e.g. c,h,o,n\n'
                           'atomic number could be used with comma and hyphen, e.g. 1-7,10-12,14\n'
                           'basis set of which will be extracted\n')
parser.add_argument("-b",dest='basis',metavar='basis',default='',type=str,
                    help='basis set name to extract\n'
                         'This name is case insensitive\n'
                         'If you are not sure about exact name\n'
                         'use -l option to list basis set satisfy certain condition\n'
                         'note that calender basis set such as may-cc-pvdz are supported although they are not listed\n'
                         'if using different basis for different names\n'
                         'use format like 6-31g*;Hg,Cl,Br:def2-tzvp;ecp:lanl08;ecp:Hg:cc-pVTZ-PP\n')
parser.add_argument("-l",dest='list',metavar='list',default='',type=str,
                    help='list basis satisfy certain conditions\n'
                         'the format is -l "s:svp;f: r:orbital;t:e" where s for substr, f for family, r for role, t for type\n'
                         'available roles are orbital optri rifit jkfit jfit dftxfit dftjfit admmfit guess\n'
                         'available types are gto(g) gto_spherical(gs) gto_cartesian(gc) scalar_ecp(e), noecp, nogto\n'
                         'available families could be listed as --list-families\n')
parser.add_argument("-o",dest='output',metavar='output',default='',type=str,
                    help='gjf, gbs, gjfgbs, ref,or other format\n'
                         'gjf write to gjf directly, replace [autobse] or append at end of gjf\n'
                         'gbs will write basis set in gaussian format to autobse.gbs file\n'
                         'gbs: will write basis set to screen\n'
                         'orca: will write basis set in orca format to screen\n'
                         'gbs:abc will write basis set to abc.gbs file\n'
                         'gjfgbs[:autobse.gbs] write basis set to autobse.gbs file and generate @gbs line in gjf\n'
                         'ref[:format][:autobse.ref] will written reference of basis set to autobse.ref file\n '
                         'other format write basis set starts with correspond name to file\n'
                         'e.g. psi4 will write basis to autobse.psi4 and psi4:abc.txt will write basis to abc.txt\n'
                         'use --list-formats to view available formats')
parser.add_argument("-a",dest='appendstr',metavar='appendstr',default='',type=str,
                    help='some string that will append to file name. If not set, origin gjf file will be overwritten')
parser.add_argument("-i",dest='inspect',metavar='inspect',default='',type=str,
                    help='inspect information of a basis set or a basis family\n'
                         'you could input a substring of basis name like svp to list all basis contain that string\n')
parser.add_argument("--list-roles",dest='lroles',action="store_true",
                    help='Output a list all available roles and descriptions')
parser.add_argument("--list-formats",dest='lformats',action="store_true",
                    help='Output a list of basis set formats that can be outputted')
parser.add_argument("--list-ref-formats",dest='lrformats',action="store_true",
                    help='Output a list of basis set reference formats that can be outputted')
parser.add_argument("--list-families",dest='lfamilies',action="store_true",
                    help='Output a list all available basis set families')
parser.add_argument("--basis_options",dest='basis_options',metavar='',default='',type=str,
                    help='set following options to True, if those keywords is present\n'
                    'ucontract_general,uncontract_spdf,uncontract_segmented,make_general,optimize_general')
parser.add_argument("--version",action="version",version='%(prog)s 1.0')
args=parser.parse_args()

class AutoBSE:
    def __init__(self):
        self.elem = []
        self.basis = ''
        self.basis_options = {'uncontract_general':False,'uncontract_spdf':False,
                              'uncontract_segmented':False,'make_general':False,
                              'optimize_general':False}
        self.file2elem = {}
        self.elem2basis_info = {}

        self._elem2an = {'H': 1, 'He': 2, 'Li': 3, 'Be': 4, 'B': 5, 'C': 6, 'N': 7,
                     'O': 8, 'F': 9, 'Ne': 10, 'Na': 11, 'Mg': 12, 'Al': 13,
                     'Si': 14, 'P': 15, 'S': 16, 'Cl': 17, 'Ar': 18, 'K': 19,
                     'Ca': 20, 'Sc': 21, 'Ti': 22, 'V': 23, 'Cr': 24, 'Mn': 25, 'Fe': 26,
                     'Co': 27, 'Ni': 28, 'Cu': 29, 'Zn': 30, 'Ga': 31, 'Ge': 32,
                     'As': 33, 'Se': 34, 'Br': 35, 'Kr': 36, 'Rb': 37, 'Sr': 38,
                     'Y': 39, 'Zr': 40, 'Nb': 41, 'Mo': 42, 'Tc': 43, 'Ru': 44,
                     'Rh': 45, 'Pd': 46, 'Ag': 47, 'Cd': 48, 'In': 49, 'Sn': 50,
                     'Sb': 51, 'Te': 52, 'I': 53, 'Xe': 54, 'Cs': 55, 'Ba': 56,
                     'La': 57, 'Ce': 58, 'Pr': 59, 'Nd': 60, 'Pm': 61, 'Sm': 62,
                     'Eu': 63, 'Gd': 64, 'Tb': 65, 'Dy': 66, 'Ho': 67, 'Er': 68,
                     'Tm': 69, 'Yb': 70, 'Lu': 71, 'Hf': 72, 'Ta': 73, 'W': 74,
                     'Re': 75, 'Os': 76, 'Ir': 77, 'Pt': 78, 'Au': 79, 'Hg': 80,
                     'Tl': 81, 'Pb': 82, 'Bi': 83, 'Po': 84, 'At': 85}
        self._an2elem = {v: k for k, v in self._elem2an.items()}

    def read_file(self,inpfile):
        file_list = []
        elems = []
        for f in inpfile.strip().split(','):
            file_list += glob.glob(f)
        if len(file_list) == 0:
            print('Error!!! no file found by option "-f {:s}"'.format(inpfile))
            sys.exit()
        for f in file_list:
            atoms = self.read_gjf(f)
            if len(atoms) == 0:
                print('Error!!! No elements found in file {:s}'.format(f))
                sys.exit()
            elems += atoms
            self.file2elem[f] = Counter(atoms)
        self.elem = list(set(elems))

    def an2elem(self):
        '''convert atomic number to element string, remove non-existing elems'''
        elem = []
        for e in self.elem:
            if str(e).isdigit():
                elem.append(self._an2elem[int(e)])
            elif '-' in str(e):
                begin,end = [int(i) for i in e.split('-')]
                elem += [self._an2elem[i] for i in range(begin,end+1)]
            else:
                if str(e).capitalize() in self._elem2an:
                    elem.append(str(e).capitalize())
                else:
                    print('Waring!!! omit unrecognized elements {:s}'.format(str(e)))
        self.elem = elem

    def add_basis2gjf(self,append_str=''):
        for file,ele_count in self.file2elem.items():
            elem = [i for i in ele_count.keys()]
            # check 5D and 6D basis
            df = [self.elem2basis_info[e]['DF'] for e in elem]
            dfstr=[]
            if '6D' in df and '5D' not in df:
                dfstr.append("6D")
            elif '5D' in df and '6D' in df:
                print('Warning!!! mixing of 6D and 5D basis set for file {:s}'.format(file))
            if '10F' in df and '7F' not in df:
                dfstr.append("10F")
            elif '7F' in df and '10F' in df:
                print('Warning!!! mixing of 7F and 10F basis set for file {:s}'.format(file))
            outbasis = copy.deepcopy(self.outbasis)
            del_elem = []
            for an in outbasis['elements'].keys():
                e = str(self._an2elem[int(an)])
                if e not in elem:
                    del_elem.append(an)
            for an in del_elem:
                del outbasis['elements'][an]
            basis_str = bse.write_formatted_basis_str(outbasis,'gaussian94').strip()
            abspath = os.path.abspath(file)
            fldir,flnm = os.path.split(abspath)
            basename,ext = os.path.splitext(flnm)
            with open(file,'r') as gjf:
                file_str = gjf.read().strip()
            if 'gen' not in file_str.lower() and 'genecp' not in file_str.lower():
                print('Warning!!! keywords gen or genecp not found in file {:s}. You shoud check this file'.format(file))
            if dfstr:
                for dfs in dfstr:
                    if dfs.lower() not in file_str.lower():
                        print('Warning!!! keywords {:s} required but not found in file {:s}. '
                              'I will try to add this keywords'.format(dfs,file))
                        file_str=re.sub(r'(#[pP]?)\s*',r'\1 '+dfs+' ',file_str) 
            if '[autobse]' in file_str:
                new_fstr = file_str.replace('[autobse]',basis_str)
            elif '****' not in file_str:
                new_fstr = file_str + "\n" + "\n" + basis_str
            else:
                print('Error!!! It seems that gjf file {:s} already have a basis set. Exit now'.format(file))
                sys.exit()
            new_fstr += "\n\n\n"
            if append_str:
                basename = basename + append_str
            new_file = os.path.join(fldir,basename+ext)
            print('Add basis set to {:s}'.format(new_file))
            with open(new_file,'w') as new_gjf:
                new_gjf.write(new_fstr)

    def add_gbs2gjf(self,append_str='',gbs_name='autobse.gbs'):
        if not gbs_name:
            print('Since not gbs file is generated. I will not modify gjf file')
            return
        if '.' not in gbs_name:
            gbs_name += '.gbs'
        gbs_str="@"+gbs_name
        for file,ele_count in self.file2elem.items():
            elem = [i for i in ele_count.keys()]
            df = [self.elem2basis_info[e]['DF'] for e in elem]
            dfstr=[]
            if '6D' in df and '5D' not in df:
                dfstr.append("6D")
            elif '5D' in df and '6D' in df:
                print('Warning!!! mixing of 6D and 5D basis set for file {:s}'.format(file))
            if '10F' in df and '7F' not in df:
                dfstr.append("10F")
            elif '7F' in df and '10F' in df:
                print('Warning!!! mixing of 7F and 10F basis set for file {:s}'.format(file))
            abspath = os.path.abspath(file)
            fldir,flnm = os.path.split(abspath)
            basename,ext = os.path.splitext(flnm)
            with open(file,'r') as gjf:
                file_str = gjf.read().strip()
            if 'gen' not in file_str.lower() or 'genecp' not in file_str.lower():
                print('Warning!!! keywords gen or genecp not found in file {:s}. You shoud check this file'.format(file))
            if dfstr:
                for dfs in dfstr:
                    if dfs.lower() not in file_str.lower():
                        print('Warning!!! keywords {:s} required but not found in file {:s}. '
                              'I will try to add this keywords'.format(dfs,file))
                        file_str=re.sub(r'(#[pP]?)\s*',r'\1 '+dfs+' ',file_str) 
            if '[autobse]' in file_str:
                new_fstr = file_str.replace('[autobse]',gbs_str)
            elif '****' in file_str or '@' in file_str:
                print('Error!!! It seems that gjf file {:s} already have a basis set or file inclusion. Exit now'.format(file))
                sys.exit()
            else:
                new_fstr = file_str + "\n" + "\n" + gbs_str
            new_fstr += "\n\n\n"
            if append_str:
                basename = basename + append_str
            new_file = os.path.join(fldir,basename+ext)
            print('Add {:s} to {:s}'.format(gbs_str,new_file))
            with open(new_file,'w') as new_gjf:
                new_gjf.write(new_fstr)

    def gen_gbs(self,gbs_name='autobse.gbs'):
        '''generate gbs file for gaussian'''
        basis_str = bse.write_formatted_basis_str(self.outbasis,'gaussian94')
        lines = []
        for line in basis_str.split('\n'):
            if len(line.split()) == 2:
                if line.split()[0].capitalize() in self.elem and line.split()[1] == '0':
                    line = '-'+line.strip()
            lines.append(line)
        basis_str='\n'.join(lines).strip()
        if not gbs_name:
            print(basis_str)
        else:
            if '.' not in gbs_name:
                gbs_name += '.gbs'
            print("Saving gbs file {:s} ...".format(gbs_name))
            with open(gbs_name,'w') as gbs:
                gbs.write(basis_str.strip())

    def parser_basis_spec(self):
        '''requires self.elem and self.basis generate a dict self.elem2basis_name
        and self.elem2basis_str
        '''
        raw_list = self.basis.split(';')
        general_basis = [i for i in raw_list if ':' not in i][-1]
        try:
            general_ecp = [i for i in raw_list if i.startswith('ecp:') and len(i.split(':'))==2][-1].split(':')[-1]
        except:
            general_ecp = ''
        elem_basis = [i for i in raw_list if ':' in i and 'ecp:' not in i]
        elem_ecp = [i for i in raw_list if i.startswith('ecp:') and len(i.split(':'))==3]
        if len(self.elem) == 0:
            print('Error!!! No elements available. You must have at least one element to set basis')
            sys.exit()
        for e in self.elem:
            self.elem2basis_info[e]=defaultdict(str, {'shell':general_basis, 'ecp':general_ecp})
        for eb in elem_basis:
            es,b = eb.split(':')
            for e in es.split(','):
                e=e.capitalize()
                if e in self.elem2basis_info:
                    self.elem2basis_info[e]['shell'] = b
        for ee in elem_ecp:
            _,es,ecp = ee.split(':')
            for e in es.split(','):
                e=e.capitalize()
                if e in self.elem2basis_info:
                    self.elem2basis_info[e]['ecp'] = ecp
        self.basis2elem = defaultdict(str,{})
        for e,v in self.elem2basis_info.items():
            if v['shell'] not in self.basis2elem:
                self.basis2elem[v['shell']] = defaultdict(list,{'shell':[e]})
            else:
                self.basis2elem[v['shell']]['shell'].append(e)
            if v['ecp']:
                if v['ecp'] not in self.basis2elem:
                    self.basis2elem[v['ecp']] = defaultdict(list,{'ecp':[e]})
                else:
                    self.basis2elem[v['ecp']]['ecp'].append(e)

    def get_basis(self,name,elem,fmt='',shell=''):
        '''this is wrapper of bse.get_basis but can do modifications to Dunning-style basis sets'''
        #extend = bse.manip.extend_dunning_aug
        calend = bse.manip.truhlar_calendarize
        ex_aug = {'d-aug-':2,'t-aug-':3,'q-aug-':4}
        calend_aug = {'jul-cc':'jul','jun-cc':'jun','may-cc':'may','apr-cc':'apr','mar-cc':'mar','feb-cc':'feb'}
        # if name[:6].lower() in ex_aug:
            # raw_dict = bse.get_basis(name=name[6:], elements=elem,  header=False)
            # basis_dict=extend(raw_dict,level=ex_aug[name[:6]])
        if name[:6].lower() in calend_aug:
            raw_dict = bse.get_basis(name='aug-'+name[4:], elements=elem, **self.basis_options,header=False)
            basis_dict=calend(raw_dict,month=calend_aug[name[:6]])
        else:
            basis_dict = bse.get_basis(name=name, elements=elem, **self.basis_options,header=False)
        # for b in basis_dict['elements']['14']['electron_shells']:
        #     print(b)

        basis_string = bse.write_formatted_basis_str(basis_dict,fmt='gaussian94')
        # print(basis_string)
        return basis_dict

    def check_basis(self):
        '''this function generate basis in Gaussian format and create dictionary self.elem2basis_str which
        seperate gto and ecp'''
        self.basis2dict = {}
        self.outbasis = {'elements':{},'function_types':[]}
        for bn,v in self.basis2elem.items():
            self.basis2dict[bn] = {}
            shell_elem = v['shell']
            ecp_elem = v['ecp']
            self.basis2dict[bn]['shell'] = self.get_basis(name=bn, elem=shell_elem)
            self.outbasis['function_types'] += self.basis2dict[bn]['shell']['function_types']
            if ecp_elem:
                self.basis2dict[bn]['ecp'] = self.get_basis(name=bn, elem=ecp_elem)
                self.outbasis['function_types'] += self.basis2dict[bn]['ecp']['function_types']
        self.outbasis['function_types'] = list(set(self.outbasis['function_types']))
        a2l = {0:'s',1:'p',2:'d',3:'f',4:'g',5:'h',6:'i',7:'j'}
        l2p = defaultdict(str,{'s':1,'S':1,'P':3,'p':3,'d':5,'f':7,'D':6,'F':10,
                               'g':9,'G':15,'h':11,'H':21,'i':13,'I':28,'j':15,'J':36})

        # print(bse.write_formatted_basis_str(bd,'gaussian94'))
        for e,v in self.elem2basis_info.items():
            l2n = defaultdict(str, {'s': '', 'p': '', 'sp': '', 'd': '', 'f': '', 'g': ''})
            l2diff = defaultdict(list, {})
            num_gtf = 0
            num_bn = 0
            an = str(self._elem2an[e])
            elem_basis = {}
            self.outbasis['elements'][an] = elem_basis
            shell = v['shell']
            ecp = v['ecp']
            if 'electron_shells' not in self.basis2dict[shell]['shell']['elements'][an]:
                print("Error!!! basis set {:s} do not have shell basis for element {:s}".format(shell,e))
                sys.exit()
            else:
                bd = self.basis2dict[shell]['shell']['elements'][an]['electron_shells']
                elem_basis['electron_shells'] = bd
                # print(bd)
                for f in bd:
                    am = f['angular_momentum']
                    coefs = f['coefficients']
                    if len(coefs) > 0:
                        minexp = min([float(i) for i in f['exponents']])
                        am_str = ''.join([a2l[i] for i in am])
                        l2diff[am_str].append(minexp)
                        if f['function_type'] == 'gto_cartesian':
                            am_str=am_str.upper()
                            if am_str == 'D':
                                v['DF'] += '6D'
                            if am_str == 'F':
                                v['DF'] += '10F'
                        elif f['function_type'] == 'gto_spherical':
                            if am_str == 'd':
                                v['DF'] += '5D'
                            if am_str == 'f':
                                v['DF'] += '7F'
                        if len(coefs) > len(am) and len(am) == 1:
                            l2n[am_str] += ''.join([str(len(coefs[0])),'X',str(len(coefs)) ])
                            num_bn +=  l2p[am_str[0]] * len(coefs)
                            num_gtf += l2p[am_str[0].upper()] * sum([len([x for x in c if float(x) != 0]) for c in coefs])
                        elif len(am) > 1 and len(coefs) == len(am):
                            l2n[am_str] += str(len(coefs[0]))
                            num_bn += sum([l2p[i] for i in am_str])
                            num_gtf += sum([l2p[i.upper()] for i in am_str]) *len(coefs[0])
                        elif len(am) == 1 and len(coefs) == 1:
                            num_bn += sum([l2p[i] for i in am_str]) * len(coefs)
                            num_gtf += sum([l2p[i.upper()] for i in am_str]) * len(coefs)*len(coefs[0])
                            if 'X' in l2n[am_str]:
                                l2n[am_str] += '+'+''.join([str(len(i)) for i in coefs])
                            else:
                                l2n[am_str] += ''.join([str(len(i)) for i in coefs])
                        else:
                            print('Error! basis format could not be parsed. Please contact author: ggdhzdx@qq.com')
                v['bn'] = int(num_bn)
                v['gf'] = int(num_gtf)
                v['bfgp'] = str(num_bn)+'/'+str(num_gtf)
                l2diff_str = []
                for l,exp in l2diff.items():
                    if min(exp) < 1:
                        l2diff_str.append(l +'{:<4.1f}'.format(min(exp)*100))
                shell_order = ['s','p','d','f','g','h','i','j']
                v['diff'] = ' '.join(sorted(l2diff_str,key=lambda x:shell_order.index(x[0])))
                l2n_str = []
                for l,n in l2n.items():
                    if n:
                        l2n_str.append(l+n)
                v['compose'] = ','.join(l2n_str)
            if not ecp:
                if 'ecp_potentials' in self.basis2dict[shell]['shell']['elements'][an]:
                    v['ecp'] = shell
                    v['ecp_ele'] = self.basis2dict[shell]['shell']['elements'][an]['ecp_electrons']
                    elem_basis['ecp_potentials'] = self.basis2dict[shell]['shell']['elements'][an]['ecp_potentials']
                    elem_basis['ecp_electrons'] = self.basis2dict[shell]['shell']['elements'][an]['ecp_electrons']
            else:
                if 'ecp_potentials' not in self.basis2dict[ecp]['ecp']['elements'][an]:
                    print('Warning!!! basis set {:s} do not have ecp for element {:s}'.format(ecp,e))
                else:
                    v['ecp_ele'] = self.basis2dict[ecp]['ecp']['elements'][an]['ecp_electrons']
                    elem_basis['ecp_potentials'] = self.basis2dict[ecp]['ecp']['elements'][an]['ecp_potentials']
                    elem_basis['ecp_electrons'] = self.basis2dict[ecp]['ecp']['elements'][an]['ecp_electrons']
            if v['ecp']:
                v['ecpne'] = v['ecp']+':'+str(v['ecp_ele'])
        print('Following basis sets have been found:')
        len_basis =  str(max([len(i['shell']) for i in self.elem2basis_info.values()]) + 4)
        len_ecp =  str(max([len(i['ecpne']) for i in self.elem2basis_info.values()]) + 2)
        len_bfgp =  str(max([len(str(i['bfgp'])) for i in self.elem2basis_info.values()]) + 4)
        len_comp =  str(max([len(i['compose']) for i in self.elem2basis_info.values()]) + 4)
        len_diff =  str(max([len(i['diff']) for i in self.elem2basis_info.values()]) + 4)
        if int(len_ecp) < 3:
            format_str = '{:6s}{:' + len_basis + 's}{:' + len_bfgp + 's}{:' + len_comp + 's}{:' + len_diff + 's}'
            print(format_str.format('elem', 'basis', 'BF/GP', 'contractions', 'min_exponents X 100'))
            for k, v in sorted(self.elem2basis_info.items(), key=lambda x:self._elem2an[x[0]]):
                print(format_str.format(k, v['shell'], str(v['bfgp']), v['compose'], v['diff']))
        else:
            format_str = '{:6s}{:'+len_basis+'s}{:'+len_ecp+'s}{:'+len_bfgp+'s}{:'+len_comp+'s}{:'+len_diff+'s}'
            print(format_str.format('elem', 'basis','ecp:ne','BN/GF','contractions','min_exponents X 100'))
            for k, v in sorted(self.elem2basis_info.items(), key=lambda x:self._elem2an[x[0]]):
                print(format_str.format(k, v['shell'], v['ecpne'],str(v['bfgp']),v['compose'],v['diff']))

    def check_system(self):
        if len(self.file2elem) > 0:
            print("DFT Time is estimated with: L502 time; PBE0; tryptophan; E5-2699V4 22core@2.6GHz;15 scf cycle")
            print("MP2 Time is estimated with: L906 time; revDSD-PBEP86-D3(BJ); histidine; E5-2699V4 22core@2.6GHz; Mem: 40GB")
            print("{:20s}{:10s}{:10s}{:20s}{:20s}{:12s}{:12s}{:12s}"
                  .format('file','BasisFunc','GauPrim','DFT Time','MP2 Time','GP^3.5','BF^5','BF^7'))
        for file,ele_count in self.file2elem.items():
            tot_bn = sum([self.elem2basis_info[k]['bn']*v for k,v in ele_count.items()])
            tot_gf = sum([self.elem2basis_info[k]['gf']*v for k,v in ele_count.items()])
            dft_time = str(datetime.timedelta(seconds=10**(np.log10(tot_gf)*3.42-7.866))).split('.')[0]
            mp2_time = str(datetime.timedelta(seconds=10**(np.log10(tot_bn)*2.60+np.log10(tot_gf)*1.86-10.085))).split('.')[0]
            gfe35 = '{:.3E}'.format(tot_gf**3.5)
            bne5 = '{:.3E}'.format(tot_bn**5)
            bne7 = '{:.3E}'.format(tot_bn**7)
            print("{:20s}{:<10d}{:<10d}{:20s}{:20s}{:<12.3E}{:<12.3E}{:<12.3E}"
                  .format(file,tot_bn,tot_gf,dft_time,mp2_time,tot_gf**3.5,tot_bn**5,tot_bn**7))

    def gen_basis(self,format='',file_name='autobse'):
        '''generate all basis with certain format, output a file or print result to screen is filename is empty'''
        basis_str = bse.write_formatted_basis_str(self.outbasis,fmt=format)
        if not file_name:
            print(basis_str)
        else:
            if '.' not in file_name:
                file_name += '.' + format
            print("Writting basis in format {:s} to file {:s} ...".format(format,file_name))
            with open(file_name,'w',encoding="utf-8") as bf:
                bf.write(basis_str.strip())

    def gen_ref(self,ref_format='txt',ref_file=''):
        basis2elem={}
        ref_list = []
        for e,be in self.elem2basis_info.items():
            gto = be['shell']
            ecp = be['ecp']
            if gto and gto not in basis2elem:
                basis2elem[gto] = [e]
            elif gto and gto in basis2elem:
                basis2elem[gto].append(e)
            if ecp and ecp not in basis2elem:
                basis2elem[ecp] = [e]
            elif ecp and ecp in basis2elem:
                basis2elem[ecp].append(e)
        for b,e in basis2elem.items():
            e = list(set(e))
            ref_list.append(bse.get_references(b,elements=e,fmt=ref_format))
        ref_str = '/n'.join(list(set(ref_list)))
        if not ref_file:
            print(ref_str)
        else:
            print("Saving reference to file {:s} ...".format(ref_file))
            with open(ref_file,'w',encoding="utf-8") as ref:
                ref.write(ref_str)

    def read_gjf(self,gjf_file):
        cs_read = 0
        atoms = []
        file = open(gjf_file,'r')
        for l in file:
            if re.match('^\s*-?\d\s+\d\s?', l) and cs_read == 0:
                cs_read = 1
                continue
            if cs_read == 1 and re.match('^\s*$', l):
                cs_read = 2
                continue
            if cs_read == 1:
                astr = l.replace(',',' ').split()[0]
                at = astr.split('(')[0]
                if at.isdigit():
                    atoms.append(self._an2elem(int(at)))
                elif at.isalpha():
                    if at.capitalize() in self._elem2an:
                        atoms.append(at.capitalize())
                    else:
                        print('Warning! omit unrecognized element {:s} in {:s}'.format(at,gjf_file))
                else:
                    print('Error! atom symbol illegal: {:s}'.format(astr))
                    break
        return atoms

    def filter_basis(self,substr,family='',role='',ftype=''):
        if not substr:
            substr=None
        if not family:
            family=None
        if not role:
            role=None
        filter_result = bse.filter_basis_sets(substr=substr,elements=self.elem,family=family,role=role)
        if ftype:
            ftype_list = []
            exclude_list = []
            s2f={'g':'gto','gs':'gto_spherical','gc':'gto_cartesian','e':'scalar_ecp','ecp':'scalar_ecp',
                 'gtoS':'gto_spherical','gtoC':'gto_cartesian'}
            for i in ftype.split(','):
                if i.startswith('no'):
                    if i[2:] in s2f:
                        exclude_list.append(s2f[i[2:]])
                    else:
                        exclude_list.append(i[2:])
                else:
                    if i in s2f:
                        ftype_list.append(s2f[i])
                    else:
                        ftype_list.append(i)
            filter_result = {k:v for k,v in filter_result.items() if all([i in v['function_types'] for i in ftype_list])}
            filter_result = {k:v for k,v in filter_result.items() if all([i not in v['function_types'] for i in exclude_list])}
        # names = [filter_result[i]['basename'] for i in filter_result]
        # family = [filter_result[i]['family'] for i in filter_result]
        # function_type = [''.join(filter_result[i]['function_types']) for i in filter_result]
        # role = [filter_result[i]['role'] for i in filter_result]
        f2s = {'gto':'gto', 'gto_spherical':'gtoS', 'gto_cartesian':'gtoC', 'scalar_ecp':'ecp'}
        info = ['{:30s}|{:15s}| {:10s}| {:10s}'.
                format(filter_result[i]['display_name'],
                       ','.join([f2s[k] for k in filter_result[i]['function_types']]),
                       filter_result[i]['role'],
                       filter_result[i]['family'])
                for i in filter_result]
        # print(set(function_type))
        # print(filter_result)
        info_header = '{:30s} {:15s}  {:10s}  {:10s}'.format('basis_set','function_type','role','family')
        print(info_header)
        for i in info:
            print(i)

    def get_basis_info(self,basis_name):
        def joinelem(elem_list):
            start = 0
            joined_elem=[]
            for e in sorted([int(i) for i in elem_list]):
                if start == 0:
                    last_e = e
                    start = e
                elif e == last_e + 1:
                    last_e = e
                else:
                    end = last_e
                    if end > start:
                        joined_elem.append(str(start)+'-'+str(end))
                    else:
                        joined_elem.append(str(start))
                    start = e
                    last_e = e
            if last_e > start:
                joined_elem.append(str(start) + '-' + str(last_e))
            else:
                joined_elem.append(str(last_e))
            return ','.join(joined_elem)
        print_info = ['display_name','latest_version','family','role']
        filter_result = bse.filter_basis_sets(substr=basis_name)
        if basis_name in bse.get_families():
            fnotes=bse.get_family_notes(basis_name)
            fb = bse.filter_basis_sets(family=basis_name)
            print(fnotes)
            print("Basis set available in the family {:s}:".format(basis_name))
            for k in fb:
                print(k)
        elif basis_name.lower() in filter_result:
            # print(filter_result[basis_name.lower()])
            for k,v in filter_result[basis_name.lower()].items():
                if k in print_info:
                    print("{:15s}:  {:s}".format(k,v))
                if k == 'function_types':
                    print("{:15s}:  {:s}".format(k,','.join(v)))
                if k == 'versions':
                    elems = v[filter_result[basis_name.lower()]['latest_version']]['elements']
                    print("{:15s}:  {:s}".format('elements',joinelem(elems)))
            print("{:15s}:  ".format('auxiliaries'),end='')
            for at,an in filter_result[basis_name.lower()]['auxiliaries'].items():
                print("{:10s}:  {:s}\n{:18s}".format(at,an," "),end="")
            print("\n")
        elif len(filter_result) > 0:
            print('The basis set name {:s} is not correct. You may mean one of the following:'
                  .format(basis_name))
            f2s = {'gto': 'gto', 'gto_spherical': 'gtoS', 'gto_cartesian': 'gtoC', 'scalar_ecp': 'ecp'}
            info = ['{:30s}| {:15s}| {:10s}| {:10s}'.
                        format(i,
                               ','.join([f2s[k] for k in filter_result[i]['function_types']]),
                               filter_result[i]['role'],
                               filter_result[i]['family'])
                    for i in filter_result]
            # print(set(function_type))
            # print(filter_result)
            info_header = '{:30s}  {:15s}  {:10s}  {:10s}'.format('basis_set name', 'function_type', 'role', 'family')
            print(info_header)
            for i in info:
                print(i)

autobse = AutoBSE()


if args.inpfile:
    autobse.read_file(args.inpfile)

if args.element:
    autobse.elem += [i.capitalize() for i in args.element.split(',')]

if len(autobse.elem) > 0:
    autobse.an2elem()

if args.basis_options:
    for i in args.basis_options.split(','):
        autobse.basis_options[i] = True

if args.basis:
    autobse.basis = args.basis
    autobse.parser_basis_spec()
    autobse.check_basis()
    autobse.check_system()

if args.list:
    if ':' not in args.list:
        args.list += ':'
    filter = defaultdict(str,{i.split(':')[0]:i.split(':')[1] for i in args.list.split(';')})
    ss=[v for k,v in filter.items() if k.lower().startswith('s')]
    fs=[v for k,v in filter.items() if k.lower().startswith('f')]
    rs=[v for k,v in filter.items() if k.lower().startswith('r')]
    ts=[v for k,v in filter.items() if k.lower().startswith('t')]
    if not ss:
        ss=['']
    if not fs:
        fs=['']
    if not rs:
        rs=['']
    if not ts:
        ts=['']
    autobse.filter_basis(substr=ss[0],family=fs[0],role=rs[0],ftype=ts[0])

if args.lroles:
    for k,v in bse.get_roles().items():
        print('{:8s} : {:s}'.format(k,v))

if args.lfamilies:
    first_letter = ''
    for k in bse.get_families():
        if first_letter and first_letter != k[0]:
            print('')
        if first_letter != k[0]:
            print(k[0].upper()+" >>>", end = ' ')
        first_letter = k[0]
        print('{:s}'.format(k), end=' ')

if args.lformats:
    for k,v in bse.get_writer_formats().items():
        print('{:10s} : {:s}'.format(k,v))

if args.lrformats:
    for k,v in bse.get_reference_formats().items():
        print('{:10s} : {:s}'.format(k,v))

if args.inspect:
    autobse.get_basis_info(args.inspect)

if args.output:
    if args.output == 'gjf':
        autobse.add_basis2gjf(append_str=args.appendstr)
    elif args.output.startswith('gbs'):
        gbs_name = 'autobse.gbs'
        if ':' in args.output:
            gbs_name = args.output.split(':')[1]
        autobse.gen_gbs(gbs_name=gbs_name)
    elif args.output.startswith('gjfgbs'):
        gbs_name = 'autobse.gbs'
        if ':' in args.output:
            gbs_name = args.output.split(':')[1]
        autobse.gen_gbs(gbs_name=gbs_name)
        autobse.add_gbs2gjf(append_str=args.appendstr,gbs_name=gbs_name)
    elif args.output.startswith('ref'):
        ref_format = 'txt'
        ref_name = 'autobse'
        if ':' in args.output:
            os = args.output.split(':')
            if len(os) == 3:
                ref_format = os[1]
                if ref_format not in ['txt','bib','ris','endnote','json']:
                    ref_format = 'txt'
                ref_name = os[2]
            if len(os) == 2:
                ref_format = os[1]
                if ref_format not in ['txt','bib','ris','endnote','json']:
                    ref_format = 'txt'
                    ref_name = os[1]
        if ref_name and '.' not in ref_name:
            ref_name = ref_name + '.' + ref_format

        autobse.gen_ref(ref_format=ref_format,ref_file=ref_name)
    else:
        file_name = 'autobse'
        if ':' in args.output:
            file_name = args.output.split(':')[1]
            basis_name = args.output.split(':')[0]
        else:
            basis_name = args.output
        avail = [i for i in bse.get_writer_formats() if i.startswith(basis_name)]
        if len(avail) == 1:
            autobse.gen_basis(format=avail[0],file_name=file_name)
        elif len(avail) > 1:
            print('Error!!! More than one format are chosed: {:s}'.format(','.join(avail)))
        else:
            print('-o option {:s} not recognized'.format(args.output))

# print(bse.get_writer_formats())





