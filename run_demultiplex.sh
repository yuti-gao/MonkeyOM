#!/bin/bash

#SBATCH --partition=amilan
#SBATCH --qos=long
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=7-00:00:00
#SBATCH --job-name=demult
#SBATCH --output=demult.%j.out

ml purge
python3 demultiplex_by_inline_barcode_1115.py
