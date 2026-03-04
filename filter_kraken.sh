#!/bin/bash
#SBATCH --job-name=filter_kraken_s_gallolyticus-2
#SBATCH --time=24:00:00
#SBATCH -e /scratch/yutingga/decontam/filtered_fasta/outerr/slurm.gallolyticus.%j.err
#SBATCH -c 4
#SBATCH -N 1
#SBATCH --mem=30G
#SBATCH -p general
#SBATCH -q public
#SBATCH --mail-user=cale8589@colorado.edu
#SBATCH --mail-type=END,FAIL

module load mamba
source activate biobakery3

set -euo pipefail

#taxids=$(tail -n +2 /scratch/yutingga/decontam/filtered_kraken/verus/contaminant_ids_EB8_LB4.txt | tr '\n' ' ')

extract_script=/scratch/yutingga/decontam/filtered_fasta/extract_kraken_reads.py

kraken_dir=/scratch/yutingga/eager_results/roxellana/results/metagenomic_classification/kraken
fq_dir=/scratch/yutingga/eager_results/roxellana/results/samtools/filter
out_dir=/scratch/yutingga/decontam/filtered_fasta/S_gallolyticus
mkdir -p "$out_dir"
cd "$out_dir"

samples=("01-49" "01-50" "01-51" "01-52" "01-53" "01-54" "01-55")

for sample in "${samples[@]}"; do
  kraken_out="$kraken_dir/${sample}.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken.out"
  kraken_report="$kraken_dir/${sample}.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report"
  fq_in="$fq_dir/${sample}.unmapped.fastq.gz"
  out_fq="$out_dir/cleaned.${sample}.unmapped.fasta"
#  python "$extract_script" -k "$kraken_out" -r "$kraken_report" -s1 "$fq_in" -o "$out_fq" --taxid $taxids --exclude
python "$extract_script" -k "$kraken_out" -r "$kraken_report" -s1 "$fq_in" -o "$out_fq" -t 315405 --fastq-output
done
