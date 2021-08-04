#!/bin/bash
# Trimming
#SBATCH -J Trim_06Nov20.%j
#SBATCH -p All # la partition
#SBATCH -n 8 # nombre de processeurs
#SBATCH -N 1 # nombre de noeuds, DO NOT CHANGE THIS SETTING
#SBATCH --mem 30000 # mémoire (en MB)
#SBATCH --array=0-8
#SBATCH -o /K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/slurm/Trim_06Nov20.%j.o
#SBATCH -e /K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/slurm/Trim_06Nov20.%j.e
#SBATCH --mail-type=END # notification par e-mail à la fin en cas de réussite ou erreur
#SBATCH --mail-user=sanchari.sircar@u-psud.fr # l’adresse e-mail
##

set -e

export NB_CORE=$SLURM_CPUS_ON_NODE # nb de processeurs alloués sur le noeud (spécifié par le permettre -n)
export OMP_NUM_THREADS=$NB_CORE  # limite du nombre thread à l'exécution
export OMP_THREAD_LIMIT=$NB_CORE # limite du nombre de thread pour l'ensemble du programme



for file in /K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/rawdata/*gz; do echo -e "$file\t/K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/Trimming/trim_`basename $file`" > /K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/trim_paths/trim_path_`basename $file .fastq.gz`; done


mytrimFiles=($(echo /K/CHROCYC/Deep-sequencing_Raw_Data/RNAseq_Cecile_sup_fevrier_2020/trim_paths/* ))
trimFile=${mytrimFiles[$SLURM_ARRAY_TASK_ID]}

pathToTrimmoTool="/opt/share/trimmomatic/Trimmomatic-0.38/trimmomatic-0.38.jar"
typeAnalyse=SE
pathToTrimmoParam=$trimFile #Path to the dataframe containning the input paths and output names that you give as entry
adapters="/opt/share/trimmomatic/Trimmomatic-0.38/adapters/TruSeq3-SE.fa"


echo "Order of the parameters:
trimmomatic.VERSION.jar path, type of analysis (SE for Single End, PE for Pair End), trimmomatic parameters dataframe path, adapters paths and output folder"


IFS=$'\n'
if [ "$typeAnalyse" = "PE" ]; then
	for pathToTrimmoParam in $trimFile; do
		for currentTrimmoParam in $(cat $pathToTrimmoParam); do
			input1=$(echo $currentTrimmoParam |cut -f1)
			input2=$(echo $currentTrimmoParam |cut -f2)
			output1Paired=$(echo $currentTrimmoParam |cut -f3)
			output1Unpaired=$(echo $currentTrimmoParam |cut -f4)
			output2Paired=$(echo $currentTrimmoParam |cut -f5)
			output2Unpaired=$(echo $currentTrimmoParam |cut -f6)

			mkdir -p $(dirname $output1Paired)
			mkdir -p $(dirname $output2Paired)
			mkdir -p $(dirname $output1Unpaired)
			mkdir -p $(dirname $output2Unpaired)

			cmd="java -jar $pathToTrimmoTool PE -threads $NB_CORE $input1 $input2 $output1Paired $output1Unpaired $output2Paired $output2Unpaired ILLUMINACLIP:$adapters:2:30:10 LEADING:5 TRAILING:5 MINLEN:30"
			echo $currentTrimmoParam

			echo "Launching cmd : $cmd"
			eval $cmd
		done
	done

elif [ "$typeAnalyse" = "SE" ]; then
	for pathToTrimmoParam in $trimFile; do
		echo $pathToTrimmoParam
		for currentTrimmoParam in $(cat $pathToTrimmoParam); do
			echo $currentTrimmoParam
			input=$(echo $currentTrimmoParam | cut -f1)
			output=$(echo $currentTrimmoParam | cut -f2)
			mkdir -p $(dirname $output)
			echo $input
			echo $output

			cmd="java -jar $pathToTrimmoTool SE -threads $NB_CORE $input $output ILLUMINACLIP:$adapters:2:30:10 LEADING:5 TRAILING:5 MINLEN:30"

			echo "Launching cmd : $cmd"
			eval $cmd
		done
	done

else
	echo "The second argument should be SE for Single End analysis or PE for Pair End"
fi
