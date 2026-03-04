#!/usr/bin/env python3
import os, json, sys
from collections import defaultdict

# Define all your directories
DIRS = [
    "/scratch/yutingga/eager_results/source/metagenomic_classification/kraken",
    "/scratch/yutingga/eager_results/badius_GM/metagenomic_classification/kraken", 
    "/scratch/yutingga/eager_results/badius_OM_2/metagenomic_classification/kraken",
    "/scratch/yutingga/eager_results/papio_OM/metagenomic_classification/kraken",
    "/scratch/yutingga/eager_results/gelada_OM/metagenomic_classification/kraken"
]

# File patterns to match (based on your original command)
FILE_PATTERNS = [
    "modern_human_dc_ERR3307045.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "modern_human_dc_ERR3307046.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "modern_human_dc_ERR3307047.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report", 
    "modern_human_dc_ERR3307048.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "modern_human_dc_ERR3307049.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "modern_human_dc_ERR3307050.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "modern_human_dc_ERR3307051.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "modern_human_dc_ERR3307052.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "modern_human_dc_ERR3307053.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "modern_human_dc_ERR3307054.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "skin_SRR1631060.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "skin_SRR1631061.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "skin_SRR1631063.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "skin_SRR1631064.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "skin_SRR1633008.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "skin_SRR3184100.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "Piliocolobus_badius_ERX2201547.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "Piliocolobus_badius_ERX2201549.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "Piliocolobus_badius_ERX2201550.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "Piliocolobus_badius_ERX2201551.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "badius_25451FL-01-01-17_S18_L002.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "badius_25451FL-01-01-18_S19_L002.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "badius_25451FL-01-01-20_S21_L002.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "badius_25451FL-01-01-24_S25_L002.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "badius_25451FL-01-01-25_S26_L002.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "badius_25451FL-01-01-26_S27_L002.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "FD01.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "FD14.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "FD18.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "FD03.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report",
    "FD09.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report"
]

def find_file(filename):
    """Find a file in any of the directories"""
    for d in DIRS:
        path = os.path.join(d, filename)
        if os.path.exists(path):
            return path
    return None

def parse_kraken_report(filepath):
    """Parse Kraken2 report - use CLADE reads (column 2) at GENUS level (G)"""
    counts = {}
    with open(filepath, 'r') as f:
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 8:
                tax_level = parts[5].strip()
                tax_name = parts[7].strip().lstrip()  # Remove leading spaces
                if tax_level == 'G':  # Genus level
                    # Use CLADE reads (column 2), not direct reads
                    clade_reads = int(float(parts[1].strip()))
                    if clade_reads > 0:
                        counts[tax_name] = clade_reads
    return counts

print("Processing 31 files...")
all_data = {}
all_taxa = set()

for pattern in FILE_PATTERNS:
    filepath = find_file(pattern)
    if filepath and os.path.exists(filepath):
        sample_name = pattern.replace('.unmapped.fastq.gz_lowcomplexityremoved.fq.kraken2_report', '')
        print(f"  {sample_name}")
        counts = parse_kraken_report(filepath)
        all_data[sample_name] = counts
        all_taxa.update(counts.keys())
    else:
        print(f"  WARNING: File not found: {pattern}")

print(f"\nFound {len(all_data)} samples and {len(all_taxa)} unique genera")

# Create BIOM structure
taxa = sorted(all_taxa)
samples = sorted(all_data.keys())
data = []

for i, taxon in enumerate(taxa):
    for j, sample in enumerate(samples):
        count = all_data[sample].get(taxon, 0)
        if count > 0:
            data.append([i, j, count])

biom_obj = {
    "id": "kraken2_genus_table",
    "format": "Biological Observation Matrix 1.0.0",
    "format_url": "http://biom-format.org",
    "type": "OTU table",
    "generated_by": "direct_kraken_parser",
    "date": "2024-01-01",
    "rows": [{"id": t, "metadata": None} for t in taxa],
    "columns": [{"id": s, "metadata": None} for s in samples],
    "matrix_type": "sparse",
    "matrix_element_type": "int",
    "shape": [len(taxa), len(samples)],
    "data": data
}

# Save BIOM file
output_file = "table_direct.biom"
with open(output_file, 'w') as f:
    json.dump(biom_obj, f)

print(f"\n✅ Created {output_file}")
print(f"   Samples: {len(samples)}")
print(f"   Taxa (genera): {len(taxa)}")
print(f"   Total counts: {sum(sum(c.values()) for c in all_data.values()):,}")

# Also create a TSV for verification
tsv_file = "table_direct.tsv"
with open(tsv_file, 'w') as f:
    f.write("Genus\t" + "\t".join(samples) + "\n")
    for taxon in taxa:
        row = [taxon]
        for sample in samples:
            row.append(str(all_data[sample].get(taxon, 0)))
        f.write("\t".join(row) + "\n")

print(f"   Also created {tsv_file} for verification")
