__all__ = ['addTimeScale', 'stripModule', 'clear_hints','ctrl_reg',]

from CCURegisters import ctrl_reg
import re

def addTimeScale(fname):
    txt = []
    txt.append(
'''
`resetall
`timescale 1ns/1ps
`default_nettype none

''')
    with open(fname,'r') as f:
        txt.extend(f.readlines())
    
    txt.append('`resetall\n')

    with open(fname,'w') as f:
        f.writelines(txt)

def stripModule(fname, module_name):
    with open(fname,'r') as f:
        txt = ''.join(f.readlines())
    
    found = False
    start_ref = None
    
    while not found :
        start_ref = txt.find('module',start_ref)
        end_ref   = txt.find('endmodule', start_ref)
        
        if not (start_ref and end_ref) :
            return -1
        
        if start_ref > end_ref:
            return -2
        
        subtxt = txt[start_ref: txt.find('\n',end_ref)+1]
        # print(subtxt)
        
        if subtxt.find(module_name, 0, subtxt.find(';')) :
            with open(fname,'w') as f:
                f.writelines([subtxt,'\n'])
            
            return 0
    
def clear_hints(fname) :
    with open(fname,'r') as fr:
        txt = fr.readlines()
        
    txt = [
        re.sub(
            r'\(\*.*\*\)',
            '',
            line,
        ) for line in txt
    ]
    txt = [line for line in txt if not line.isspace()]
        
    with open(fname,'w') as fw:
        fw.writelines(txt)    
    