#!/bin/bash

#SBATCH --partition plgrid-testing
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1  # has to be defined explicitly
#SBATCH --cpus-per-task=1
#SBATCH --mem=2GB
#SBATCH --time 1:00:00
#SBATCH -C localfs
#SBATCH --job-name jupyter-notebook


# start spark
module load plgrid/apps/spark/2.4.5
start_spark_cluster

# source python virtual environment
source venv-hail-0.2.64/bin/activate

## get tunneling info
XDG_RUNTIME_DIR=""
ipnport=$(shuf -i8000-9999 -n1)
ipnport_local=$ipnport
ipnip=$(hostname -i)

# start an ipcluster instance and launch jupyter server
jupyter notebook --no-browser --port=$ipnport --ip=$ipnip &
sleep 5

# print tunneling instructions
echo -e "
Copy/Paste this in your local terminal to ssh tunnel with remote
-----------------------------------------------------------------
ssh -o ServerAliveInterval=300 -N -L $ipnport_local:$ipnip:$ipnport ${USER}@pro.cyfronet.pl
-----------------------------------------------------------------

Then open a browser on your local machine to the following address
------------------------------------------------------------------
$(jupyter notebook list | sed -r 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/localhost/')
------------------------------------------------------------------
"
sleep infinity
