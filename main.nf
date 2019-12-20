#!/usr/bin/env nextflow

process get_ids {
    conda "envs/pyega.yml"
    publishDir "${params.outputDir}", mode: params.publishDirMode
    input:
        val egad_identifier from Channel.value(params.datasetId)
    output:
        file "egaf_list.txt" into egaf_list

    """
    pyega3 -cf ${params.egaCredFile} files $egad_identifier | grep "^EGAF" | cut -f 1 -d" " > egaf_list.txt
    """
}

process download_fastq {
    conda "envs/pyega.yml"
    errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }
    publishDir "${params.outputDir}", mode: params.publishDirMode

    input:
        each egaf_identifier from egaf_list.readLines()

    output:
        file "**/*.f*q.gz" into fastqs

    """
    pyega3 -cf ${params.egaCredFile} -c ${params.downloadConnections} fetch $egaf_identifier
    """
}
