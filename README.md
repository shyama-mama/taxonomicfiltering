# taxonomicfiltering

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

## Usage


First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,NA
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

Now, you can run the pipeline using:

```bash
nextflow run nf-core/taxonomicfiltering \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --database <path to database> \
   --ncbi_fullnames <path to ncbi fullnames.dmp file> \
   --taxon_name < Name of taxon same as in fullnames.dmp at order level to filter by, eg. Primates" \
   --filtering_mode <"positive" or "negative", determines if unclassified reads are removed or kept> \
   --outdir <OUTDIR>
```

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
