#!/usr/bin/env python

import sys
from heapq import heappush, heappop
from random import random
from pprint import pprint
from connected_comps import comps
from bcc import bcc

from time import time


def bfs(g,u,art_reach,art_edges):
    d = {u:0}
    open = [-1]*len(g)
    bcc = [-1]*len(g)
    open[0] = u
    oi = 0
    oj = 1
    closed = set([u])
    mxd = 0

    while oi < oj:
        v = open[oi]
        if v in art_reach:
            for w in art_edges[v][bcc[oi]]:
                if w in closed: continue
                closed.add(w)
                d[w] = 1 + d[v]
                mxd = max(d[w],mxd)
                if w in art_reach: bcc[oj] = g[v][w]
                open[oj] = w
                oj += 1
            if bcc[oi] == art_reach[v][0][0]:
                mxd = max(mxd, d[v] + art_reach[v][1][1])
            else:
                mxd = max(mxd, d[v] + art_reach[v][0][1])
        else:
            for w in g[v]:
                if w in closed: continue
                closed.add(w)
                d[w] = 1 + d[v]
                mxd = max(d[w],mxd)
                if w in art_reach: bcc[oj] = g[v][w]
                open[oj] = w
                oj += 1
        oi += 1
    return mxd


def art_bfs(g,u,art_reach):
    d = {u:0}
    open = [-1]*len(g)
    bcc = [-1]*len(g)
    open[0] = u
    oi = 0
    oj = 1
    closed = set([u])
    mxd = 0
    bcc_max = {}

    while oi < oj:
        v = open[oi]
        for w in g[v]:
            if w in closed: continue
            closed.add(w)

            open[oj] = w
            if v == u: bcc[oj] = g[u][w]
            else: bcc[oj] = bcc[oi]

            d[w] = 1 + d[v]
            bcc_max[bcc[oj]] = max(bcc_max.get(bcc[oj],0),d[w])
            mxd = max(d[w],mxd)
            
            oj += 1
        oi += 1

    for dist, idx in reversed(sorted([(bcc_max[x],x) for x in bcc_max])):
        if u not in art_reach: art_reach[u] = [(idx,dist)]
        else:
            art_reach[u].append((idx,dist))
            break
    return mxd

def eccentricity(g):
    n = len(g)
    
    verts = set()

    for u in g:
        verts.add(u)

    ecc = {}
    art_reach = {}

    bccs = bcc(g)

    mems = {}
    for u in g: mems[u] = set()

    for i in xrange(len(bccs)):
        for (u,v) in bccs[i]:
            g[u][v] = i
            mems[u].add(i)
            mems[v].add(i)

    art = [x for x in mems if len(mems[x]) > 1]

    art_edges = {}

    c = 0
    for u in art:
        c += 1
        art_edges[u] = {}
        for v in g[u]:
            bc = g[u][v]
            if not bc in art_edges[u]:
                art_edges[u][bc] = set()
            art_edges[u][bc].add(v)
        ecc[u] = art_bfs(g,u,art_reach)

    for u in verts:
        if u in art_reach: continue
        ecc[u] = bfs(g,u,art_reach,art_edges)
    
    return ecc
    


if __name__ == '__main__':
    
    g_file = open(sys.argv[1])
    v_file = open(sys.argv[2])
    v_file.readline()
    
    order = []
    for line in v_file:
        order.append(line.split(',')[0])
    
    g = {}
    for line in g_file:
        u,v,w = line.split(',')

        w = 1
        if not u in g: g[u] = {}
        g[u][v] = w
        if not v in g: g[v] = {}
        g[v][u] = w

    ecc = eccentricity(g)
    bcs = bcc(g)
    mems = {}

    for i,bc in zip(range(len(bcs)),bcs):
        for u,v in bc:
            if not u in mems: mems[u] = set()
            if not v in mems: mems[v] = set()
            mems[u].add(i)
            mems[v].add(i)
            

    print 'Eccentricity,Number of Biconnected Components'
    for u in order:
        print '%d,%d'%(ecc[u],len(mems[u]))

