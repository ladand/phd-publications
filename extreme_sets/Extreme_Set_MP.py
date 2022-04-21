import networkx as nx
import bisect
import subprocess
import sys
import thread
import threading
import multiprocessing
import os
import signal
from copy import deepcopy

# Ladan Doroud - 
# Multiprocessing implementation of Extreme Sets using Nagamochi 2010 Minimum Degree Ordering
# This program uses multi processing. However, it does not use all the processors. no matter how many processors are there, always 3 of them will be
# left available for other calculations. This avoids freezing. 


def connected_components(G): #Gives the connected components in a graph
    if G.is_directed():
        raise nx.NetworkXError("""Not allowed for directed graph G.
            Use UG=G.to_undirected() to create an undirected graph.""")
    seen={}
    components=[]
    for v in G:
        if v not in seen:
            c=nx.single_source_shortest_path_length(G,v)
            components.append(list(c.keys()))
            seen.update(c)
    components.sort(key=len,reverse=True)
    return components

def assign_weights(self): #saves initial degree for each of the nodes and call it mu.
      list1 = []
      dictt={}
      self.mu={}
      for v in self.nodes():
            self.mu[v] = self.degree(v,weight='weight')
        #position = bisect.bisect(list1, (self.mu[v],v))
            bisect.insort(list1, (self.mu[v],v))
            dictt[v] = self.degree(v,weight='weight')
    #print "done with assign weights"
      return self.mu,list1,dictt

def extreme(GG,mu,list1,dictt): #finds extreme sets in the given graph
    print "++extreme started for ",p
    X = []
    list2 = deepcopy(list1)
    dictt2= deepcopy(dictt)

    while (len(list2)>2):
        while (len(list1)>2): # This will find the minimum degree ordering of a graph based on the list1 of its nodes
            deg_min_node, min_node = list1[0]
            min_neighbors = GG.neighbors(min_node)

            for nei in min_neighbors: #this part goes through all the nodes, to find the flat pair.
                if (nei in dictt and not (dictt[nei] is None)):
                    degr = dictt[nei]
                    list1.remove((degr,nei))
                    www= GG[nei][min_node]['weight']
                    degr2 = int(degr) - int(www)
                    if (degr2 >0):
                        bisect.insort(list1, (degr2,nei))
                        dictt[nei]=degr2
                    elif (degr2<0):
                        print "ERROR. NEGATIVE DEGREE.",nei,min_node

            
            list1.remove((deg_min_node, min_node))
            del dictt[min_node]
        
        #print "only 2 left", list1
        deg_flat1,u = list1[0]
        deg_flat2,v = list1[1]
        z = str(u)+ "_" + str(v) #Z is the potentional extreme set
        GG.add_node(z)
        
        # Remove the u and v and add the contracted version which is z in the network
        for w in GG.neighbors(u):
            if w !=v:
                ww= GG.get_edge_data(u,w,['weight'])
                GG.add_edge(z,w,ww)
                GG.remove_edge(w,u)
        
        for w in GG.neighbors(v):
            ww= GG[v][w]['weight']
            if (not(GG.has_edge(z,w))):
                GG.add_edge(z,w,weight = ww)
            else:
                pre_w = GG[z][w]['weight']
                GG.edge[z][w]['weight'] = (ww) + (pre_w)
                GG.remove_edge(w,v)

        GG.remove_node(u)
        GG.remove_node(v)
        dictt2[z]= GG.degree(z,weight='weight')
        minimum_of_uv = min(mu[u], mu[v])
        # check to see if z (contracted flat pair) should be an extreme set or not. it is an extreme set if the connection between the flat pair
        # is more than the connection of each of the flat pair nodes to the outside.
        if (GG.degree(z,weight='weight') < minimum_of_uv ):
            X.append(z)
            OUTFILE.write(z)
            OUTFILE.write("\n")
            OUTFILE.flush()
            mu[z] = GG.degree(z,weight='weight')
        else:
            mu[z] = minimum_of_uv #z was not an extreme set, I should go find the next flat pair.
        
        list2.remove((dictt2[u],u))
        list2.remove((dictt2[v],v))
        
        del dictt2[u]
        del dictt2[v]
        bisect.insort(list2, (GG.degree(z,weight='weight'),z))
        list1 =[]
        list1 = deepcopy(list2)
        dictt=deepcopy(dictt2)
    print "--extreme is finished for", p


def main(): # Main starts multiprocessing. No matter how many processors we have, it always keeps 3 of them free for other calculations.
    NUM_PROCS = multiprocessing.cpu_count()
    print "Number of processors are:", NUM_PROCS
    fname = raw_input("please enter the file name of your graph (the file should be without any file format in the end)\n")
    f= open(fname,'r')
    G=nx.Graph()
    output_name="ES_result_" + fname
    global OUTFILE
    OUTFILE = open(output_name,"a")
    global counter
    global mu
    i= 0
    counter=0
    jobs= []

    for l in f.readlines():
        z = l.split()
        if len(z) == 3:
            wei = int(z[2])
            G.add_node(z[0])
            G.add_node(z[1])
            G.add_edge(z[0],z[1],weight=wei)
        else:
            print ("Bad input: the edge",l.strip(),"is not valid")
            sys.exit(0)

    #print some info on network
    print "**********************************************************"
    #G.to_undirected()
    print ("number_of_nodes:\t",G.number_of_nodes())
    print ("number_of_edges:\t",G.number_of_edges())

    cc=connected_components(G)

    print "Number of connected components are: ",  len(cc)
    print "**********************************************************\n"

    try:
        for c in cc:
            if (len(c)>=2):
                i=i+1
                print "started for connected component ", i
                H = G.subgraph(c).copy()
                mu,list1,dictt=assign_weights(H)  # sets mu values based on original degree. we want to keep the original degree of a node.
                nodes_H_list = H.nodes()
                for index in nodes_H_list:
                    G.remove_node(index)
            #print "len(jobs) = " , len(jobs)
                global p
                p = multiprocessing.Process(target = extreme, args = (H,mu,list1,dictt, ) ) #start using a new processor
                p.daemon = True
                jobs.append(p)
                p.start()
                
            #results = result_queue.get()
                #   print "result is ready and is ", results
                while ((len(jobs)>= NUM_PROCS-3)):
                    #print "stuck in here?"
                    #time.sleep(0.1)
                    for process_p in jobs: #number of open jobs is high and might freeze the system if it becomes even more. so I have to wait til 
                                           # the jobs are finished so I can start a new job.
                        if not (process_p.is_alive()):
                            process_p.join()
                            process_p.terminate()
                            jobs.remove(process_p)
                        #process_p.close()
#                       else:
#       print "is still alive:", process_p, process_p.is_alive()

# Wait for all worker processes to finish
        for process_p in jobs:
            process_p.join()
            process_p.terminate()

    except ValueError as msg:
            print "p has problems", p,msg
    except:
            print "ERROR IN GENERAL", msg


    #jobs.join()

    # printing extreme sets.
    print "\n**********************\n\tDONE!!!!\n**********************\n\n\n"
    OUTFILE.flush()
    OUTFILE.close()
    return
main()
