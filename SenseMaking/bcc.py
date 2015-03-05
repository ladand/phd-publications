#!/usr/bin/env python

import sys
from heapq import heappush, heappop
from random import random
from pprint import pprint
from connected_comps import comps

def bcc(g):
    bicomps = []
    cmps = comps(g)

    reclimit = sys.getrecursionlimit()
    sys.setrecursionlimit(2*(1+max([len(x) for x in cmps])))

    sized = reversed(sorted([(len(x), x) for x in cmps]))
    
    for s, cmp in sized:
        u = list(cmp)[0]
        v = list(g[u])[0]
        bicomps.extend(_bcc(g,u,v,0,[],{},{}))

    sys.setrecursionlimit(reclimit)

    bcs = []
    for bc in bicomps:
        b = set()
        for u,v in bc:
            b.add((u,v))
            if v in g and u in g[v]:
                b.add((v,u))
        bcs.append(list(b))
    return bcs


def _bcc(g, v, u, tm, s, low, vn):
    r = []
    rr = []
    low[v] = vn[v] = tm = tm+1
    for w in g[v]:
        if vn.get(w,0) < vn[v]: s.append((v,w))
        if not w in vn:
            r = r + _bcc(g,w,v,tm,s,low,vn)
            low[v] = min(low[v],low[w])
            if low[w] >= vn[v]:
                bc = []
                (uu,vv) = None,None
                while (uu,vv) != (v,w):
                    uu,vv = s.pop()
                    bc.append((uu,vv))
                r.append(bc)
        else:
            low[v] = min(low[v], vn[w])
    return rr + r

def bridges(g):
    bcs = bcc(g)
    r = []
    for bc in bcs:
        if len(bc) == 1:
            r.append(bc[0])
        elif len(bc) == 2:
            u,v = bc[0]
            if bc[1] == (v,u):
                r.append(bc[0])
                r.append(bc[1])
    return set(r)



if __name__ == '__main__':

    g = {}

    for line in open(sys.argv[1]):
        u,v,w = line[:-1].split(',')

        if not u in g: g[u] = {}
        g[u][v] = w
        if not v in g: g[v] = {}
        g[v][u] = w

    bcs = [set(x) for x in bcc(g)]

    i = 0
    for bc in bcs:
        if len(bc) == 2:
            label = 'Bridge'
        else:
            i += 1
            label = 'BCC %d'%i
        for u,v in bc:
            if u > v:
                pass
                print ','.join((u,v,g[u][v],label))
            del g[u][v]
    for u in g:
        for v in g[u]:
            if u > v:
                print ','.join((u,v,g[u][v],'Lost'))
