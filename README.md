# taxonomicfiltering
### NOTE: The pipeline is built using nf-core but it is not part of nf-core. 
#### A similar nf-core pipeline called [detaxizer](https://nf-co.re/detaxizer) exists. Eventually, this will be merged into detaxizer. 

## Introduction

Ancient DNA from archeological remains such as bones are a complex mixture of DNA endogenous to the material and sequences from taxa found in the environment (modern human, microbes, etc.). This is a pipeline to filter sequences based on [Kraken2](https://github.com/DerrickWood/kraken2), a metagenomic classifier, to separate endogenous and non-endogenous taxa from pre-processed sequence data (adapters trimmed and/or pair-end reads collapsed)

![TaxonomicFiltering (1)](https://github.com/user-attachments/assets/72a27a89-abf8-475d-8ca2-5f0994cfb1c1)

Briefly, the pipeline runs FastQC on the input data. [Kraken2](https://github.com/DerrickWood/kraken2) is used to classify the reads with a user specified database. The classification is used to filter reads based on user inputs (e.g extract reads that are classified at the order level 'Primate').

1. Run QC on input reads ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
3. Run taxonomic classification on input reads ([`Kraken2`](https://github.com/DerrickWood/kraken2))
4. Parse taxonomic IDs from fullnames.dmp file (get_ncbi_taxon_list)
5. Use taxonomic classification and taxids to get list to reads to retain
6. Run Seqtk subseq to filter input reads ([`Seqtk`](https://github.com/lh3/seqtk))
7. Present QC and Classification summary for reads ([`MultiQC`](http://multiqc.info/))

## Setup and Example Run
Assuming you already have nextflow [installed](https://www.nextflow.io/docs/latest/install.html).
```bash
# Clone Repo
git clone https://github.com/shyama-mama/taxonomicfiltering.git

# Download Sample Kraken2 Database and extract 
wget 'https://github.com/nf-core/test-datasets/raw/eager/databases/kraken/eager_test.tar.gz' && \
   tar -xvf eager_test.tar.gz

# Download NCBI taxonomy names list
wget 'https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.zip'
mkdir -p ncbi_files && unzip new_taxdump.zip -d ncbi_files

# Run test pipline
# Choose one of singularity, docker or conda depending on what environment you have.
# The pipeline below classifies the input reads using Kraken2.
# The database used here is a simple database containing mammoth, human and boa constrictor sequences.
# We are performing "positive" filtering where only sequences classified as "Proboscidea" are kept. (See Usage for more details)
# "Proboscidea" is the order containing mammoths. 
nextflow run ./taxonomicfiltering/ -profile test,{singularity,docker,conda} \
   --outdir test --ncbi_fullnames ./ncbi_files/fullnamelineage.dmp \
   --input ./taxonomicfiltering/data/samplesheet.csv --database ./eager_test/ \
   --filtering_mode positive --taxon_name "Proboscidea"
```
Example output is in `data/multiqc_report.html`

## Usage

### Input File 
The samplesheet with your input data that looks as follows:
```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
CONTROL_REP1,AEG588A1_S1_L002_001.fastq.gz,
```
Each row represents a fastq file (single-end) or a pair of fastq files (paired end). 
The pipeline requires that all FASTQ file names are unique. 

### Pipeline options
- `--input`: Path to input text/csv file. 
- `--database`: Path to Kraken2 database (See 'Database and Filtering Method' for type of database to use)
- `--ncbi_fullnames`: Path to NCBI fullnamelineage.dmp file. Can be downloaded from [here](https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/new_taxdump/). 
- `--taxon_name`: Scientic taxonomy name as appearing in fullnamelineage.dmp to filter reads by. For example, "Primates" to retain reads classified at order Primates or above. Generally, the order level for a species is a good choice. If you want to differentiate sequences at higher resolution then family, genus or species name can be used.   
- `--filtering_mode`: One of "positive" or "negative" filtering. More details can be found in 'Database and Filtering Method' section. 

### Output
The output dir has the following folder structure.
```
output/
├─ fastqc/
│  ├─ *_fastqc.html
│  ├─ *_fastqc.zip
├─ kraken2/
│  ├─ *.kraken2.report.txt
│  ├─ *.kraken2.classifiedreads.txt
├─ get/
│  ├─ *.filtered_reads.list
├─ seqtk/
│  ├─ *_taxa_${taxon_name}_mode_${filtering_mode}_filtered.fq.gz
├─ multiqc/
│  ├─ multiqc_report.html
```
- `fastqc` contains FastQC results for each FASTQ in the input file
- `kraken2` for each row in input file 
  - `.kraken2.report.txt` classification summary, and
  - `.kraken2.classifiedreads.txt` read header and Kraken2 classification
- `get` for each row in input file 
  - `.filtered_reads.list` list of read headers to keep
- `seqtk` for each FASTQ in input file
  - `*_taxa_${taxon_name}_mode_${filtering_mode}_filtered.fq.gz` the filtered FASTQ file
- `multiqc` summary of FastQC, Kraken2 classification and taxonomic filtering. 


## Database and Filtering Method
The pipeline supports two types of metagenomic filtering. While it was originally designed for ancient DNA (aDNA) studies, it can be applicable to a wide range of sequencing datasets. The types of databases and filtering strategies are described in detail in the following [manuscript](https://doi.org/10.1093/bib/bbae646). 

Below is a practical summary of the filtering options.

The main difference between "positive" and "negative" filtering is as follows:

- In "negative" filtering, the goal is to identify reads that are not from the taxon/taxa of interest.
- In "positive" filtering, the goal is to identify reads that are from the taxon/taxa of interest.

The database you build for each approach will differ based on your goal and use case.

### Negative Filtering
Remove potential contaminants while retaining reads likely from your target taxon and unclassified reads.

Requires a large database containing sequences from taxon/taxa of interest, related taxa, and as many taxa as possible that could be present in the data. For ancient DNA, this commonly includes sequences from humans, domestic animals, microbes, plants, fungi and viruses. The [standard](https://github.com/DerrickWood/kraken2/wiki/Manual) Kraken2 database is a good start to build a bigger database from. 

Once the database is built, we classify the sequence data. For example, if the sequence data is from an ancient dog specimen and the filtering threshold is set at the order level i.e Carnivora. We have three types of reads:
- reads that are classified at minimum as 'Carnivora',
- reads classified outside of 'Carnivora', and
- reads that Kraken2 could not classify (either because there was no representative sequence in the database for that taxon or in the case of ancient DNA, the read was too short to accurately classify).

With negative filtering we:

- **Remove:** reads that are outside of 'Carnivora', and
- **Retain:** reads that are at leat 'Carnivora' or reads Kraken2 could not classify. In the context of ancient DNA, we want to keep unclassified reads to minimise the loss of ancient DNA from the taxon of interest. 

### Positive Filtering
Retain reads classified as belonging to your taxon/taxa of interest.

Could use a relatively small Kraken2 database containing sequences from the taxa of interest, taxa related to it and if present population-level variation to reduce reference bias (i.e only retaining reads that look like the reference sequences in the database). 

To identify ancient dog reads, we can build a Kraken2 database with:
- Dog, wolf, fox and dingo reference genomes
- Add known SNP variation in Canids from the Dog Genomes diversity project

**Considerations for ancient DNA:**
- aDNA fragments are often very short (< 40 bp)
- Kraken2's default k-mer size is 35, which will not be able to classify short fragments.
- We can build a database with a reduced k-mer size (k-mer 29) to improve classification of shorter fragments. However, this increases false classifications
  - To minimise the effect of false classification we keep the databse focused on the taxa of interest.
- Add variation data to reduce reference bias if population genetics analysis is going to be performed on the data

### Summary

| Filtering Type | Goal | Database Type | Method |
|:---------------|:-----|:--------------|:--------|
| **Negative** | Remove not from taxa of interest | Large, broad database | Retain reads classified as target taxa group (e.g. `Carnivora`) and unclassified |
| **Positive** | Identify reads from taxa of interest | Small, focused database | Use reduced k-mer size of 29 for aDNA and add variation data |

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).

You can cite the `taxonomicfiltering` publication as follows:

> **Filtering out the noise: metagenomic classifiers optimize ancient DNA mapping.**
>
> Shyamsundar Ravishankar, Vilma Perez, Roberta Davidson, Xavier Roca-Rada, Divon Lan, Yassine Souilmi & Bastien Llamas
>
> _Briefings in Bioinformatics_ 2025 Jan. doi: [10.1093/bib/bbae646](https://doi.org/10.1093/bib/bbae646)




