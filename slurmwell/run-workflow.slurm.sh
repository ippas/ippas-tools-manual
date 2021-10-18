#!/usr/bin/env bash

#SBATCH -A plgsportwgs
#SBATCH -p plgrid-now
#SBATCH -t 12:0:0
#SBATCH --mem=2GB
#SBATCH --cpus-per-task=1
#SBATCH -C localfs
# #SBATCH --output=/net/archive/groups/plggneuromol/slurm-log/%j.out
# #SBATCH --error=/net/archive/groups/plggneuromol/slurm-log/%j.err

# module load plgrid/tools/cromwell - korzystamy z nowszego
module load plgrid/tools/java11/11
export TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"

sg plggneuromol -c 'java \
	-Dconfig.file=config.conf \
	-Djava.io.tmpdir=$SCRATCH_LOCAL \
	-jar $TOOLS_DIR/cromwell run \
		alignment-light.wdl \
		--inputs inputs.json \
		--options options.json'
