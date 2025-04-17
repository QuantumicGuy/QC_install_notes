#!/usr/bin/env python3
import subprocess as sp
import os
import sys
import glob
import pandas as pd
import psutil
import re
import shutil
from itertools import islice
import argparse

'''version 1.0
use Multiwfn to generate cubes in batch
developed by zhongcheng@whu.edu.cn. QQ:32598827
please contact me if you have any suggestions or find any bugs
'''
class extractInfo:
    '''detect homo and lumo in wfn file (fchk,log,molden)
    and convert orbital index to orbital label or
    convert orbital label to orbital index'''

    def __init__(self, wfnfile):
        self.wfnfile = os.path.abspath(wfnfile)
        try:
            self.fileobj = open(wfnfile, 'r')
            filename = os.path.basename(wfnfile)
            self.basename, self.ext = os.path.splitext(filename)
        except TypeError:
            sys.exit(
                'Error! The input {:s} is not a file' .format(str(wfnfile)))

    def read_orb(self):
        self.openshell = 0
        readorb = {'.fchk': self._orb_fchk,
                   '.log': self._orb_log,
                   '.molden': self._orb_molden}
        self.homo_idx = readorb[self.ext]()
        self.total_orb = self.homo_idx[1] - self.homo_idx[0]

    def read_exc(self):
        '''es_states is a list of dict'''
        readexc = {'.log': self._exc_log,
                   '.out': self._exc_out,
                   }
        es_states = readexc[self.ext]()
        es_no = []
        es_lbl = []
        no_s = 0
        no_t = 0
        for e in es_states:
            if e['Mult'].startswith('S'):
                no_s = no_s + 1
                elbl = 'S'+str(no_s)
            elif e['Mult'].startswith('T'):
                no_t = no_t + 1
                elbl = 'T'+str(no_t)
            else:
                elbl = 'E'+str(e['sn'])
            es_no.append(e['sn'])
            es_lbl.append(elbl)
        self.es_no = es_no
        self.es_lbl = es_lbl

    def _exc_log(self):
        sep_line = [0]
        for line_no, line in enumerate(self.fileobj):
            if 'SCF Done' in line and line_no > 0:
                sep_line.append(line_no)
        sep_line.append(line_no)

        if len(sep_line) > 3:
            print('Optimize job detected, replace current gout file with its last part.')
            self.fileobj = open(self.wfnfile, 'r')
            first_part = list(islice(self.fileobj, sep_line[1]))
            self.fileobj = open(self.wfnfile, 'r')
            last_part = list(islice(self.fileobj, sep_line[-2], sep_line[-1]))
            self.fileobj.close()
            shutil.move(self.wfnfile, self.wfnfile+'.bak')
            newlog = open(self.wfnfile, 'w')
            for line in first_part+last_part:
                if 'GradGrad' not in line:
                    newlog.write(line)
            newlog.close()
        self.fileobj = open(self.wfnfile, 'r')
        excited_states = []
        for l in self.fileobj:
            if 'Excited State' in l:
                es = {'sn': int(l.split()[2].strip(':')),
                      'Mult': l.split()[3].split('-')[0],
                      }
                excited_states.append(es)
        return excited_states

    def _exc_out(self):
        pass

    def _orb_fchk(self):
        for l in self.fileobj:
            if 'Beta Orbital Energies' in l:
                self.openshell = 1
            if 'Number of alpha electrons' in l:
                alpha_e = l.split()[5]
            if 'Number of beta electrons' in l:
                beta_e = l.split()[5]
            if 'Number of independent functions' in l:
                total_orb = l.split()[5]
            if 'MO coefficients' in l:
                break
        beta_homo = int(total_orb)+int(beta_e)
        return [int(alpha_e), beta_homo]

    def _orb_log(self):
        for l in self.fileobj:
            if 'Orbital symmetries:' in l:
                line = self.fileobj.next()
                if 'Alpha Orbitals' in line:
                    self.openshell = 1
                break
            if 'alpha electrons' in l:
                alpha_e = l.split()[0]
                beta_e = l.split()[3]
            if 'primitive gaussians' in l:
                total_orb = l.split()[0]
        beta_homo = str(int(total_orb)+int(beta_e))
        return [int(alpha_e), beta_homo]

    def _orb_molden(self):
        pass


