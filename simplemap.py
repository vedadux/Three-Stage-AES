# 
# Copyright (C) 2024 Vedad Hadžić
# 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 

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