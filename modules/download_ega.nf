process GET_IDS {
    executor 'local'
    maxForks params.parallel_downloads
    conda "$baseDir/envs/default.yml"
    publishDir "${params.out_dir}", mode: params.publish_dir_mode

    input:
    val egad_identifier 

    output:
    file "egaf_list.txt" 

    script:
    // Added command to download publicly available datasets without egaCredFile
    def pyega_opts = params.egaCredFile ? '-cf ' + params.egaCredFile : "-t"

    """
    pyega3 $pyega_opts files $egad_identifier 2>&1 | grep -o \"EGAF[0-9]\\+\" > egaf_list.txt
    """
}

process DOWNLOAD_FASTQ {
    tag "$egaf_identifier"
    executor 'local'
    maxForks params.parallel_downloads
    conda "$baseDir/envs/default.yml"
    errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }
    publishDir "${params.out_dir}", mode: params.publish_dir_mode

    input:
    val egaf_identifier 

    output:
    //file "**/*.{f*q.gz,bam}" // To avoid error when no fastq or bam files are downloaded
    file "**/*" 

    script:
    // Added command to download publicly available datasets without egaCredFile
    script:
    def pyega_opts = params.egaCredFile ? '-cf ' + params.egaCredFile : "-t" 

    """
    pyega3 $pyega_opts -c ${params.downloadConnections} fetch $egaf_identifier
    """
}