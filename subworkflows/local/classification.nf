//
// Classify reads with database
//

include { KRAKEN2_KRAKEN2 } from '../../modules/nf-core/kraken2/kraken2/main' 

workflow CLASSIFICATION {
    take:
    reads       // [ [meta], [read1, reads2] ] or [ [meta], [read1] ]
    database    // file: /path/to/database

    main:
    ch_versions                 = Channel.empty()
    ch_multiqc_files            = Channel.empty()

    KRAKEN2_KRAKEN2 ( reads, database, false, true ) // read, database, save_output_fastqs, save_reads_assignment 
    ch_versions                 = ch_versions.mix ( KRAKEN2_KRAKEN2.out.versions.first() )
    ch_multiqc_files            = ch_multiqc_files.mix( KRAKEN2_KRAKEN2.out.report )

    emit:
    taxonomic_classification    = KRAKEN2_KRAKEN2.out.classified_reads_assignment   // [ [ meta ], classified_reads_assignment ]
    mqc                         = ch_multiqc_files
    versions                    = ch_versions
}

