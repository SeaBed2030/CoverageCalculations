#!/bin/sh
# Script to generate grids for calcuation of percentage coverage using blockmedians
# The routines used are from the Generic Mapping Tools (GMT) system: http://gmt.soest.hawaii.edu/
# Input data are geographic longitude/longitude co-ordinates in the form of x,y,z files (z = depth, -ve).
# Data must be split into blocks – due to the volume of data; the size of the intermediate grid files and processing time required.
#Inputs:
#$1 = block number
#$2 = minimum longitude
#$3 = maximum longitude
#$4 = minimum latitude
#$5 = maximum latitude
#blockmedian filter the input data to 3.75 arc-seconds (~100m); 7.5 arc-seconds (~200m); 15 arc-seconds (~400m) and 30 arc-seconds (~800m)
blockmedian  block$1.xyz -I3.75s -R$2/$3/$4/$5 -r -V -Q > block$1_100m.med
blockmedian  block$1.xyz -I7.5s -R$2/$3/$4/$5 -r -V -Q > block$1_200m.med
blockmedian  block$1.xyz -I15s -R$2/$3/$4/$5 -r -V -Q > block$1_400m.med
blockmedian  block$1.xyz -I30s -R$2/$3/$4/$5 -r -V -Q > block$1_800m.med

#grid the filtered data (no interpolation of data) at each resolution
xyz2grd block$1_100m.med -Gblock$1_100m.nc=ni -I3.75s -R$2/$3/$4/$5 -r -V
xyz2grd block$1_200m.med -Gblock$1_200m.nc=ni -I7.5s -R$2/$3/$4/$5 -r -V
xyz2grd block$1_400m.med -Gblock$1_400m.nc=ni -I15s -R$2/$3/$4/$5 -r -V
xyz2grd block$1_800m.med -Gblock$1_800m.nc=ni -I30s -R$2/$3/$4/$5 -r -V

#sample the grids to 100m
grdsample block$1_200m.nc -Gblock$1_200m_samp.nc=ni -I3.75s -nn
grdsample block$1_400m.nc -Gblock$1_400m_samp.nc=ni -I3.75s -nn
grdsample block$1_800m.nc -Gblock$1_800m_samp.nc=ni -I3.75s -nn

#clip the depth range in the sampled grids as per criteria outlined in the Concept Paper on Seabed 2030: https://www.mdpi.com/2076-3263/8/2/63/html
grdclip block$1_200m_samp.nc -Gblock$1_200m_samp_clip.nc -Si-3000/-1500/200 -Sb-3000/NaN -Sa-1500/NaN
grdclip block$1_400m_samp.nc -Gblock$1_400m_samp_clip.nc -Si-5750/-3000/400 -Sb-5750/NaN -Sa-3000/NaN
grdclip block$1_800m_samp.nc -Gblock$1_800m_samp_clip.nc -Sb-5750/800 -Sa-5750/NaN -Sr-5750/NaN
grdclip block$1_100m.nc -Gblock$1_100m_samp_clip.nc -Si-1500/0/100 -Sb-1500/NaN -Sa0/NaN -Sr0/NaN

#add together the grids to produce a final grid containing all the data
grdmath block$1_400m_samp_clip.nc block$1_800m_samp_clip.nc AND = paste1.nc
grdmath block$1_200m_samp_clip.nc paste1.nc AND = paste2.nc
grdmath block$1_100m_samp_clip.nc paste2.nc AND = block$1_stat.nc=ni
grdmath block$1_stat.nc 1 AND = block$1_stat_ref.nc=ni

#Adding in land areas
grdclip land_$1.nc –Gland_clip_$1.nc=ni -Sb0/NaN -Sa0/-8888 -Sr0/NaN -R$2/$3/$4/$5
grdsample land_clip_$1.nc –Gland_clip_$1_clip.nc -I3.75s -nn
grdmath land_clip_$1_clip.nc block$1_stat_ref.nc AND = block$1_stat_ref_2.nc=ni