class parseExc:
    def __init__(self, info_obj):
        self.es_no = info_obj.es_no
        self.es_lbl = info_obj.es_lbl

    def parse_exc(self, exc_states):
        def expand(e):
            es_idx = []
            if '-' in e:
                e1 = int(e.split('-')[0])
                e2 = int(e.split('-')[1])
                if e1 > e2:
                    e1, e2 = e2, e1
                es_idx = es_idx + list(range(e1, e2+1))
            else:
                try:
                    es_idx = es_idx + [int(e)]
                except ValueError:
                    pass
            return es_idx
        es = exc_states.lower().strip('st')
        no2lbl = dict(zip(self.es_no, self.es_lbl))
        lbl2no = dict(zip(self.es_lbl, self.es_no))
        es_lbl = []
        es_no = []
        for e in exc_states.split(','):
            if e.lower().startswith('s'):
                es_idx = expand(e[1:])
                lbl = ['S'+str(i) for i in es_idx if 'S'+str(i) in self.es_lbl]
                no = [lbl2no[i] for i in lbl]
                es_lbl = es_lbl + lbl
                es_no = es_no + no
            elif e.lower().startswith('t'):
                es_idx = expand(e[1:])
                lbl = ['T'+str(i) for i in es_idx if 'T'+str(i) in self.es_lbl]
                no = [lbl2no[i] for i in lbl]
                es_lbl = es_lbl + lbl
                es_no = es_no + no
            elif e[0].isdigit():
                es_idx = expand(e)
                no = [i for i in es_idx if i in self.es_no]
                lbl = [no2lbl[i] for i in no]
                es_no = es_no + no
                es_lbl = es_lbl + lbl
        self.sn = es_no
        self.lbl = es_lbl
        print('cubes for excited states: {:s} will be generated'.format(','.join(self.lbl)))


class parseOrb:
    def __init__(self, info_obj):
        self.openshell = info_obj.openshell
        self.homo_idx = info_obj.homo_idx
        self.total_orb = info_obj.total_orb

    def parse_orb(self, orb_str):
        '''convert user input orbital string to a list of orbital label and index'''
        orb_label = []
        for o in orb_str.split(','):
            if '-' in o:
                o1 = o.split('-')[0]
                o2 = o.split('-')[1]
                if 'a' in o1 and 'b' in o2:
                    print(
                        'Error!!! Orbtital format {:s}-{:s} is not supported'.format(o1, o2))
                    sys.exit()
                i1 = self.lbl2idx([o1])[0]
                i2 = self.lbl2idx([o2])[0]
                if i1 > i2:
                    i1, i2 = i2, i1
                orb_label = orb_label + self.idx2lbl(list(range(i1, i2+1)))
                try:
                    i1 = self.lbl2idx([o1])[1]
                    i2 = self.lbl2idx([o2])[1]
                    if i1 > i2:
                        i1, i2 = i2, i1
                    orb_label = orb_label + self.idx2lbl(list(range(i1, i2+1)))
                except IndexError:
                    pass
            else:
                orb = self.idx2lbl(self.lbl2idx([o]))
                orb_label = orb_label + orb
        self.orb_label = orb_label
        self.orb_index = self.lbl2idx(orb_label)
        self.filter_orb()

    def idx2lbl(self, idx_list):
        # convert orbital index list to orbital label list
        orb_label = []
        for i in idx_list:
            if i < self.total_orb:
                i = i - self.homo_idx[0]
                if i <= 0:
                    ol = 'H'+str(i*-1)+'a'
                else:
                    ol = 'L'+str(i-1)+'a'
            else:
                i = i - self.homo_idx[1]
                if i <= 0:
                    ol = 'H'+str(i*-1)+'b'
                else:
                    ol = 'L'+str(i-1)+'b'
            orb_label.append(ol)
        return orb_label

    def lbl2idx(self, label_list):
        '''convert orbital label to orbital index'''
        idx_list = []
        for ol in label_list:
            ol = ol.lower().replace('omo', '').replace('umo', '')
            try:
                i = int(ol.strip('hlab'))
            except ValueError:
                i = 0
            if ol.startswith('h'):
                idx_a = self.homo_idx[0] - abs(i)
                idx_b = self.homo_idx[1] - abs(i)
            elif ol.startswith('l'):
                idx_a = self.homo_idx[0] + 1 + abs(i)
                idx_b = self.homo_idx[1] + 1 + abs(i)
            else:
                try:
                    index = [int(ol)]
                except ValueError:
                    print('Error! Wrong orbital label format: {:s}'.format(ol))
            if not ol.isdigit():
                if ol.endswith('b'):
                    index = [idx_b]
                elif ol.endswith('a'):
                    index = [idx_a]
                else:
                    index = [idx_a, idx_b]
            idx_list = idx_list + index
        return idx_list

    def filter_orb(self):
        '''filt beta orbital label and index if self.open_shell=0'''
        if self.openshell == 0:
            self.orb_label = [ol.replace('a', '')
                              for ol in self.orb_label if 'b' not in ol]
            self.orb_index = [
                idx for idx in self.orb_index if idx < self.total_orb]
        self.orb_label = [re.sub('([HL])0', r'\1', ol)
                          for ol in self.orb_label]


