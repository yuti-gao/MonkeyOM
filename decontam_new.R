# Created by Yuti Gao
#if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

#if (!require("decontam")) {
  BiocManager::install("decontam", force = TRUE)
}

library(decontam)
library(phyloseq)

name <- "alouatta"

# Read the feature table
df <- read.csv(paste0("decontam_feature_table_", name, ".csv"), check.names = FALSE)

# Store the original names - first column is species name, second is taxID
species_names <- df[, 1]
tax_ids <- df[, 2]

# Create matrix with taxIDs as row names
mat <- as.matrix(df[, -c(1, 2)])  # Remove species name and taxID columns
rownames(mat) <- tax_ids  # Set taxIDs as row names
mode(mat) <- "numeric"

# Read metadata
meta <- read.csv(paste0("decontam_metadata_", name, ".csv"), row.names = 1, check.names = FALSE)

# Make sure meta$is.neg is logical
meta$is.neg <- as.logical(trimws(as.character(meta$is.neg)))

# Create mapping between taxIDs and species names
taxid_to_species <- setNames(species_names, tax_ids)

# Create phyloseq object
OTU <- otu_table(mat, taxa_are_rows = TRUE)
SD <- sample_data(meta)
ps <- phyloseq(OTU, SD)

# Run decontam
libsizes <- sample_sums(ps)
summary(libsizes)

cont.prev <- isContaminant(ps, method = "prevalence", neg = "is.neg", threshold = 0.5)

table(cont.prev$contaminant)

is.contam <- cont.prev$contaminant
sum(is.contam)

# Clean data
ps.clean <- prune_taxa(!is.contam, ps)
clean_counts <- as(otu_table(ps.clean), "matrix")

# Get clean taxIDs
clean_taxids <- rownames(clean_counts)

# Create clean table with species names (no taxIDs)
clean_df <- data.frame(
  name = taxid_to_species[clean_taxids],  # Map taxIDs to species names
  clean_counts,
  row.names = NULL,
  check.names = FALSE
)

# Write clean feature table
write.csv(clean_df, paste0("decontam_feature_table_clean_", name, ".csv"), row.names = FALSE)

# Get contaminant taxIDs
contaminant_taxids <- rownames(cont.prev)[cont.prev$contaminant]

# Write contaminant taxIDs to file
writeLines(contaminant_taxids, paste0("contaminant_ids_", name, ".txt"))
