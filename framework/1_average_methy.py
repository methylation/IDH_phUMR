#!/usr/bin/python
# -*-coding:utf-8 -*-
#This program was used to calculated average methylation level of WGBS samples.
import re
from itertools import islice
import numpy as np
import time
import os

star = time.clock()

#wig trans
def Readwig(rootdir):
    file = []
    with open(rootdir, "r") as wig:
        chr = "chr0"
        for line in  islice(wig, 1, None): #skip frist line
            line = line.rstrip()
            if re.search(r"chrom", line): #Identify chr
                        arr = line.split("=")
                        chr = arr[1] #Extract chr
            else:
                        arr = line.split("\t")
                        file.append( list([chr,arr[0],arr[1]])) #trans to three cols(chr,site,methylation)
    return file

#store three samples into hash
def con_hash(x):
    for i in range(len(x)):
        keys = x[i][0]+","+x[i][1] #set keys as "chr,site"
        if (keys in h.keys()):
            h[keys]=str(h[keys])+"\t"+x[i][2] #if keys have been exsited, append current value to Previous values 
        else:
            h[keys]=x[i][2]
    return h

#Calculate the average methylation
def methy_ave(x):
    k = []
    k = list(x.keys())
    m_ave = 0
    t = []
    res = []
    for i in range(len(k)):
        x[k[i]].split("\t")
        m_ave = round(np.mean(list(map(float,x[k[i]].split("\t")))),5) #get means of every value in hash  
        t = k[i].split(",")
        lines = list([t[0],t[1],m_ave]) #(chr,site,methylation_average)
        res.append(lines)
    return res

#read normal methylation wig
input_normal1 = 'brain_1_methy.wig'
normal1 = Readwig(input_normal1)
print(input_normal1+"  "+str(len(normal1)))
input_normal2 = 'brain_2_methy.wig'
normal2 = Readwig(input_normal2)
print(input_normal2+"  "+str(len(normal2)))
input_normal3 = 'brain_3_methy.wig'
normal3 = Readwig(input_normal3)
print(input_normal3+"  "+str(len(normal3)))

#read IDH-GBM methylation wig
input_idh1 = 'IDH-GBM1.wig'
idh1 = Readwig(input_idh1)
print(input_idh1+"  "+str(len(idh1)))
input_idh2 = 'IDH-GBM2.wig'
idh2 = Readwig(input_idh2)
print(input_idh2+"  "+str(len(idh2)))
input_idh3 = 'IDH-GBM3.wig'
idh3 = Readwig(input_idh3)
print(input_idh3+"  "+str(len(idh3)))

#read WT-GBM methylation wig
input_wt1 = 'WT-GBM1.wig'
wt1 = Readwig(input_wt1)
print(input_wt1+"  "+str(len(wt1)))
input_wt2 = 'WT-GBM2.wig'
wt2 = Readwig(input_wt2)
print(input_wt2+"  "+str(len(wt2)))
input_wt3 = 'WT-GBM3.wig'
wt3 = Readwig(input_wt3)
print(input_wt3+"  "+str(len(wt3)))

keys = ''
h = {}
nor_ha1 = con_hash(normal1)
nor_ha2 = con_hash(normal2)
nor_ha3 = con_hash(normal3) #store three samples into hash
print("normalcon_hash has been  finished ")

keys = ''
h = {}
idh_ha1 = con_hash(idh1)
idh_ha2 = con_hash(idh2)
idh_ha3 = con_hash(idh3) #store three samples into hash
print("idhcon_hash has been  finished ")

keys = ''
h = {}
wt_ha1 = con_hash(wt1)
wt_ha2 = con_hash(wt2)
wt_ha3 = con_hash(wt3) #store three samples into hash
print("wtcon_hash has been  finished ")

nor_ave = methy_ave(nor_ha3)
print("nor_ave has been finished.")
idh_ave = methy_ave(idh_ha3)
print("idh_ave has been finished.")
wt_ave = methy_ave(wt_ha3) #Calculate the average methylation
print("wt_ave has been finished.")

elapsed = (time.clock() - star)
print("Time used:",elapsed)

#store data into hash again
nor_ave_key = ''
nor_ave_ha = {}
for i in range(len(nor_ave)):
    nor_ave_key = nor_ave[i][0]+","+str(int(nor_ave[i][1])+1) #normal CGsite +1
    nor_ave_ha[nor_ave_key]= float(nor_ave[i][2]) #"chr,site → methylation_average
print("nor avervage  "+str(len(nor_ave_ha.keys())))

idh_ave_key = ''
idh_ave_ha = {}
for i in range(len(idh_ave)):
    idh_ave_key = idh_ave[i][0]+","+idh_ave[i][1]
    idh_ave_ha[idh_ave_key]= float(idh_ave[i][2]) #"chr,site → methylation_average
print("idh avervage  "+str(len(idh_ave_ha.keys())))

wt_ave_key = ''
wt_ave_ha = {}
for i in range(len(wt_ave)):
    wt_ave_key = wt_ave[i][0]+","+wt_ave[i][1]
    wt_ave_ha[wt_ave_key]= float(wt_ave[i][2]) #"chr,site → methylation_average
print("wt avervage  "+str(len(wt_ave_ha.keys())))


