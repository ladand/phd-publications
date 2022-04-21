#!/bin/sh

./make_adjacency.py input/netsci-G.csv input/netsci-V.csv > output/test-A.csv
./eccentricity.py input/netsci-G.csv input/netsci-V.csv > output/test-M.csv

