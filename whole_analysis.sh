#!/bin/bash

#mkdir files
#curl ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr22.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz -o files/chr22.vcf.gz
#curl ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel -o files/panel.txt
grep TSI files/panel.txt | cut -f 1 > files/TSI_individuals.txt

mkdir plink_outputs
../software/plink2 --make-bed --vcf files/chr22.vcf.gz --keep files/TSI_individuals.txt --set-all-var-ids @:#\$r-\$a --rm-dup --geno --mind --indep-pairwise 50 10 0.5 --snps-only just-acgt --max-alleles 2 --out plink_outputs/filter

../software/plink2 --make-bed --bfile plink_outputs/filter --exclude plink_outputs/filter.prune.out --out plink_outputs/filtered #--exclude: 124092 variants remaining.

mkdir individuals
mkdir individuals/temp_files
while IFS= read -r sample
do 
	tmp=$(mktemp)
	echo $sample | cut -d" " -f 2 > "$tmp"
	message=$(cat "$tmp")
	mkdir individuals/$message
	echo $sample > individuals/temp_files/$message.txt
	../software/plink --bfile plink_outputs/filtered --keep individuals/temp_files/$message.txt --recode 23 --out individuals/$message/$message
	rm individuals/$message/$message.nosex
	sed 's/\t/,/g' individuals/$message/$message.txt > individuals/$message/$message.csv
	sed -i 1,8d individuals/$message/$message.csv
	sed -i 's/.\{2\}//' individuals/$message/$message.csv
	gzip individuals/$message/$message.csv
	rm individuals/$message/$message.txt
	rm individuals/temp_files/$message.txt
	rm $tmp
done < plink_outputs/filtered.fam

../software/plink2 --bfile plink_outputs/filtered --recode ped --out plink_outputs/filtered_conv

rmdir individuals/temp_files
rm files/chr22.vcf.gz
rm files/panel.txt
rm files/TSI_individuals.txt
rmdir files
rm plink_outputs/filter.bed
rm plink_outputs/filter.fam
rm plink_outputs/filter.bim
