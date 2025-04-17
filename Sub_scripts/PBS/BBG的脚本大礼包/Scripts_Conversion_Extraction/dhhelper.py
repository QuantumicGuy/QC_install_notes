#!/usr/bin/env python3

# dh_helper
# Author: Shirong Wang 
# Date:   2022/04/24

# # Features
# ## Generate Gaussian iops for doubly hybrid functionals
# * full functional (include SCF and PT2)
# ```
# > python3 dhhelper -t dh -f revDSDPBEP86D3
# p DSDPBEP86
# iop(3/76=1000006900, 3/77=0310003100, 3/78=0429604296)
# iop(3/125=0079905785)
# em=gd3bj iop(3/174=0437700,3/175=-1,3/176=0,3/177=-1,3/178=5500000)
# ```
# * SCF only (useful for stable=opt)
# ```
# > python3 dhhelper -t scf -f revDSDPBEP86D3
# p PBEP86
# iop(3/76=1000006900, 3/77=0310003100, 3/78=0429604296)
# em=gd3bj iop(3/174=0437700,3/175=-1,3/176=0,3/177=-1,3/178=5500000)
# ```
# * functionals supported

# | bDH | bDH-D3 |
# | :---: | :---: |
# | B2PLYP | B2PLYPD3 |
# | mPW2PLYP | |
# | B2GPPLYP | |
# | PBE0DH | |
# | PBE02 | |
# | PBEQIDH | |
# | LS1DHPBE | |
# | DSDPBEP86 | DSDPBEP86D3 |
# | | revDSDPBEP86D3 |
# | | DSDPBEPBED3 |
# | | DSDBLYPD3 |
# | | DSDPBEB95D3 |

# Note: all hyphens are removed due to compatibility with [ajz34/dh](https://github.com/ajz34/dh). DSDPBEP86 here is equivalent to the 2013 one (renamed by Martin) but not the original one (DSDPBEP86 in ORCA).



# Doubly hybrid functionals xc code in detail
XC_DH_MAP = {   # [xc_s, xc_n, cc, c_os, c_ss]
    "mp2": ("HF", None, 1, 1, 1),
    "hfb3lyp": ("HF", "B3LYP", 0, 0, 0),
    "hfpbe0": ("HF", "PBE0", 0, 0, 0),
    # xDH
    "xyg3": ("B3LYPg", "0.8033*HF - 0.0140*LDA + 0.2107*B88, 0.6789*LYP", 0.3211, 1, 1),
    "xygjos": ("B3LYPg", "0.7731*HF + 0.2269*LDA, 0.2309*VWN3 + 0.2754*LYP", 0.4364, 1, 0),
    "xdhpbe0": ("PBE0", "0.8335*HF + 0.1665*PBE, 0.5292*PBE", 0.5428, 1, 0),
    "revxyg3": ("B3LYPg", "0.9196*HF - 0.0222*LDA + 0.1026*B88, 0.6059*LYP", 0.3941, 1, 1),
    "xyg5": ("B3LYPg", "0.9150*HF + 0.0612*LDA + 0.0238*B88, 0.4957*LYP", 1, 0.4548, 0.2764),
    "xyg6": ("B3LYPg", "0.9105*HF + 0.1576*LDA - 0.0681*B88, 0.1800*VWN3 + 0.2244*LYP", 1, 0.4695, 0.2426),
    "xyg7": ("B3LYPg", "0.8971*HF + 0.2055*LDA - 0.1408*B88, 0.4056*VWN3 + 0.1159*LYP", 1, 0.4052, 0.2589),
    "revxygjos": ("B3LYPg", "0.8877*HF + 0.1123*LDA, -0.0697*VWN3 + 0.6167*LYP", 0.5485, 1, 0),
    "xygjos5": ("B3LYPg", "0.8928*HF + 0.3393*LDA - 0.2321*B88, 0.3268*VWN3 - 0.0635*LYP", 0.5574, 1, 0),
    # bDH
    "b2plyp": ("0.53*HF + 0.47*B88, 0.73*LYP", None, 0.27, 1, 1),
    "mpw2plyp": ("0.55*HF + 0.45*mPW91, 0.75*LYP", None, 0.25, 1, 1),
    "pbe0dh": ("0.5*HF + 0.5*PBE, 0.875*PBE", None, 0.125, 1, 1),
    "pbeqidh": ("0.693361*HF + 0.306639*PBE, 0.666667*PBE", None, 0.333333, 1, 1),
    "pbe02": ("0.793701*HF + 0.206299*PBE, 0.5*PBE", None, 0.5, 1, 1),
    "b2gpplyp": ("0.65*HF + 0.35*B88, 0.64*LYP", None, 0.36, 1, 1),
    "ls1dhpbe": ("0.75*HF + 0.25*PBE, 0.578125*PBE", None, 0.421875, 1, 1),
    "dsdpbep86": ("0.72*HF + 0.28*PBE, 0.44*P86", None, 1, 0.51, 0.36),
    "dsdpbep86d3": ("0.69*HF + 0.31*PBE, 0.44*P86", None, 1, 0.52, 0.22),
    "revdsdpbep86d3": ("0.69*HF + 0.31*PBE, 0.4296*P86", None, 1, 0.5785, 0.0799),
    "dsdpbepbed3": ("0.68*HF + 0.32*PBE, 0.49*PBE", None, 1, 0.55, 0.13),
    "dsdblypd3": ("0.71*HF + 0.29*B88, 0.54*LYP", None, 1, 0.47, 0.40),
    "dsdpbeb95d3": ("0.66*HF + 0.34*PBE, 0.55*B95", None, 1, 0.46, 0.09),
    "b2plypd3": ("0.53*HF + 0.47*B88, 0.73*LYP", None, 0.27, 1, 1),
    # bDH RSH
    #"wb2gpplyp":("0.65*SR_HF(0.27) + 1.0*LR_HF(0.27) + 0.35*B88, 0.64*LYP", None, 0.36, 1, 1),
    }
