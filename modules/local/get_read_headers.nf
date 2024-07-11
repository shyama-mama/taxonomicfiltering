process GET_READ_HEADERS {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::gawk=5.3.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.0' :
        'biocontainers/gawk:5.3.0' }"

    input:
    tuple val(meta), path(kraken_classification)
    path taxon_list
    val include_unclassified

    output:
    tuple val(meta), path('*reads.list')    , emit: taxid_list
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/taxonomicfiltering/bin/
    def include_unclass_command = include_unclassified ? "grep ^U ${kraken_classification} | awk '{print \$2;}' >> ${meta.id}.filtered_reads.list" : ""
    """
    awk 'BEGIN {FS="\\t"} NR==FNR {subset[\$1]; next} \$3 in subset {print \$2}' ${taxon_list} ${kraken_classification} > ${meta.id}.filtered_reads.list
    $include_unclass_command 
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | sed 's/GNU Awk //' | cut -d, -f1 | head -n1 )
    END_VERSIONS
    """
}