class prepareM:
    def __init__(self, np=None, mem=None):
        if np:
            self.np = int(np)
        else:
            self.np = None
        if mem:
            if mem.lower().endswith('gb'):
                self.mem = float(mem.lower().strip('gb'))*1024*1024*1024
            elif mem.lower().endswith('mb'):
                self.mem = float(mem.lower().strip('mb'))*1024*1024
            elif mem.lower().endswith('kb'):
                self.mem = float(mem.lower().strip('kb'))*1024
            else:
                self.mem = float(mem)
        else:
            self.mem = None
        self.check_env()
        self.check_Mwfn_path()
        self.check_gau_path()
        self.modify_Mwfn_ini()

    def check_env(self):
        '''detect avaiable memory, physical cpu cores and Multiwfn path'''
        self.settings = {}
        self.mem_avail = float(psutil.virtual_memory()._asdict()['available'])
        print('{:.1f} GB memory avaialbe'.format(
            float(self.mem_avail)/1024/1024/1024))
        self.np_avail = int(psutil.cpu_count(logical=False))
        print('{:d} physical cores detected'.format(self.np_avail))
        if not self.np:
            self.np = self.np_avail
        elif self.np > self.np_avail:
            self.np = self.np_avail
        if not self.mem:
            self.mem = self.mem_avail
        elif self.mem > self.mem_avail:
            self.mem = self.mem_avail
        self.stacksize = int(self.mem*0.8/self.np)
        if self.stacksize > 2147483647:
            self.stacksize = 2147483647
        print('Use {:d} cores and ompstacksize is set to {:.1f} GB'.format(
            self.np, self.stacksize/1024/1024/1024))
        os.environ["KMP_STACKSIZE"] = str(self.stacksize)
        self.settings['ompstacksize'] = str(self.stacksize)
        self.settings['nthreads'] = str(self.np)

    def check_Mwfn_path(self):
        # check Multiwfn path
        path = os.getenv('PATH')
        Mdir = None
        for p in path.split(os.path.pathsep):
            p1 = os.path.join(p, 'Multiwfn.exe')
            p2 = os.path.join(p, 'Multiwfn')
            if os.path.exists(p1) and os.access(p1, os.X_OK):
                Mdir = p
                break
            elif os.path.exists(p2) and os.access(p2, os.X_OK):
                Mdir = p
                break
        if not Mdir:
            print('Error!!! Multiwfn not found in PATH, exit now!')
            os._exit(0)
        else:
            print('Multiwfn found in {:s}'.format(Mdir))
        self.Mdir = Mdir

    def check_gau_path(self):
        # check gaussian path
        path = os.getenv('PATH')
        Gdir = None
        for p in path.split(os.path.pathsep):
            p1 = os.path.join(p, 'formchk.exe')
            p2 = os.path.join(p, 'formchk')
            if os.path.exists(p1) and os.access(p1, os.X_OK):
                Gdir = p
                formchk = p1
                cubegen = os.path.join(p, 'cubegen.exe')
                if 'g09' in p:
                    gau = os.path.join(p, 'g09.exe')
                if 'g16' in p:
                    gau = os.path.join(p, 'g16.exe')
                break
            elif os.path.exists(p2) and os.access(p2, os.X_OK):
                Gdir = p
                formchk = p2
                cubegen = os.path.join(p, 'cubegen')
                if 'g09' in p:
                    gau = os.path.join(p, 'g09')
                if 'g16' in p:
                    gau = os.path.join(p, 'g16')
                break
        if Gdir:
            print('Gaussian found in {:s}'.format(Gdir))
            self.Gdir = Gdir
            if os.path.exists(cubegen) and os.access(cubegen, os.X_OK):
                self.settings['cubegenpath'] = cubegen
            else:
                print('Warning! cubegenpath not set becasue {:s} not exist or excutable'.format(
                    cubegen))
            if os.path.exists(formchk) and os.access(formchk, os.X_OK):
                self.settings['formchkpath'] = formchk
            else:
                print('Warning! formchkpath not set becasue {:s} not exist or excutable'.format(
                    formchk))
            if os.path.exists(gau) and os.access(gau, os.X_OK):
                self.settings['gaupath'] = gau
            else:
                print(
                    'Warning! gaupath not set becasue {:s} not exist or excutable'.format(gau))
        else:
            print('Warning!!! Gaussian not d in PATH')

    def modify_Mwfn_ini(self, **kwargs):
        '''modify settings.ini by inp_dict'''
        self.settings.update(kwargs)
        inifile = os.path.join(self.Mdir, 'settings.ini')
        if os.path.exists(inifile):
            shutil.copyfile(inifile, 'settings.ini')
            f = open('settings.ini', 'r+')
            f_content = f.read()
            for k, v in self.settings.items():
                v = v.replace('\\', '\\\\')
                if 'path' in k:
                    #f_content = re.sub(k+'.*//', r'{}= "{}"'.format(k,v), f_content)
                    f_content = re.sub(
                        k+'.*/?/?', '{}= "{}" //'.format(k, v), f_content)
                else:
                    f_content = re.sub(
                        k+'.*/?/?', r'{}= {} //'.format(k, v), f_content)
            f.seek(0)
            f.truncate()
            f.write(f_content)
            f.close()
            cwd = os.getcwd()
            os.environ["Multiwfnpath"] = cwd
            print('settings.ini is modified and copy to {:s}'.format(cwd))
            print('Set Multiwfnpath to {:s}'.format(cwd))
        else:
            print(
                'Warning! settings.ini is not found in {:s}'.format(self.Mdir))


