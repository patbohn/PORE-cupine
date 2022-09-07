# Changes by me:
- removed nanopolish.rar files to reduce size (replaced nanopolish with f5c in workflow, including the optional filter signal step)
- changed script header to launch with any installed version of Rscript
- copied over the fixed for_r.cpp into the single_gene directory
- changed single_gene/Read_events.R to allow launching from other working directories (-> relative path of for_r.cpp now always same directory as script) 
- changed Read_events.R and single_gene/SVM.R to store and read RData files with saveRDS and readRDS
  - input/output files now have to be specified with full path and only a ".RData" is added during saveRDS


## possible To-Dos:
- improve SVM efficiency by training it only once and then storing it, or alternatively loading multiple samples to test at once

# Updated workflow:

1. install and compile f5c from
`git clone https://github.com/patbohn/f5c_filter_signal`
(use f5c eventalign with --filter-signal option to remove signal below 0 and above 200 before eventaligning)

2. Run PORE-cupine Read_events.R and SVM.R






# PORE-cupine
## Chemical utilized probing interrogated using nanopores (PORE-cupine)
 Detecting SHAPE modification using direct RNA sequencing

For single gene is suitable for running one gene at a time.  
For transcriptome is recommeded for running multiple genes.  
Both will yield the same results.  

### Programs needed to run the analysis:
Albacore (Oxford nanopore)  
Nanopolish (https://github.com/jts/nanopolish) a modified copy that removes the outliers from fast5 is included (nanopolish-edited.zip)   
Graphmap (https://github.com/isovic/graphmap)  
R (https://www.r-project.org/)  

### R packages required:
dplyr  
e1071  
data.table  
optparse  
Rcpp  


## Steps:

### To basecall raw fast5, output for both fast5 and fastq is required 
read_fast5_basecaller.py -i "location of fast5" -s "output_location" -r -k SQK-RNA001 -f FLO-MIN106 -o fast5,fastq --disable_filtering

### To map
cat fastq* | sed 's/U/T/g' > coverted.fastq  
graphmap align -r "reference.fa" -d coverted.fastq -o gene.sam  --double-index  
samtools view -bT "reference.fa" -F 16 gene.sam > gene.bam  
samtools sort gene.bam > gene.s.bam  
samtools index gene.s.bam  

### aligning of raw signal with nanopolish
nanopolish index -d "location of basecalled fast5" converted.fastq
### scaling of events current to the model current is required
nanopolish eventalign  --reads converted.fastq --bam gene.s.bam --genome "reference.fa" --print-read-names --scale-events > gene.event

## For single genes
### To combine mulitple events from same position and strands
./Read_events.R -f gene.event -o combined.RData

### To generate reactivity
./SVM.R -m "modified_gene.RData" -u "unmodified_gene.RData" -o "output file names.csv" -l length_of_transcipt(a number) 

## For transcriptome

### split events to individual transcript
./split_events.sh "folder to store tmp files" gene.event

### Optional step run if needed to combine tmp files from multiple flowcells
#### combined tmp files will be found in folder named combined
./combine.sh 

### To combine mulitple events from same position and strands
./loop_for_Read_files.sh "number of parts" "input folder" "output folder"

### To generate reactivity profile for mulitple transcripts
./loop_SVM.sh -s "number of parts" "RData folder containing modified samples" "RData folder containing unmodified samples" "Output folder"

## To calcuate error rates in bam files
File found in Error_rates are used to calcuate the error rates of mismatch, deletion and insertion per position.

# Acknowledgments
Li Chenhao for his help in getting me started and the calculation of error per strands (https://github.com/lch14forever)

Shen Yang for his code for aligning transcript positions to genomic position and for the TRipseq analysis (https://github.com/shenyang1981) 

Zhang Yu for the calculation of error rates.

For combining of standard deviations with mean, standard deviations and number of samples. Headrick, T. C. (2010). Statistical Simulation: Power Method Polynomials and other Transformations. Boca Raton, FL: Chapman & Hall/CRC.
