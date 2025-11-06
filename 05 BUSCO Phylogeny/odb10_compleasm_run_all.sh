#!/bin/bash

# Directories
GENOME_DIR="/home/isessi/petrel_genome/busco_phylogeny/new_genomes"
OUTPUT_DIR="/home/isessi/petrel_genome/busco_phylogeny/odb10_compleasm_results"
LINEAGE="aves_odb10"
LIBRARY_PATH="/ccg/bin/compleasm_downloads"  # path to the BUSCO lineage
THREADS=64

# Create output folder if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through all genome files (assuming .fna or .fasta)
for genome in "$GENOME_DIR"/*.{fna,fasta}; do
    # Skip if no matching files
    [ -e "$genome" ] || continue

    # Get genome basename
    base=$(basename "$genome")
    base="${base%.*}"  # remove extension
    outdir="$OUTPUT_DIR/${base}_compleasm"

    echo "Running compleasm on $genome using $LINEAGE..."
    /ccg/bin/compleasm.sh run \
        -a "$genome" \
        -o "$outdir" \
        -l "$LINEAGE" \
        -L "$LIBRARY_PATH" \
        -t "$THREADS"
done

echo "All genomes processed. Results in $OUTPUT_DIR."
