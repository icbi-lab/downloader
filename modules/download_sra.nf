process SRA_PREFETCH {
    executor 'local'
    maxForks params.parallel_downloads
    // different versions have different parameters.
    // Use the conda version to make sure it's compatible
    conda "bioconda::sra-tools=3.1.0"     // Updated to available version

    input:
    val sra_acc 

    output:
    file "${sra_acc.strip()}" 

    script:
    """
    # max size: 1TB, bash correctly handles exit code 3 and ignores it
    prefetch --progress 1 --max-size 1024000000 ${sra_acc.strip()} || \\
    (exit_code=\$?; if [ \$exit_code -eq 3 ]; then echo "Exit code 3: Ignoring"; exit 0; \\
    else echo "Failure with exit code \$exit_code"; exit 1; fi)
    """

}

process SRA_DUMP {
    publishDir "${params.out_dir}", mode: params.publish_dir_mode
    // different versions have different parameters.
    // Use the conda version to make sure it's compatible
    conda "bioconda::sra-tools=3.1.0"      // Updated to available version

    input:
    file prefetch_dir 

    output:
    file "*.f*q.gz"

    script:
    """
    # fastq-dump options according to https://edwards.sdsu.edu/research/fastq-dump/
    # fasterq-dump seems to have more sensible defaults, some of the
    # options are not required any more.
    fasterq-dump --outdir . --skip-technical --split-3 \\
        --threads ${task.cpus} \\
        ${prefetch_dir}
    pigz -p ${task.cpus} *.f*q
    """
}