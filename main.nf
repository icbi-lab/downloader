#!/usr/bin/env nextflow

def helpMessage() {
    log.info """
    Usage:
    ./main.nf --ega --out_dir="/path/to/downloaded/fastqs" --accession="EGAD000XXXXX"

    --accession_list            List of accession numbers (of files)/download links. One file per line. 
    --accession                 Accession number (of a dataset) to download. 
    --parallel_downloads        Number of parallel download slots (default 16). 

    Download-modes:
    --ega                       EGA archive
    --wget                      Just download a plain list of ftp/http links
    --sra                       Download from SRA

    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

if (params.accession_list  && params.accession) {
    exit 1, "You can only specify either of accession_list or accession"
}


if (params.wget) {
    if(params.accession) {
        exit 1, "wget download mode only supports accession_lists"
    }
    process download_wget {
        executor 'local'
        maxForks params.parallel_downloads
        publishDir "${params.out_dir}", mode: params.publish_dir_mode

        input:
            val url from Channel.fromPath(params.accession_list).splitText()
        output:
            file "${url.substring( url.lastIndexOf('/')+1, url.length() ).strip();}"

        script:
        """
        wget $url
        """
        
    }
}

if (params.sra) {
    if(params.accession) {
        exit 1, "sra download mode only supports accession_lists"
    }
    process sra_prefetch {
        executor 'local'
        maxForks params.parallel_downloads

        input:
            val sra_acc from Channel.fromPath(params.accession_list).splitText()
        output:
            file "${sra_acc.strip()}" into sra_prefetch

        script:
        """
        # max size: 1TB
        prefetch --progress 1 --max-size 1024000000 ${sra_acc.strip()}
        """       
    } 

    process sra_dump {
        publishDir "${params.out_dir}", mode: params.publish_dir_mode
        input:
            file prefetch_dir from sra_prefetch
        
        output:
            file "*.f*q.gz"
        
        script:
        """
        # fastq-dump options according to https://edwards.sdsu.edu/research/fastq-dump/
        # fasterq-dump seems to have more sensible defaults, some of the 
        # options are not required any more. 
        fasterq-dump --outdir . --skip-technical --split-3 \
            --threads ${task.cpus} \
            ${prefetch_dir}
        gzip *.f*q
        """
    }
}


if(params.ega) {
    if(params.accession) {
        process get_ids {
            executor 'local'
            maxForks params.parallel_downloads

            conda "envs/pyega.yml"
            publishDir "${params.out_dir}", mode: params.publish_dir_mode
            input:
                val egad_identifier from Channel.value(params.accession)
            output:
                file "egaf_list.txt" into egaf_list

            """
            pyega3 -cf ${params.egaCredFile} files $egad_identifier | grep "^EGAF" | cut -f 1 -d" " > egaf_list.txt
            """
        }
    } else {
        egaf_list = file(params.accession_list)
    }

    process download_fastq {
        executor 'local'
        maxForks params.parallel_downloads
        conda "envs/pyega.yml"
        errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }
        publishDir "${params.out_dir}", mode: params.publish_dir_mode

        input:
            each egaf_identifier from egaf_list.readLines()

        output:
            file "**/*.f*q.gz" into fastqs

        """
        pyega3 -cf ${params.egaCredFile} -c ${params.downloadConnections} fetch $egaf_identifier
        """
    }
}

