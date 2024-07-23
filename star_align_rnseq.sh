#!/bin/bash

source "${HOME}/miniconda3/etc/profile.d/conda.sh"

function gen_index() {
	local genome_path="$1"
	local gtf_path="$2"
	local index_path="$3"
	STAR \
	--runThreadN 6 \
	--runMode genomeGenerate \
	--genomeDir "$index_path" \
	--genomeFastaFiles "$genome_path" \
	--sjdbGTFfile "$gtf_path"
}

function align_fq() {
	local star_index="$1"
	local fq="$2"
	local fq_base="$(basename "$fq" .fastq.gz | sed 's/_trimmed_R1//g')"
	echo "Aligning ${fq_base}"
	STAR \
	--runThreadN 14 \
	--genomeDir "$star_index" \
	--readFilesIn "${fq_base}_trimmed_R1.fastq.gz" "${fq_base}_trimmed_R2.fastq.gz" \
	--readFilesCommand zcat \
	--outSAMtype BAM SortedByCoordinate \
	--outTmpDir "${HOME}/star_temp_dir/" \
	--outFileNamePrefix "${fq_base}_" 
}

genome="${HOME}/genome/gencode_GRCm39/GRCm39.primary_assembly.genome.fa"
g_index="${HOME}/genome/gencode_GRCm39/star_index/"
gtf="${HOME}/genome/gencode_GRCm39/gencode.vM35.primary_assembly.annotation.gtf"
fq_dir="$1"

export gen_index
export align_fq

# Activate environment
conda activate rnaseq_env

# Generate genome index
gen_index "$genome" "$gtf" "$g_index"

# Align paired-end reads
cd "$fq_dir" || echo 'FastQ directory is not valid!'
for fqs in *fastq.gz;
do
	align_fq "$g_index" "$fqs"
done

# Deactivate environment
conda deactivate

exit