class prepareFile:
    def __init__(self, basename, pm):
        '''check and prepare all the necessary file
        and pass this file object to Multiwfn class
        basename is the basename of a file without extenstion
        pm is prepareM object that contains path information
        of formchk'''
        self.pm = pm
        self.basename = basename
        if os.path.exists(basename+'.log'):
            self.logfile = basename+'.log'
        elif os.path.exists(basename+'.out'):
            self.logfile = basename+'.out'
        else:
            self.logfile = ""

        if os.path.exists(basename+'.fchk'):
            self.fchkfile = basename+'.fchk'
        elif os.path.exists(basename+'.chk'):
            self._formchk(basename+'.chk')
        else:
            sys.exit('Error! {:s}.fchk or {:s}.chk not available'
                     .format(basename, basename))

    def _formchk(self, chkfile):
        if "formchkpath" in self.pm.settings:
            fchkpath = self.pm.settings["formchkpath"]
            print("formchk {:s} using {:s}".format(chkfile, fchkpath))
            p = sp.Popen([fchkpath, self.basename+'.chk'])
            p.communicate()
            self.fchkfile = self.basename+'.fchk'
        else:
            sys.exit("Error ! formchk command not found. Please formchk the chk file youself")


class Multiwfn:
    def __init__(self, pf_obj):
        '''basename is the name for log and chk, profile contol which job to run
        and which infor to extract'''
        self.inp = pf_obj
        self.basename=pf_obj.basename
        self.Mout = ''
        self.p2c = {
            'den': ['5;1;GS;2', 'density.cub'],
            'orb': ['5;4;IDX;GS;2', 'MOvalue.cub'],
            'esd': ['5;5;GS;2', 'spindensity.cub'],
            'elf': ['5;9;GS;2', 'ELF.cub'],
            'lol': ['5;10;GS;2', 'LOL.cub'],
            'esp': ['5;12;GS;2', 'totesp.cub'],
            'rdg': ['5;13;GS;2', 'RDG.cub'],
            'prdg': ['5;14;GS;2', 'RDGprodens.cub'],
            'lmd': ['5;15;GS;2', 'signlambda2rho.cub'],
            'plmd': ['5;16;GS;2', 'signlambda2rhoprodens.cub'],
            'Ehole': ['18;1;LOG;IDX;1;GS;10;1', 'hole.cub'],
            'Eele': ['18;1;LOG;IDX;1;GS;11;1', 'electron.cub'],
            'Esr': ['18;1;LOG;IDX;1;GS;12;2', 'Sr.cub'],
            'Esm': ['18;1;LOG;IDX;1;GS;12;1', 'Sm.cub'],
            'Etd': ['18;1;LOG;IDX;1;GS;13', 'transdens.cub'],
            'Etdmx': ['18;1;LOG;IDX;1;GS;14;1', 'transdipens.cub'],
            'Etdmy': ['18;1;LOG;IDX;1;GS;14;2', 'transdipens.cub'],
            'Etdmz': ['18;1;LOG;IDX;1;GS;14;3', 'transdipens.cub'],
            'Ecdd': ['18;1;LOG;IDX;1;GS;15', 'CDD.cub'],
            'Etmdmx': ['18;1;LOG;IDX;-1;1;GS;17;1', 'magtrdipens.cub'],
            'Etmdmy': ['18;1;LOG;IDX;-1;1;GS;17;2', 'magtrdipens.cub'],
            'Etmdmz': ['18;1;LOG;IDX;-1;1;GS;17;3', 'magtrdipens.cub'],
            'Ento': ['18;6;LOG;IDX;2;OUTNAME', ''],
        }

    def profile_parser(self, excite='',orb='',common=''):
        '''convert profile to list of dict, each list represent a type of cube
        [{'type':'exc','index':1,'name':}, {'type':'orb','index':55,'name':'h'}]'''
        explist = []
        if orb:
            info = extractInfo(self.inp.fchkfile)
            info.read_orb()
            o = parseOrb(info)
            o.parse_orb(orb)
            for i, oi in enumerate(o.orb_index):
                explist.append({'type': 'orb', 'index': oi,
                                'name': 'o'+o.orb_label[i]})
        if excite:
            exc_states = excite.split(':')[0]
            exc_prof = excite.split(':')[1]
            info = extractInfo(self.inp.logfile)
            info.read_exc()
            e = parseExc(info)
            e.parse_exc(exc_states)
            for st in exc_prof.split(','):
                for i, ei in enumerate(e.sn):
                    explist.append(
                        {'type': 'E'+st, 'index': ei, 'name': e.lbl[i]+'-'+st, 'auxfile': self.inp.logfile})
        if common:
            for p in common.split(','):
                prof = {'type': p, 'name': p}
                explist.append(prof)

        # print(explist)
        self.explist = explist

    def _gen_Minp(self, profile, dens='scf', grid='2'):
        comstr = self.p2c[profile['type']][0]
        self.Mfile = self.p2c[profile['type']][1]
        _, ext = os.path.splitext(self.Mfile)
        if profile['type'] == 'Ento':
            ext = '.fchk'
        self.outfile = self.basename + '_' + profile['name'] + ext
        if dens != 'scf':
            comstr = '200;16;'+dens.upper()+';y;0;' + comstr
            self.outfile = self.basename + '_' + \
                dens.upper() + profile['name'] + ext

        comstr = comstr.replace('GS', grid)
        if 'index' in profile:
            comstr = comstr.replace('IDX', str(profile['index']))
        if 'auxfile' in profile:
            comstr = comstr.replace('LOG', str(profile['auxfile']))
        comstr = comstr.replace('OUTNAME', self.outfile)
        comstr = comstr.replace(';', '\n')
        m = open('Multiwfn_com', 'w')
        m.write(comstr)
        m.close()

    def _run_multiwfn(self):
        Min = open('Multiwfn_com', 'r')
        Mout = open('Multiwfn_out', 'w')
        Merr = open('Multiwfn_err', 'w')
        try:
            p = sp.Popen(['Multiwfn', self.basename+'.fchk'],
					     stdin=Min, stdout=sp.PIPE, universal_newlines=True, stderr=Merr)
        except FileNotFoundError:
            p = sp.Popen(['Multiwfn.exe', self.basename+'.fchk'],
					    stdin=Min, stdout=sp.PIPE, universal_newlines=True, stderr=Merr)
        for l in p.stdout:
            if 'Progress' in l:
                l = l.strip('\n')
                print(l, end='\r')
            else:
                Mout.write(l)
        print('\n')
        Min.close()
        Mout.close()
        Merr.close()

    def gen_cube(self, grid_setting='2', dens=None):
        if not dens:
            dens = 'scf'
        if not grid_setting:
            grid_setting = '2'
        for prof in self.explist:
            self._gen_Minp(prof, grid=grid_setting, dens=dens)
            print('Using Multiwfn to generate {:s} ...'.format(self.outfile))
            self._run_multiwfn()
            if self.Mfile:
                shutil.move(self.Mfile, self.outfile)
            try:
                os.mkdir("MCUBEG")
            except FileExistsError:
                pass
            shutil.move(self.outfile, os.path.join("MCUBEG", self.outfile))
            print('{:s} moved to {:s}'.format(
                self.outfile, os.path.abspath("MCUBEG")))


