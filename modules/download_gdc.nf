process GET_GDC_FILES_BYID {
    executor 'local'
    maxForks params.parallel_downloads

    conda "$baseDir/envs/gdc.yml"
    publishDir "${params.out_dir}", mode: params.publish_dir_mode
    errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }

    input:
    val gdc_file_id

    output:
    //file "**/*.bam" // To avoid error when no bam files are in the download IDs
    file "**/*"

    script:
    def gdc_client_opts = params.gdc_token ?  "-t " + file(params.gdc_token) : ""

    """
    gdc-client download -n  ${params.downloadConnections}  ${gdc_client_opts} ${gdc_file_id}
    """
}

process GET_GDCFILES_BYMANIFEST {
    executor 'local'
    conda "$baseDir/envs/gdc.yml"
    errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }
    publishDir "${params.out_dir}", mode: params.publish_dir_mode

    input:
    file manifest 

    output:
    //file "**/*.bam" // To avoid error when no bam files are in the download IDs
    file "**/*"

    script:
    def gdc_client_opts = params.gdc_token ?  "-t " + file(params.gdc_token) : ""
    
    """
    gdc-client download -n  ${params.downloadConnections}  ${gdc_client_opts} -m ${manifest}
    """
}

process GET_GDC_BAM_REGION {
    tag "$file_uuid"
    executor 'local'
    conda "$baseDir/envs/gdc.yml"
    maxForks params.parallel_downloads
    publishDir "${params.out_dir}", mode: params.publish_dir_mode

    errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }

    input:
    val gdc_token
    val file_uuid
    val slice

    output:
    file "*.bam"

    script:
    // Formatting slice type
    def slice_str = slice instanceof List ? slice[0] : slice
    def clean_slice = slice_str.replaceAll('[\\[\\]\\s]', '')

    // Validate the slice type
    def slice_type = params.gdc_bamslice_type in ['region', 'gene'] ? params.gdc_bamslice_type : null

    if (!slice_type) {
        error "Invalid gdc_bamslice_type: ${params.gdc_bamslice_type}. Must be 'region' or 'gene'."
    }

    """
    gdc-bamslicer.py \\
        --gdc_file_uuid ${file_uuid.trim()} \\
        --slice_type ${slice_type} \\
        --slice_req ${clean_slice} \\
        --outfile ${file_uuid.trim()}_${clean_slice.replace(':', '_')}.bam \\
        --token_file ${gdc_token}
    """
}       

process GDC_BAM_TO_FASTQ {
    executor 'local'
    conda "$baseDir/envs/gdc.yml"
    publishDir "${params.out_dir}", mode: params.publish_dir_mode

    input:
    file bam 

    output:
    file "*.f*q.gz"

    script:
    """
    samtools sort -@ ${task.cpus/2} -n $bam | \\
        samtools fastq -@ ${task.cpus/2} \\
        -0 /dev/null \\
        -1 ${bam.baseName}_R1.fastq \\
        -2 ${bam.baseName}_R2.fastq \\
        -s ${bam.baseName}_singleton.fastq \\
        -

    pigz -p ${task.cpus} *.f*q
    """
}
