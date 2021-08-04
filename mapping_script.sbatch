#!/bin/bash
# Bowtie of RNAseq_Maher_abosog_b2tmt
#SBATCH -J Mapping_RNAseq.%j
#SBATCH -p big # la partition
#SBATCH -n 8 # nombre de processeurs
#SBATCH -N 1 # nombre de noeuds, DO NOT CHANGE THIS SETTING
#SBATCH --mem 30000 # mémoire (en MB)
#SBATCH --array=0-8
#SBATCH -o /K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/slurm/bowtie2.%j.o # la sortie standard
#SBATCH -e /K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/slurm/bowtie2.%j.e # la sortie erreur standard
#SBATCH --mail-type=END # notification par e-mail à la fin en cas de réussite ou erreur
#SBATCH --mail-user=sanchari.sircar@u-psud.fr # l’adresse e-mail
##

set -e

export NB_CORE=$SLURM_CPUS_ON_NODE # nb de processeurs alloués sur le noeud (spécifié par le parametre -n)
export OMP_NUM_THREADS=$NB_CORE  # limite du nombre thread à l'exécution
export OMP_THREAD_LIMIT=$NB_CORE # limite du nombre de thread pour l'ensemble du programme

module load deeptools/3.5.0
module load samtools/1.9
module load  bowtie2/2.3.5

FastqTrimFolders=/K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/Trimming
#Path to your FastqTrimFolders list
#fileExtens=$2 #The extension of the groupe of files to make the fastqc on it

typeAnalyse=SE #PE or SE
bowtie_index_path="/K/CHROCYC/sanchari/Arabido_Bowtie2_indexes"
bowtie_index="TAIR10.fasta"
principaloutputDir=/K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/Mapping

IFS=$'\n'

export BOWTIE2_INDEXES=$bowtie_index_path

