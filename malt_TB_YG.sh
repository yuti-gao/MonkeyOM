#!/bin/bash

#SBATCH --job-name=malt-TB
#SBATCH --time=1-00:00:00
#SBATCH -o slurm.%A_%a.out
#SBATCH -e slurm.%A_%a.err
#SBATCH --cpus-per-task=20
#SBATCH -N 1
#SBATCH --mem=60G
#SBATCH -p general
#SBATCH -q public
#SBATCH --mail-user=yutingga@asu.edu
#SBATCH --mail-type=END,FAIL

# Inputs live here
gz_files_dir="/scratch/yutingga/decontam/filtered_fasta/TB"

# All outputs go here (BBDuk + MALT)
outdir="/scratch/yutingga/MALT_TB/output_decontam"

# Tools / resources
module load bbmap-39.01-gcc-12.1.0

malt_run="/data/stonelab/maxine_malt/malt_software/malt-run"
malt_index="/data/stonelab/metagenomic_databases/malt/mycobacteriaceae/index/"

mkdir -p "$outdir"
cd "$gz_files_dir"

# 1) Low-complexity filtering (reads input here, writes output to $outdir)
for file in *.unmapped.fasta; do
  base="$(basename "$file" .fasta)"         # e.g., LHC02_..._L002.unmapped
  out="${outdir}/${base}.highC.fasta"       # write to output dir
# threads=cpus-per-task
  bbduk.sh in="$file" out="$out" entropy=0.90 entropywindow=20 entropyk=5 threads=20
done

# 2) MALT on filtered reads (reads from $outdir, writes to $outdir)
for file in "$outdir"/*.unmapped.highC.fasta; do
  base="$(basename "$file" .fasta)"         # drop .fastq.gz
  output_file="${outdir}/${base}.rma"          # .rma in output dir
# threads=cpus-per-task
  "$malt_run" --mode BlastN -at SemiGlobal --minPercentIdentity 85 -t 20 \
    --index "$malt_index" \
    --output "$output_file" \
    --inFile "$file"
done
