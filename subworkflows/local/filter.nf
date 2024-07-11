//
// Filter fastqs based on classification
//

include { GET_TAXON_LIST    } from '../../modules/local/get_taxon_list'
include { GET_READ_HEADERS  } from '../../modules/local/get_read_headers'
include { SEQTK_SUBSEQ      } from '../../modules/nf-core/seqtk/subseq/main'

workflow FILTER {
    take:
    reads                       // [ [meta], [read1, reads2] ] or [ [meta], [read1] ]
    taxonomic_classification    // [ [ meta ], classified_reads_assignment ]
    ncbi_fullnames              // file: path/to/fullnames.dmp 
    taxon_name                  // val: scientific name of taxon eg: Primates

    main:
    ch_versions = Channel.empty()

    GET_TAXON_LIST ( ncbi_fullnames, taxon_name )
    ch_versions = ch_versions.mix ( GET_TAXON_LIST.out.versions.first() )

    GET_READ_HEADERS ( taxonomic_classification, GET_TAXON_LIST.out.taxid_list, false )
    ch_versions = ch_versions.mix ( GET_READ_HEADERS.out.versions.first() )

    ch_input_for_seqtk = reads
                            .mix(GET_READ_HEADERS.out.taxid_list)
                            .groupTuple()
                            .multiMap {
                                meta, files -> 
                                    reads: [ meta, files[0] ]
                                    taxid_list: files[1]
                            }
    
    //reads.view()
    //GET_READ_HEADERS.out.taxid_list.view()

    ch_input_for_seqtk.reads.transpose().view()
    ch_input_for_seqtk.taxid_list.view()

    SEQTK_SUBSEQ ( ch_input_for_seqtk.reads.transpose(), ch_input_for_seqtk.taxid_list )
    ch_versions = ch_versions.mix ( SEQTK_SUBSEQ.out.versions.first() )

    emit:
    filtered_reads  = SEQTK_SUBSEQ.out.sequences    // [ [ meta ], sequences ]
    versions        = ch_versions
}
