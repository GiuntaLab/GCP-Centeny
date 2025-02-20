#!/bin/bash

# Check if at least two arguments are provided
if [[ $# -lt 1 ]]
then
    echo "usage: bash script.sh <genome> <sequence> <output_dir>"
    exit 1
fi

# Assign the arguments to variables
genome=$1
sequence=$2
output_dir=${3:-.}  # Default to current directory if output_dir is not provided

# Ensure the output directory exists
mkdir -p "$output_dir"

# Extract base genome name
base_genome_name=$(basename "$genome" .gz)
output_base="${output_dir}/${base_genome_name}_${sequence}"

# Handle gzipped genome file
if [[ $genome == *.gz ]]
then
    echo "The file is gzipped. Decompressing to a temporary file..."
    tmp_file="$(dirname "$genome")/${base_genome_name}"
    gzip -c -d "$genome" > "$tmp_file"
    genome="$tmp_file"
    echo "Temporary file created: $tmp_file"
fi

# Run fuzznuc
echo "Running fuzznuc..."
fuzznuc --sequence "$genome" --pattern "$sequence" -complement --rformat excel -outfile "${output_base}.xlsx"

# Process output to create BED file in the specified directory
grep -v 'SeqName' "${output_base}.xlsx" | awk 'BEGIN{OFS="\t"} {print $1, $2-1, $3, $5}' > "${output_base}.bed"
echo "BED file created: ${output_base}.bed"

# Generate sequence name and length table
echo "Generating sequence name and length table..."
awk 'BEGIN {OFS="\t"} /^>/ {if (seq) print id, length(seq); id=substr($1, 2); seq=""} !/^>/ {seq = seq $0} END {if (seq) print id, length(seq)}' "$genome" > "${output_base}_length.tsv"
echo "Sequence name and length table created: ${output_base}_length.tsv"

# Clean up intermediate files
rm -f "${output_base}.xlsx"
[[ -n $tmp_file && -f $tmp_file ]] && rm -f "$tmp_file"

#echo "Script completed successfully."
