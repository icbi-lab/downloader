#!/usr/bin/env nextflow

process DOWNLOAD_ASCP {
    executor 'local'
    maxForks params.parallel_downloads
    conda "$baseDir/envs/default.yml"
    publishDir "${params.out_dir}", mode: params.publish_dir_mode
    errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }

    input:
    val url 

    output:
    file "${url.tokenize('/')[-1].trim()}"

    script:
    // automatically convert EBI ftp links into ASCP links
    url = url.replace("ftp://", "").replace("ftp.sra.ebi.ac.uk/", "era-fasp@fasp.sra.ebi.ac.uk:").strip()
    """
    ascp ${params.ascp_params} -i ${params.ascp_private_key_file} $url .
    """
}