# Additional parameters for doubly hybrids (mostly dftd3)
XC_DH_ADD_MAP = {           # [s6 a1 s8 a2 sr6], version
    "dsdpbep86d3": {"D3": ([0.48, 0, 0, 5.6, 0], 4)},
    "revdsdpbep86d3": {"D3": ([0.4377, 0, 0, 5.5, 0], 4)},
    "dsdpbepbed3": {"D3": ([0.78, 0, 0, 6.1, 0], 4)},
    "dsdblypd3": {"D3": ([0.57, 0, 0, 5.4, 0], 4)},
    "dsdpbeb95d3": {"D3": ([0.61, 0, 0, 6.2, 0], 4)},
    "b2plypd3": {"D3": ([0.64, 0.9147, 0.3065, 5.0570, 0], 4)},
}


def parse_xc_s(xc):
    xc_s = XC_DH_MAP[xc][0]
    if ',' not in xc_s:
        raise NotImplementedError(''' ''') 

    exch, corr = xc_s.split(',')
    if '+' in corr:
        raise NotImplementedError('''Correlation functional contains more than 1 component, 
                                   which is not supported yet''')
    corr_scal, corr_fnal = corr.split('*')
    corr_scal = float(corr_scal.strip())
    corr_fnal = corr_fnal.strip()
    exchs = exch.split('+')
    if len(exchs)>2:
        raise NotImplementedError('''Exchange functional contains more than 1 component 
                                   other than HF, which is not supported yet''')
    for item in exchs:
        if 'HF' not in item:
            exch_scal, exch_fnal = item.split('*')
    exch_scal = float(exch_scal.strip())
    hf_exch = 1 - exch_scal
    exch_fnal = exch_fnal.strip()
    return exch_fnal, corr_fnal, hf_exch, corr_scal

p2g = {
    'B88':'B',
    'mPW91':'mPW',
}

def tostr(floatnum, len=5):
    scal = 10**(len-1)
    gauint = int(round(floatnum*scal,0))
    gaustr = '%09d'%gauint
    return gaustr[-len:]

def dump_fnal(params):
    exch_fnal, corr_fnal, hf_exch, corr_scal = params
    if exch_fnal in p2g:
        exch_fnal = p2g[exch_fnal]
    if corr_fnal in p2g:
        corr_fnal = p2g[corr_fnal]
    fnal_g = exch_fnal + corr_fnal
    exch_scal = 1 - hf_exch
    scal = 'iop(3/76=10000%s, 3/77=%s%s, 3/78=%s%s) '% (tostr(hf_exch),
           tostr(exch_scal), tostr(exch_scal), tostr(corr_scal), tostr(corr_scal))
    return fnal_g, scal

