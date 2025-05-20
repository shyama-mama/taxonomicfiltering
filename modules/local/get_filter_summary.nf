process GET_FILTER_SUMMARY {
    label 'process_single'

    conda "conda-forge::gawk=5.3.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.0' :
        'biocontainers/gawk:5.3.0' }"

    input:
    path files

    output:
    path "summary.csv"                          , emit: filter_summary
    path "*_mqc.yml"                            , emit: filtering_summary_mqc
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: 
    """
    echo "sample,total_reads,reads_retained,reads_filtered"                             > summary.csv

    echo "id: filtering_summary"                                                        > filtering_summary_mqc.yml
    echo "section_name: \\"Kraken2 Filtering Summary\\""                                >> filtering_summary_mqc.yml
    echo "description: \\"Number of reads retained and filtered reads per sample\\""    >> filtering_summary_mqc.yml
    echo "plot_type: generalstats"                                                      >> filtering_summary_mqc.yml
    echo "pconfig:"                                                                     >> filtering_summary_mqc.yml
    echo "  total_reads:"                                                               >> filtering_summary_mqc.yml
    echo "    title: \\"Total Reads\\""                                                 >> filtering_summary_mqc.yml
    echo "  reads_retained:"                                                            >> filtering_summary_mqc.yml
    echo "    title: \\"Reads Retained\\""                                              >> filtering_summary_mqc.yml
    echo "  reads_filtered:"                                                            >> filtering_summary_mqc.yml
    echo "    title: \\"Reads Filtered\\""                                              >> filtering_summary_mqc.yml
    echo "data:"                                                                        >> filtering_summary_mqc.yml

    echo "id: filtering_plot"                                                           >  filtering_plot_mqc.yml
    echo "section_name: \\"Kraken2 Filtering\\""                                        >> filtering_plot_mqc.yml
    echo "description: \\"Number of reads retained and filtered reads per sample\\""    >> filtering_plot_mqc.yml
    echo "plot_type: bargraph"                                                          >> filtering_plot_mqc.yml
    echo "pconfig:"                                                                     >> filtering_plot_mqc.yml
    echo "  ylab: \\"Number of reads\\""                                                >> filtering_plot_mqc.yml
    echo "  reads_retained:"                                                            >> filtering_plot_mqc.yml
    echo "    name: \\"Reads Retained\\""                                              >> filtering_plot_mqc.yml
    echo "  reads_filtered:"                                                            >> filtering_plot_mqc.yml
    echo "    name: \\"Reads Filtered\\""                                              >> filtering_plot_mqc.yml
    echo "data:"                                                                        >> filtering_plot_mqc.yml

    for sample in \$(ls *.kraken2.classifiedreads.txt | sed 's/.kraken2.classifiedreads.txt//'); do
        classified_count=\$(cat "\${sample}.kraken2.classifiedreads.txt" | wc -l)
        retained_count=\$(cat "\${sample}.filtered_reads.list" | wc -l)
        filtered_count=\$((classified_count - retained_count))
        
        echo "\${sample},\${classified_count},\${retained_count},\${filtered_count}"    >> summary.csv
        
        echo "  \${sample}:"                                                            >> filtering_summary_mqc.yml
        echo "    total_reads: \${classified_count}"                                    >> filtering_summary_mqc.yml
        echo "    reads_retained: \${retained_count}"                                   >> filtering_summary_mqc.yml
        echo "    reads_filtered: \${filtered_count}"                                   >> filtering_summary_mqc.yml

        echo "  \${sample}:"                                                            >> filtering_plot_mqc.yml
        echo "    reads_retained: \${retained_count}"                                   >> filtering_plot_mqc.yml
        echo "    reads_filtered: \${filtered_count}"                                   >> filtering_plot_mqc.yml
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(awk --version | sed 's/GNU Awk //' | cut -d, -f1 | head -n1 )
    END_VERSIONS
    """
}
