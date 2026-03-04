#!/bin/bash
#SBATCH --partition=amilan
#SBATCH --job-name=fastp_0809
#SBATCH --output=fastp_20250422_0809.%j.out
#SBATCH --time=24:00:00
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks=16 
#SBATCH --mail-type=ALL
#SBATCH --mail-user=yuga3894@colorado.edu
#SBATCH --account=ucb-general

# this is the script worked in April 18 2025 Friday test_fastp 
# acompile (if not in sbatch job)
ml anaconda
conda activate fastp

# Directory containing FASTQ files
FASTQ_DIR="./1_fq_R1R2"  # Directory with paired-end fastq files
OUTPUT_DIR="./2_fastp"    # Output directory for processed files
FASTP_REPORTS_DIR="./2_fastp_reports"
CSV_FILE="host_reference.csv"  # CSV file with sample IDs and species

# Ensure the output directories exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$FASTP_REPORTS_DIR"

# Process each pair of FASTQ files
processed_samples=()

# Find all forward files (either *_F.fastq.gz or *_L002_R1_001.fastq.gz)
# for forward_file in "$FASTQ_DIR"/*_{F.fastq.gz,L002_R1_001.fastq.gz}; do
for forward_file in "$FASTQ_DIR"/*{08,09}*_{F.fastq.gz,L002_R1_001.fastq.gz}; do
    # Skip if no files found (globbing returns pattern when no matches)
    [ -f "$forward_file" ] || continue
    # Extract base sample ID from filename
    filename=$(basename "$forward_file")
    
    # Handle F.R1.EB.LB
    if [[ $filename =~ ^(NW|FD|EB|LB)-?([0-9]+)_ ]]; then
        prefix=${BASH_REMATCH[1]}
        num=${BASH_REMATCH[2]}      
	num=$((10#$num))  # Force decimal
    	if (( num < 10 )); then
		sample_id="${prefix}0${num}"
    	else
        	sample_id="${prefix}${num}"
    	fi

	 # Skip if we've already processed this sample
    if [[ " ${processed_samples[@]} " =~ " $sample_id " ]]; then
        continue
    fi
    processed_samples+=("$sample_id")
    
    # Determine reverse file name
    if [[ $forward_file == *_F.fastq.gz ]]; then
        reverse_file="${forward_file/_F.fastq.gz/_R.fastq.gz}"
    else
        reverse_file="${forward_file/_R1_001.fastq.gz/_R2_001.fastq.gz}"
    fi
    # Check if reverse file exists
    if [ ! -f "$reverse_file" ]; then
        echo "Warning: Reverse file not found for $forward_file"
        continue
    fi
    
    
# Look up species in CSV file (only if not EB/LB file)
    if [[ "$filename" =~ (EB|LB) ]]; then
        species=""  # No species needed for EB/LB files
        echo "Note: Skipping species lookup for EB/LB file $filename"
    else
        species=$(awk -F, -v id="$sample_id" '$2 == id {print $3}' "$CSV_FILE" | head -1)
        if [ -z "$species" ]; then
            echo "Warning: No species found for $sample_id in $CSV_FILE"
            continue
        fi
    fi

    # Define output filenames based on EB/LB status
    if [[ "$filename" =~ (EB|LB) ]]; then
        merged_file="${OUTPUT_DIR}/${sample_id}_fastp.fastq.gz"
        json_report="${FASTP_REPORTS_DIR}/${sample_id}.fastp.json"
        html_report="${FASTP_REPORTS_DIR}/${sample_id}.fastp.html"
    else
        merged_file="${OUTPUT_DIR}/${sample_id}_${species}_fastp.fastq.gz"
        json_report="${FASTP_REPORTS_DIR}/${sample_id}_${species}.fastp.json"
        html_report="${FASTP_REPORTS_DIR}/${sample_id}_${species}.fastp.html"
    fi

    echo "Processing $sample_id ($species)"
    echo "Forward file: $forward_file"
    echo "Reverse file: $reverse_file"
    echo "Output file: $merged_file"
    
# Run fastp with all original comments preserved
fastp \
    -i "$forward_file" -I "$reverse_file" \
    --thread 16 \
    -q 25 \
    -u 30 \
    --cut_mean_quality 30 \
    --cut_right \
    --cut_window_size 4 \
    --length_required 30 \
    -e 20 \
    --low_complexity_filter \
    --detect_adapter_for_pe \
    --trim_poly_g \
    --trim_poly_x \
    --dedup \
    --dup_calc_accuracy 3 \
    -m --merged_out "$merged_file" \
    --overlap_len_require 11 \
    --overlap_diff_limit 3 \
    --json "$json_report" \
    --html "$html_report"
echo "Processed $forward_file and $reverse_file into $merged_file"    
    
done

# Run MultiQC after all samples are processed
ml multiqc
multiqc "$FASTP_REPORTS_DIR/" -o "$FASTP_REPORTS_DIR/multiqc_report.html"

