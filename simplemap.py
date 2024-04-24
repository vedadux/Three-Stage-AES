# coding: utf-8

import re

costs = {
     "$_NOT_"  : 0.532,
     "$_NAND_" : 0.798, 
     "$_AND_"  : 1.064, 
     "$_XOR_"  : 1.596, 
     "$_XNOR_" : 1.596, 
     "$_DFF_P_": 4.522, 
}

def get_area(text):
     timestamp = re.compile("\[\d+\.\d+\]")
     for t in timestamp.findall(text):
          text = text.replace(t, "")
     data = text.split()
     data = {data[2*i]:int(data[2*i+1]) for i in range(len(data)//2)}
     area = sum(map(lambda x: costs[x[0]] * x[1], data.items()))
     return area