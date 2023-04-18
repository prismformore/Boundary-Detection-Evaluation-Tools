#!/usr/bin/python

# ----- Parameters passed to the cluster -------
#$ -S /usr/bin/python
#$ -l h_rt=05:59:00
#$ -l h_vmem=5000M
#$ -o /scratch_net/reinhold/Kevis/logs/
#$ -e /scratch_net/reinhold/Kevis/logs/
#$ -j y

# ------------- Examples of usage --------------
# qsub -N evalFb -t 1-100 eval_in_cluster.py COB     PASCALContext read_one_ucm      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py HED     BSDS500       read_one_cont_png fb 1 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py LEP     BSDS500       read_one_lep      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py MCG     BSDS500       read_one_ucm      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py ISCRA   BSDS500       read_one_ucm      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py gPb-UCM BSDS500       read_one_ucm      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py NWMC    BSDS500       read_one_ucm      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py IIDKL   BSDS500       read_one_ucm      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py EGB     BSDS500       read_one_prl      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py MShift  BSDS500       read_one_prl      fb 0 100
# qsub -N evalFb -t 1-100 eval_in_cluster.py NCut    BSDS500       read_one_prl      fb 0 100

# qsub -N evalFb -t 1-100 eval_in_cluster.py COB     PASCALContext read_one_ucm      fop 0 100
# qsub -N evalFop -t 1-20 eval_in_cluster.py LEP     BSDS500       read_one_lep      fop 0 20
# qsub -N evalFop -t 1-20 eval_in_cluster.py MCG     BSDS500       read_one_ucm      fop 0 20
# qsub -N evalFop -t 1-20 eval_in_cluster.py gPb-UCM BSDS500       read_one_ucm      fop 0 20
# qsub -N evalFop -t 1-20 eval_in_cluster.py NWMC    BSDS500       read_one_ucm      fop 0 20
# qsub -N evalFop -t 1-20 eval_in_cluster.py IIDKL   BSDS500       read_one_ucm      fop 0 20
# qsub -N evalFop -t 1-20 eval_in_cluster.py EGB     BSDS500       read_one_prl      fop 0 20
# qsub -N evalFop -t 1-20 eval_in_cluster.py MShift  BSDS500       read_one_prl      fop 0 20
# qsub -N evalFop -t 1-20 eval_in_cluster.py NCut    BSDS500       read_one_prl      fop 0 20

# ------------Hard-Coded Parameters ------------
#code_folder = '/srv/glusterfs/jpont/dev/seism-dev/'
code_folder = '/scratch_net/reinhold/Kevis/Software/seism'

# ----------------- Imports --------------------
import os
import numpy as np
import math
import sys

# ---------------- Functions -------------------
def file_len(fname):
    i = -1
    with open(fname) as f:
        for i, l in enumerate(f):
            pass
    return i + 1

def file_subpart(fname,id_start,id_end):
    lines = [line.strip() for line in open(fname)]
    return lines[id_start:id_end+1]


# ------------- Get the parameters -------------
if len(sys.argv)<6:
	print "ERROR: Not enough input parameters"
  	exit(1)
else:
  	method = sys.argv[1] # Name of the folder containing the partitions or contours
	database = sys.argv[2] # Name of the database: {BSDS500, PASCALContext, Pascal, SBD,..}
  	io_func = sys.argv[3] # I/O function
  	measure = sys.argv[4] # fb or fop
  	contour  = sys.argv[5] # Contour or segmentation

if len(sys.argv)>6:
  	n_jobs = int(sys.argv[6])
else:
  	n_jobs = 1

if database=='BSDS500':
	gt_set = 'test'
elif database == 'PASCALContext':
	gt_set = 'test_new'
elif database == 'Pascal':
	gt_set = 'Segmentation_val_2012'
elif database == 'SBD':
	gt_set = 'val'
	if len(sys.argv)>7:
		cat_id = sys.argv[7]
	else:
		print 'category id not defined: Evaluating default category Person'
		cat_id='15'
else:
	print "ERROR: Unknown database"
	exit(1)
    
# Check that we are in the right folder
if not os.path.isdir(code_folder + "/datasets/"):
	print "ERROR: datasets folder not found, are you in the code folder of SEISM?"
	exit(1)
if not os.path.isdir(code_folder + "/src/") or not os.path.exists(code_folder + "/install.m"):
	print "ERROR: Source code not found, are you in the code folder of SEISM?"
	exit(1)


# ---------------- Main code -------------------
ids_file = code_folder + "/src/gt_wrappers/gt_sets/" + database + "/" + gt_set + ".txt"
par_file    = code_folder + "/parameters/"+method+".txt"

task_id = int(os.getenv("SGE_TASK_ID", "0"))
if task_id==0:
    task_id = 1
    n_jobs = 1
if task_id>n_jobs:
    exit(1)

print "Process " + str(task_id) + " out of " + str(n_jobs)
sys.stdout.flush()

# Get the total number of images
n_pars = file_len(par_file)
n_ims  = file_len(ids_file)

# Get the positions that this process will handle
jobs_per_child = int(math.floor(float(n_pars)/n_jobs))
remainder = n_pars%n_jobs

# We put the remainder to the first 'remainder' jobs
if task_id<=remainder:
    id_start = (jobs_per_child+1)*(task_id-1)+1
    id_end   = (jobs_per_child+1)*(task_id)
else:
    id_start = (jobs_per_child+1)*remainder + jobs_per_child*(task_id-1-remainder) + 1
    if task_id==n_jobs:
        id_end = n_pars
    else:
        id_end = id_start+jobs_per_child-1

print 'id_start='+str(id_start)
print 'id_end='+str(id_end)

# Get all parameters
all_params = [line.rstrip('\n') for line in open(par_file)]

# Run the actual code
os.chdir(code_folder)
for ii in range(id_start-1,id_end):
    res_file = code_folder + "/results/"+database+"/"+method+"/"+gt_set+"_"+measure+"_"+all_params[ii]+".txt"
    run = 1;
    if os.path.isfile(res_file):
        print 'Found: ' + res_file
        if file_len(res_file)==n_ims:
            run = 0;

    if run==1:
		if 'cat_id' in globals():
			command_to_run = "/usr/sepp/bin/matlab -nodesktop -nodisplay -nosplash -r \"install;eval_method('"+method+"','"+all_params[ii]+"','"+measure+"',@"+io_func+",'"+database+"','"+gt_set+"',"+str(n_ims)+","+contour+","+cat_id+");exit\""
		else:
			command_to_run = "/usr/sepp/bin/matlab -nodesktop -nodisplay -nosplash -r \"install;eval_method('"+method+"','"+all_params[ii]+"','"+measure+"',@"+io_func+",'"+database+"','"+gt_set+"',"+str(n_ims)+","+contour+");exit\""
			
		#print command_to_run
		os.system(command_to_run)



