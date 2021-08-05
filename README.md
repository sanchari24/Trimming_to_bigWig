# Trimming_to_bigWig
The scripts can be used for RNA-seq, ATAC-seq and ChIP-seq data for trimming, mapping and producing bigWigs

For trimmomatic_generic.sbatch: 
First generate the trim_paths folder having the path of rawdata and trimmed data
Specify single end or double end.

For mapping_script.sbatch:

Give the path to the trim folders. It will sort, mark duplicates and generate MAPQ30 filtered bam files. Remember to delete/archive intermediate bam files. The script will then generate MAPQ30 bigwigs which can be further used for downstreame analysis
