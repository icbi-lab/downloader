process DOWNLOAD_WGET {
    maxForks params.parallel_downloads
    publishDir "${params.out_dir}", mode: params.publish_dir_mode
    errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }

    input:
    val url

    output:
    file "${url.tokenize('/')[-1].trim()}"

    script:
    """
    wget "${url.strip()}"
    """
}