parser = argparse.ArgumentParser(
    description='Version 1.0: Use Multiwfn and Gaussian output file to generate various cubes in batch', formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('-m', dest='mem', help='Set the memory used by Multiwfn; e.g.: "-m 10GB"\n'
                                           'default: 80%% of the free memory', default=None)
parser.add_argument('-n', dest='np', help='Set the number of processors used by Multiwfn; e.g: "-n 6"\n'
                    'default: all the physical cores available.', default=None)
parser.add_argument('-d', dest='density',
                    help='choose the density to use; e.g.: "-d CI"; default is "scf"', default=None)
parser.add_argument('-o', dest='orbital', help='Generate orbital cubes\n'
                    'e.g. -o "h1-l2,h2a,3b" will generate cubes of \n'
                    'HOMO-1 to LUMO+2, HOMO-2 alpha, and the 3rd beta MO'
                    )
parser.add_argument('-e', dest='excite', help='Generate excited state cubes\n'
                    'the format is EXCITED-STATE:CUBETYPE means generate CUBETYPE for EXCITED-STATE\n'
                    'following are the format of EXCITED-STATE:\n'
                    '\t"1-3,5" means 1,2,3,5 excited states\n'
                    '\t"s1,t1-3" means first singlets state and 1-3 triplets state\n'
                    'following are the available CUBETYPE, seperate multiple type by ,\n'
                    '\t"hole/ele/sr/sm" hole/electron/hole-electron overlap\n'
                    '\t"nto" natural transition orbitals in fchk format\n'
                    '\t"td/tdm[xyz]" transition density/transition dipole moment density in x,y,z\n'
                    '\t"cdd" charge density difference to current folder\n'
                    '\t"tmdm[xyz]" transition magnetic dipole moment density in x,y,z\n'
                    )
parser.add_argument('-c', dest='common', help='Set the common type of cube to generate; seperate multiple type by ","\n'
                    'e.g. -t "den,esp,elf" will generate cubes of \n'
                    'electron density, ESP, and ELF \n'
                    'available types are:\n'
                    '"den/esd/esp" electron density/electron spin density/electrostatic potential \n'
                    '"elf/lol" electron localizaition function/localized orbital locator\n'
                    '"rdg/lmd" reduced density gradient/Sign(lambda2)*rho\n'
                    '"prdg/plmd" RDG/lmd with promolecular approximation\n'
                   )
parser.add_argument('-g', dest='grid', help='Set the cube grid; Use same input as Multiwfn, and seperate lines by ";"\n'
                    'Some frequently used options are:\n'
                    '1/2/3 for Low Medium High quanlity grid, repectively;\n'
                    '4;x,y,z for the number of points or grid spacing in X,Y,Z direction\n'
					'4;0.1 set the grid spaceing to 0.1 Bohr in X,Y,Z direction\n'
                    '8;abc.cube to use same grid settings as abc.cube\n'
                    'default is 2 which is the same as default cube quanlity of cubegen')
parser.add_argument('inputfile', nargs='+',
                    help='The input files are ABC.* The ABC.fchk should be available\n'
                    'Or ABC.chk with formchk in the PATH\n'
                    'ABC.log is requied if excited state is involved.')

args = parser.parse_args()
inputfiles = []
for i in args.inputfile:
    inputfiles = inputfiles + glob.glob(i)
basenames = []
for i in inputfiles:
    filename = os.path.basename(i)
    basename, ext = os.path.splitext(filename)
    basenames.append(basename)
basenames = list(dict.fromkeys(basenames))
pm = prepareM(np=args.np, mem=args.mem)
for inpf in basenames:
    pf = prepareFile(inpf, pm)
    m = Multiwfn(pf)
    m.profile_parser(orb=args.orbital, excite=args.excite, common=args.common)
    m.gen_cube(grid_setting=args.grid, dens=args.density)
