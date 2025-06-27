#!/bin/bash
exec &> >(tee -a "download_log_$(date +'%Y%m%d_%H%M%S').txt")

# -----------------------------------------------------------------------------
# Script: Download and Rename ENA FASTQ Files with MD5 Verification
# Usage: ./download_ENA.sh
# input files:md5_filereport_read_run_PRJEB49638_tsv.txt
#             moraitou2022_gorilla_ena-file-download-read_run-PRJEB49638-fastq_ftp-20250424-1631.sh
# Output: Files renamed as `Species_Accession_1.fastq.gz` + checksum validation
# -----------------------------------------------------------------------------

# Step 1: Load metadata into associative arrays
declare -A species_map
declare -A md5_map
declare -A ftp_map

while IFS=$'\t' read -r accession _ _ _ _ scientific_name fastq_md5 fastq_ftp _ _ _; do
    # Clean species name (replace spaces with underscores)
    scientific_name_clean=${scientific_name// /_}
    species_map["$accession"]="$scientific_name_clean"

    # Extract MD5 hashes for _1/_2 files (split by ';')
    IFS=';' read -r md5_1 md5_2 <<< "$fastq_md5"
    md5_map["${accession}_1"]="$md5_1"
    md5_map["${accession}_2"]="$md5_2"

    # Extract FTP URLs for _1/_2 files (split by ';')
    IFS=';' read -r ftp_1 ftp_2 <<< "$fastq_ftp"
    ftp_map["${accession}_1"]="$ftp_1"
    ftp_map["${accession}_2"]="$ftp_2"
# change the md5 file here 
done < <(tail -n +2 alouatta-file-report-md5.tsv)

# Step 2: Process each accession
for accession in "${!species_map[@]}"; do
    species="${species_map[$accession]}"
    
    for read_num in 1 2; do
        key="${accession}_${read_num}"
        ftp_url="${ftp_map[$key]}"
        expected_md5="${md5_map[$key]}"
        new_filename="${species}_${accession}_${read_num}.fastq.gz"

        if [ -z "$ftp_url" ]; then
            echo "⚠️ No FTP URL found for $key"
            continue
        fi
# change the download script .sh file here
        # Check if download script exists and contains this URL
        if grep -q "$ftp_url" ena-file-download-selected-files-20250627-1707.sh; then
            echo "Found URL in download script: $ftp_url"
        else
            echo "⚠️ URL not found in download script: $ftp_url"
        fi

        # Download the file
        echo "Downloading: $new_filename"
        echo "From URL: $ftp_url"
        wget -nv -nc -O "$new_filename" "$ftp_url"

        # Verify MD5 checksum
        if [ -n "$expected_md5" ]; then
            actual_md5=$(md5sum "$new_filename" | awk '{print $1}')
            if [ "$expected_md5" == "$actual_md5" ]; then
                echo "  ✅ MD5 verified: $new_filename"
            else
                echo "  ❌ MD5 MISMATCH: $new_filename"
                echo "     Expected: $expected_md5"
                echo "     Actual:   $actual_md5"
                echo "     Deleting corrupted file..."
                rm -f "$new_filename"
            fi
        else
            echo "  ⚠️ No MD5 checksum found in metadata for $new_filename"
        fi
    done
done

echo "All downloads completed!"
