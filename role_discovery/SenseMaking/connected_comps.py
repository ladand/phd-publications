#!/usr/bin/env python

import sys

def _make(u,p,r):
    p[u] = u
    r[u] = 0

def _link(u,v,p,r):
    if r[u] > r[v]:
        p[v] = u
    else:
        p[u] = v
        if r[u] == r[v]: r[v] += 1

def _union(u,v,p,r):
    _link(_find(u,p),_find(v,p),p,r)

def _find(u,p):
    if u != p[u]:
        p[u] = _find(p[u],p)
    return p[u]
          

def comps(g):
    p = {}
    r = {}
    for u in g:
        if not u in p: _make(u,p,r)
        for v in g[u]:
            if not v in p: _make(v,p,r)
            if _find(u,p) != _find(v,p):
                _union(u,v,p,r)
    for u in p:
        _find(u,p)

    cs = {}
    for (u,v) in p.items():
        if not v in cs: cs[v] = set()
        cs[v].add(u)
    
    return cs.values()

def write_component(g, c, f):
    for u in g:
        if not u in c: continue
        for v in g[u]:
            print >>f, ','.join((u,v,g[u][v]))


if __name__ == '__main__':
    infile = sys.argv[1]
    outfile_base = sys.argv[2]
    
    g = {}
    for line in open(infile):
        u,v,w = line[:-1].split(',')
        if not u in g: g[u] = {}
        g[u][v] = w

    cs = comps(g)

    s = {}
    for c in cs:
        for u in c:
            s[u] = len(c)

    for i in xrange(len(s)):
        print s[`i+1`]

    foo
    
    l = reversed(sorted([(len(c),c) for c in cs]))

    idx = 1
    format_len = len(`len(cs)`)
    for (x,c) in l:
        f = '%%s-%%0%dd.csv'%format_len%(outfile_base,idx)
        write_component(g,c,open(f,'w'))
        idx = idx + 1
    
    

    