if [ "$typeAnalyse" = "PE" ]; then
	trimFiles=($(echo $FastqTrimFolders/*/trim*R1_paired.fastq.gz ))
	f=${trimFiles[$SLURM_ARRAY_TASK_ID]}

	outputDir=$principaloutputDir/$(basename $(dirname $f))

	mkdir -p $outputDir
	bowtie_cmd="bowtie2 -x $BOWTIE2_INDEXES/$bowtie_index -p 8 --very-sensitive -1 $f -2 $currentFile/`basename $f R1_paired.fastq`R2_paired.fastq | samtools view -b - > $outputDir/`basename $f R1_paired.fastq`bowtie_res.bam"
	echo "Launching cmd : $bowtie_cmd"
	eval $bowtie_cmd


	d=$outputDir/`basename $f R1_paired.fastq.gz`bowtie_res.bam
	echo $d
	sam_cmd2="samtools sort $d -o $outputDir/sorted_`basename $d`"
	echo "Launching cmd : $sam_cmd2"
	eval $sam_cmd2

	d=$outputDir/sorted_`basename $f R1_paired.fastq.gz`bowtie_res.bam
	echo $d
	sam_cmd3="samtools index -b $d"
	echo "Launching cmd : $sam_cmd3"
	eval $sam_cmd3

	sam_cmd6="bamCoverage -bs 20 -e 150 --blackListFileName /K/CHROCYC/sanchari/arabido_annotation/excludeChrM_C.bed --smoothLength 60 --effectiveGenomeSize 110000000 --normalizeUsing RPGC -b $d -of bigwig --minMappingQuality 30 -o $(dirname $d)/RPGC_normalized_coverage_FilterMAQP30_`basename $d`.bigwig"
	echo "Launching cmd : $sam_cmd6"
	eval $sam_cmd6

	sam_cmd6="bamCoverage -bs 20 --blackListFileName /K/CHROCYC/sanchari/arabido_annotation/excludeChrM_C.bed --smoothLength 60 --effectiveGenomeSize 110000000 --normalizeUsing RPGC -b $d -of bigwig --minMappingQuality 30 -o $(dirname $d)/RPGC_normalized_coverage_FilterMAQP30_`basename $d`_noExtend.bigwig"
	echo "Launching cmd : $sam_cmd6"
	eval $sam_cmd6

	sam_cmd6="bamCoverage -bs 20 -b $d -of bigwig -o $outputDir/coverage_`basename $d`_noExtend.bigwig"
	echo "Launching cmd : $sam_cmd6"
	eval $sam_cmd6

	sam_cmd7="bamCoverage -bs 150 -b $d -of bigwig -o $outputDir/coverage_`basename $d`.bigwig"
	echo "Launching cmd : $sam_cmd6"
	eval $sam_cmd7

elif [ "$typeAnalyse" = "SE" ]; then

	trimFiles=($(echo "$FastqTrimFolders/trim*.fastq.gz" ))
	f=${trimFiles[$SLURM_ARRAY_TASK_ID]}

	echo $f

	outputDir=$principaloutputDir

	mkdir -p $outputDir
	echo $outputDir

	bowtie_cmd="bowtie2 -x $BOWTIE2_INDEXES/$bowtie_index -p 8 --very-sensitive -U $f |samtools view -bS - > $outputDir/`basename $f .fastq.gz`_bowtie_res.bam"
	echo "Launching cmd : $bowtie_cmd"
	eval $bowtie_cmd

	bowtie_cmd="bowtie2 -x $BOWTIE2_INDEXES/$bowtie_index -p 8 --very-sensitive -U $f |samtools view -bS -q 30 - > $outputDir/aboveMAPQ30_`basename $f .fastq.gz`_bowtie_res.bam"
	echo "Launching cmd : $bowtie_cmd"
	eval $bowtie_cmd

	d=$outputDir/aboveMAPQ30_`basename $f .fastq.gz`_bowtie_res.bam
	echo $d
	sam_cmd1="samtools sort -n -@ 8 $d -o $outputDir/sorted_`basename $d`"
	echo "Launching cmd : $sam_cmd1"
	eval $sam_cmd1

	sam_cmd2="samtools fixmate -m $outputDir/sorted_`basename $d` $outputDir/BestReadMark_`basename $d`"
	echo "Launching cmd : $sam_cmd2"
	eval $sam_cmd2

	sam_cmd1="samtools sort -@ 8 $outputDir/BestReadMark_`basename $d` -o $outputDir/sorted_BestReadMark_`basename $d`"
	sam_cmd2="samtools index -b $outputDir/sorted_BestReadMark_`basename $d`"
	echo "Launching cmd : $sam_cmd1"
	eval $sam_cmd1
	echo "Launching cmd : $sam_cmd2"
	eval $sam_cmd2

	sam_cmd4="samtools markdup -r $outputDir/sorted_BestReadMark_`basename $d` $outputDir/dedupPCR_`basename $d`"
	echo "Launching cmd : $sam_cmd4"
	eval $sam_cmd4


	d=$outputDir/dedupPCR*`basename $f .fastq.gz`_bowtie_res.bam

	echo $d
	sam_cmd1="samtools sort -@ 8 $d -o $outputDir/sorted_`basename $d`"
	sam_cmd2="samtools index -b $outputDir/sorted_`basename $d`"
	echo "Launching cmd : $sam_cmd1"
	eval $sam_cmd1
	echo "Launching cmd : $sam_cmd2"
	eval $sam_cmd2


	echo "Retrait des chr C et M en même tant que l'analyse BamCoverage et des reads avec une MAPQ superieur a 30"

	d=$outputDir/sorted_dedupPCR*`basename $f .fastq.gz`_bowtie_res.bam



	sam_cmd6="bamCoverage -bs 50 -e 300 --blackListFileName /K/CHROCYC/sanchari/arabido_annotation/excludeChrM_C.bed --smoothLength 150 --effectiveGenomeSize 110000000 --normalizeUsing RPGC -b $d -of bigwig --minMappingQuality 30 -o $(dirname $d)/RPGC_normalized_coverage_FilterMAQP30_`basename $d`.bigwig"
	echo "Launching cmd : $sam_cmd6"
	eval $sam_cmd6



else
	echo "The second argument should be SE for Single End analysis or PE for Pair End"

fi