def parse_xc_d3(xc):
    params = XC_DH_ADD_MAP[xc]["D3"]
    if params[1] == 3:
        raise NotImplementedError('''Zero-damping not implemented''')
    return params

def dump_d3(params):
    params_dump = []
    for item in params[0]:
        if item == 0:
            params_dump.append('-1')
        else:
            params_dump.append(tostr(item, 7))
    s6, a1, s8, a2, sr6 = params_dump
    dump = 'em=gd3bj iop(3/174=%s,3/175=%s,3/176=0,3/177=%s,3/178=%s)' % (s6, s8, a1, a2)
    return dump

def gau_scf(xc):
    params = parse_xc_s(xc.lower())
    templ, scal = dump_fnal(params)
    print('Note: SCF part of DH functional')
    print('#p ' + templ)
    print('# ' + scal)
    if 'd3' in xc.lower():
        d3_params = parse_xc_d3(xc.lower())
        print('# ' + dump_d3(d3_params))

def parse_xc_pt(xc):
    c_pt, os, ss = XC_DH_MAP[xc][2:]
    return c_pt, os, ss

def dump_pt(params):
    c_pt, os, ss = params
    os *= c_pt
    ss *= c_pt
    os = tostr(os)
    ss = tostr(ss)
    dump = 'iop(3/125=%s%s)' %(ss,os)
    return dump

DH_Templ = {
    'BLYP':'B2PLYP',
    'PBEP86':'DSDPBEP86',
    'PBEPBE':'PBEQIDH'
        }

CODEc = {
    'LYP':2,
    'P86':4,
    'PBE':9,
    'B95':11,
        }
CODEx = {
    'B':400,
    'PW91':600,
    'mPW':900,
    'PBE':1000,
    }

def xccode(params):
    x,c = params
    if x in p2g: x = p2g[x]
    if c in p2g: c = p2g[c]
    xcode = CODEx[x]
    ccode = CODEc[c]
    code = xcode + ccode
    return code

SUPPORTED = ['b2plyp', 'b2plypd3', 'mpw2plyp',
            'dsdpbep86',
            'pbe0dh', 'pbeqidh']

def gau_dh(xc):
    if xc.lower() in SUPPORTED:
        print('This functional has already been supported by Gaussian.')
        return
    params = parse_xc_s(xc.lower())
    templ, scal = dump_fnal(params)
    params_pt = parse_xc_pt(xc.lower())
    pt_scal = dump_pt(params_pt)
    if templ in DH_Templ:
        templ = DH_Templ[templ]
    else:
        templ = 'B2PLYP'
        templ += ' iop(3/74=%d)'%xccode(params[:2])
    print('Note: full DH functional')
    print('#p ' + templ)
    print('# ' + scal)
    print('# ' + pt_scal)
    if 'd3' in xc.lower():
        d3_params = parse_xc_d3(xc.lower())
        print('# ' + dump_d3(d3_params))


def argument_parse():
    global parser, args
    parser=argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
                               description='Generate Gaussian iops for doubly hybrid functionals')
    parser.add_argument("-t","--type",dest='type',metavar='type',type=str,
                        required=True, choices=['dh','scf'],
                        help='scf: for SCF only (useful for stable=opt)\n'
                             ' dh: for full functional (include SCF and PT2)')
    parser.add_argument("-f","--fun",dest='xc',metavar='functional',type=str,
                        required=True,
                        help = 'supported: B2PLYP    MPW2PLYP    PBE0DH      PBEQIDH\n'
                               '           PBE02     B2GPPLYP    LS1DHPBE    DSDPBEP86\n'
                               '           DSDPBEP86D3    revDSDPBEP86D3     DSDPBEPBED3\n'
                               '           DSDBLYPD3      DSDPBEB95D3        B2PLYPD3\n'
			       ' Attention: No hyphens in functional name\n')
    parser.add_argument("-V","--version",action="version",version='v1.0')
    args=parser.parse_args()
    
    
import argparse
argument_parse()
if args.type == 'scf':
    gau_scf(args.xc)
elif args.type == 'dh':
    gau_dh(args.xc)

