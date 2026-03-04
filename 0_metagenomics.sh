#!/bin/bash

#SBATCH --partition=amilan
#SBATCH --job-name=LHC
#SBATCH --output=LHC_fastp_kraken2.%j.out
#SBATCH --time=24:00:00
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks=64
#SBATCH --mail-type=ALL
#SBATCH --mail-user=yuga3894@colorado.edu
#SBATCH --account=ucb435_asc1

module load anaconda

#download seqeunce file from seqeucning center
#read multiQC fastQC report
#https://mugenomicscore.missouri.edu/PDF/FastQC_Manual.pdf
#unzip 
#tar -xvf Malhi_Yuti_Gao_20240411.2024429.tar.bz2 

#########################FASTP##########################
#fastp.sh
conda activate fastp

# Directory containing FASTQ files
#FASTQ_DIR="/pl/active/villanea_lab/y_gao_data/LHC"  # This represents the current directory
#OUTPUT_DIR="/pl/active/villanea_lab/y_gao_data/LHC/LHC_after_fastp"  # Output directory for merged files

# Ensure the output directory exists or create it
#mkdir -p "$OUTPUT_DIR"

# Loop through all files containing "R1.fastq.gz"
# for file in "$FASTQ_DIR"/*_R1_001.fastq.gz; do
    # Extract the base identifier up to the first "_R1_001.fastq.gz" (e.g., "FD23_CCAAGGTT-GCTATCCT_L002" from "FD23_CCAAGGTT-GCTATCCT_L002_R1_001.fastq.gz")
  # base_identifier=$(basename "$file" "_R1_001.fastq.gz")

    # Define the forward and reverse file names using the exact base identifier
   # forward_file="$FASTQ_DIR/${base_identifier}_R1_001.fastq.gz"
    #reverse_file="$FASTQ_DIR/${base_identifier}_R2_001.fastq.gz"
    #merged_file="$OUTPUT_DIR/${base_identifier}.fastq.gz"

    # Run fastp for merging
    #fastp -i "$forward_file" -I "$reverse_file" -m --merged_out "$merged_file"

    #echo "Processed $forward_file and $reverse_file into $merged_file"
#done

####################KRAKEN2######################
conda activate kraken2

###run all
#kraken2 --db /pl/active/villanea_lab/y_gao_data/Malhi_Gao/standard_db/ --threads 16 --report kraken2_report.txt --output kraken2_output.txt  /pl/active/villanea_lab/y_gao_data/2_fq_after_fastp/*.fastq.gz
#kraken2 --db /pl/active/villanea_lab/y_gao_data/Malhi_Gao/standard_db/ --threads 16 --report kraken2_report.txt --output kraken2_output.txt  /pl/active/villanea_lab/y_gao_data/2_fq_after_fastp/*.fastq

###run each sample 

#!/bin/bash

cd /pl/active/villanea_lab/y_gao_data/LHC/Kraken2_LHC

# Define the directory containing your files
input_dir="/pl/active/villanea_lab/y_gao_data/LHC/LHC_after_fastp"

# Define the Kraken2 database
db="/pl/active/villanea_lab/y_gao_data/4_Kraken2/standard_db/"
# Define the number of threads to use
threads=24

# Loop through all .fastq and .fastq.gz files in the directory
for file in "$input_dir"*.fastq*; do
    # Extract the base name without the extension
    base_name=$(basename "$file")
    base_name_no_ext="${base_name%.*}"
    
    # Define the output file names
    report_file="${input_dir}${base_name_no_ext}_report.txt"
    output_file="${input_dir}${base_name_no_ext}_output.txt"
    
    # Run Kraken2
    kraken2 --db "$db" --threads "$threads" --report "$report_file" --output "$output_file" "$file"
    # Print commands for verification
    echo "kraken2 --db "$db" --threads "$threads" --report "$report_file" --output "$output_file" "$file""
done

###############################BRACKEN#######################
####build database
#bracken-build -d $DBNAME -t ${THREADS} -k ${KMER_LEN} -l ${READ_LEN}
#bracken-build -d /pl/active/villanea_lab/y_gao_data/4_Kraken2/standard_db/ -t 16 -k 35 -l 150
# kmer2read_distr -d /pl/active/villanea_lab/y_gao_data/4_Kraken2/standard_db/ -t 16 -l 150

#run braken for abundance estimation
#bracken -d $DBNAME -i sample_report.txt -o sample_report.bracken -r ${READ_LEN} -l ${LEVEL} -t ${THRESHOLD}
#bracken -d /pl/active/villanea_lab/y_gao_data/4_Kraken2/standard_db/ -i  "$report_file" -o ${base_name_no_ext}.bracken -r 150 -t 16 

################ run for primates kraken results 
#!/bin/bash

# Define variables
cd /pl/active/villanea_lab/y_gao_data/4_Kraken2/
KRAKEN_DB="/pl/active/villanea_lab/y_gao_data/Standard-16"
REPORTS_DIR="/pl/active/villanea_lab/y_gao_data/4_Kraken2"
READ_LEN=150
CLASSIFICATION_LEVEL="S"  # Adjust if you need a different level
THRESHOLD=10  # Default threshold; adjust if needed

# Loop through all report files in the specified directory ending with _report.txt
for report in ${REPORTS_DIR}*_report.txt; do
    # Create the output filename by replacing _report.txt with .bracken
    output="${report%_report.txt}.bracken"
    
    # Run Bracken for the current report
    bracken -d $KRAKEN_DB -i $report -o $output -r $READ_LEN -l $CLASSIFICATION_LEVEL -t $THRESHOLD

    # Print a message indicating completion for the current file
    echo "Processed $report into $output"
done

echo "All files processed successfully."

