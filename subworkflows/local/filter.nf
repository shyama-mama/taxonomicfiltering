//
// Filter fastqs based on classification
//

include { GET_TAXON_LIST        } from '../../modules/local/get_taxon_list'
include { GET_READ_HEADERS      } from '../../modules/local/get_read_headers'
include { SEQTK_SUBSEQ          } from '../../modules/nf-core/seqtk/subseq/main'
include { GET_FILTER_SUMMARY    } from '../../modules/local/get_filter_summary'

workflow FILTER {
    take:
    reads                       // [ [meta], [read1, reads2] ] or [ [meta], [read1] ]
    taxonomic_classification    // [ [ meta ], classified_reads_assignment ]
    ncbi_fullnames              // file: path/to/fullnames.dmp 
    taxon_name                  // val: scientific name of taxon eg: Primates
    filtering_mode              // val: "positive" or "negative" 

    main:
    ch_versions                 = Channel.empty()

    GET_TAXON_LIST ( ncbi_fullnames, taxon_name )
    ch_versions = ch_versions.mix ( GET_TAXON_LIST.out.versions )

    if(filtering_mode == "negative") {
        GET_READ_HEADERS ( taxonomic_classification, GET_TAXON_LIST.out.taxid_list, true )
    } else {
        GET_READ_HEADERS ( taxonomic_classification, GET_TAXON_LIST.out.taxid_list, false )
    }
    
    ch_versions = ch_versions.mix ( GET_READ_HEADERS.out.versions.first() )

    ch_input_for_seqtk = reads
                            .transpose()
                            .combine(GET_READ_HEADERS.out.taxid_list, by:0)
                            .multiMap {
                                meta, read, filter_list -> 
                                    reads: [ meta, read ]
                                    taxid_list: filter_list
                            }

    SEQTK_SUBSEQ ( ch_input_for_seqtk.reads, ch_input_for_seqtk.taxid_list )
    ch_versions = ch_versions.mix ( SEQTK_SUBSEQ.out.versions.first() )
    
    GET_FILTER_SUMMARY(ch_input_for_seqtk.taxid_list.unique().mix(taxonomic_classification.map{ meta, classification -> classification}).collect())

    emit:
    filtered_reads          = SEQTK_SUBSEQ.out.sequences
    mqc                     = GET_FILTER_SUMMARY.out.filtering_summary_mqc
    versions                = ch_versions
}
