process GET_TAXON_LIST {
    tag "$scientific_name"
    label 'process_single'

    conda "conda-forge::gawk=5.3.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.0' :
        'biocontainers/gawk:5.3.0' }"

    input:
    path ncbi_fullnames
    val scientific_name

    output:
    path '*.txt'       , emit: taxid_list
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline, in nf-core/taxonomicfiltering/bin/
    """
    grep -e "; $scientific_name;" -e "|\s$scientific_name\s|" $ncbi_fullnames | awk '{print \$1;}' | sort | uniq > taxon_list_to_keep.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | sed 's/GNU Awk //' | cut -d, -f1 | head -n1 )
    END_VERSIONS
    """
}