#gbm_methylation_average minus normal_methylation_average, output to files
idh_nor_k = []
idh_nor_k = list(set(idh_ave_ha.keys()) & set(nor_ave_ha.keys()))  #get common site
print("idh_nor_k   "+str(len(idh_nor_k)))
idh_nor_m = 0
idh_nor_t = []
out = open("idh-nor.bed", "w+")
for i in range(len(idh_nor_k)):
    idh_nor_m = round((idh_ave_ha[idh_nor_k[i]]-nor_ave_ha[idh_nor_k[i]]),5) #idh_methylation_average minus normal_methylation_average
    idh_nor_t = idh_nor_k[i].split(",") 
    out.write( idh_nor_t[0]+ "\t" + idh_nor_t[1] + "\t"+ str(idh_nor_m) +"\n") #chr,site,idh-nor_methylation
out.close()
print("idh-nor has been finished.")

wt_nor_k = []
wt_nor_k = list(set(wt_ave_ha.keys()) & set(nor_ave_ha.keys())) #get common site
print("wt_nor_k   "+str(len(wt_nor_k)))
wt_nor_m = 0
wt_nor_t = []
out = open("wt-nor.bed", "w+")
for i in range(len(wt_nor_k)):
    wt_nor_m = round((wt_ave_ha[wt_nor_k[i]]-nor_ave_ha[wt_nor_k[i]]),5) #wt_methylation_average minus normal_methylation_average
    wt_nor_t = wt_nor_k[i].split(",")
    out.write( wt_nor_t[0]+ "\t" + wt_nor_t[1] + "\t"+ str(wt_nor_m) +"\n") #chr,site,wt-nor_methylation
out.close()
print("wt-nor has been finished.")
elapsed = (time.clock() - star)
print("Time used:",elapsed)

#Sort gbm-nor to reduce program running time
os.system('sort -t $\'\t\' -k 1,1 -k 2n,2 idh-nor.bed >idh-norsorted.bed')
print("idh-nor.bed has been sorted.")
os.system('sort -t $\'\t\' -k 1,1 -k 2n,2 wt-nor.bed >wt-norsorted.bed')
print("wt-nor.bed has been sorted.")

elapsed = (time.clock() - star)
print("Time used:",elapsed)

#read idh-norsorted.bed
input_idh_nor = 'idh-norsorted.bed'
idh_nor = []
with open(input_idh_nor, "r") as lines:
    for line in  lines:
        line = line.rstrip()
        arr = line.split("\t")
        ins = list(arr)
        idh_nor.append(ins)
print("idh-norsorted.bed  "+str(len(idh_nor)))

#read wt-norsorted.bed
input_wt_nor = 'wt-norsorted.bed'
wt_nor = []
with open(input_wt_nor, "r") as lines:
    for line in  lines:
        line = line.rstrip()
        arr = line.split("\t")
        ins = list(arr)
        wt_nor.append(ins)
print("wt-norsorted.bed  "+str(len(wt_nor)))

#read referenceUMR
input_ref_UM = 'ref_UM.bed'
ref_UM = []
with open(input_path1, "r") as lines:
        for line in islice(lines, 1, None): #skip frist line
            line = line.rstrip()
            arr = line.split("\t")
            ins = list(arr)
            ref_UM.append(ins)
print("ref_UM.bed  "+str(len(ref_UM)))

#take sites which exist in referenceUMR
start = ''
end = ''
ind = 0
l = len(idh_nor)
out = open("mutregion.txt", "w+")
for i in range(len(ref_UM)):
    chr = ref_UM[i][0]
    start = ref_UM[i][1] #set start as ref_UM startcol
    end = ref_UM[i][2] #set end as ref_UM endcol
    while (idh_nor[ind][0]!=chr): #skip lines of uncommon chr
        ind = ind + 1
        if (ind >= l): #break at last line
            break
    if (ind >= l): #break at last line
        break
    while (int(idh_nor[ind][1])<int(start)):  #Skip those lines that sites less than start
        ind = ind+1
        if (ind >= l):
            break
    if (ind >= l):
        break
    while int(idh_nor[ind][1])<=int(end): 
        out.write(idh_nor[ind][0] + "\t" + start + "\t" + end + "\t" + idh_nor[ind][1] + "\t" + idh_nor[ind][2] + "\n") #output (chr,start,end,site,methylation)
        ind = ind + 1
        if ind >= l:
            break
    if (ind >= l):
        break
out.close()

print("mutregion.txt    finished")

        
start = ''
end = ''
ind = 0
l = len(wt_nor)
out = open("wtregion.txt", "w+")
for i in range(len(ref_UM)):
    chr = ref_UM[i][0]
    start = ref_UM[i][1] #set start as ref_UM startcol
    end = ref_UM[i][2] #set end as ref_UM endcol
    while (wt_nor[ind][0]!=chr): #skip lines of uncommon chr
        ind = ind + 1
        if (ind >= l):  #break at last line
            break
    if (ind >= l): #break at last line
        break
    while (int(wt_nor[ind][1])<int(start)):  #Skip those lines that sites less than start
        ind = ind+1
        if (ind >= l):
            break
    if (ind >= l):
        break
    while (int(wt_nor[ind][1])<=int(end))&(wt_nor[ind][0]==chr):
        out.write(wt_nor[ind][0] + "\t" + start + "\t" + end + "\t" + wt_nor[ind][1] + "\t" + wt_nor[ind][2] + "\n") #output (chr,start,end,site,methylation)
        ind = ind + 1
        if ind >= l:
            break
    if (ind >= l):
        break
out.close()

print("wtregion.txt    finished")
