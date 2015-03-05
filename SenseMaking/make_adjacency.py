#!/usr/bin/env python

import sys

g = {}
g_file = open(sys.argv[1])
v_file = open(sys.argv[2])
v_file.readline()

idx = {}
for line in v_file:
    idx[line.split(',')[0]] = `len(idx)+1`

for line in g_file:
    u,v,w = line[:-1].split(',')
    print ','.join((idx[u],idx[v],w))



    
