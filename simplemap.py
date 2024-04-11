# coding: utf-8

AND_COST = 1.064
XOR_COST = 1.596
DFF_COST = 4.522

AND_T = "$_AND_"
XOR_T = "$_XOR_"
DFF_T = "$_DFF_P_"

def get_area(text):
     data = text.split()
     data = {data[2*i]:int(data[2*i+1]) for i in range(len(data)//2)}
     area = data[AND_T] * AND_COST + data[XOR_T] * XOR_COST + data[DFF_T] * DFF_COST
     return area