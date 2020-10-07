#!/usr/bin/env nextflow

def helpMessage() {
    log.info """
    Usage:
    # Download from EGA
    ./main.nf --ega --out_dir="/path/to/downloaded/fastqs" --accession="EGAD000XXXXX"

    # Download using Aspera connect
    ./main.nf --ascp --out_dir="/path/to/downloaded/fastqs" --accession_list="urls.txt"

    # Download from SRA
    ./main.nf --sra --out_dir="results" --accession_list="SRA_Acc_List.txt"

    # Download from a plain list of ftp/http links
    ./main.nf --wget --out_dir="results" --accession_list="urls.txt"

    # Download open file from GDC
    ./main.nf --gdc --out_dir="results" --gdc_file_id 2776a850-d9b4-4c26-8414-528458c9c7c3

    # Download multiple open files from GDC
    ./main.nf --gdc --out_dir="results" \
        --gdc_file_id 2776a850-d9b4-4c26-8414-528458c9c7c3,de9105ef-cd6c-4565-8526-568b5f55a47c
    or
    ./main.nf --gdc --out_dir="results" --gdc_file_id myGDCFileIds.txt

    # Download multiple open files from GDC using a manifest file
    ./main.nf --gdc --out_dir="results" --gdc_manifest manifest.txt

    # Download protected files from GDC
    [same as above but] --gdc_token myGDCtokenFile.txt

    # Download BAM slices from GDC
    ./main.nf --gdc --out_dir="results" \
        --gdc_bamslice chr1,chr2:1000000-2000000 \
        --gdc_file_id 82805a58-0e0c-4b29-bfae-e121236203a7 \
        --gdc_token myGDCtokenFile.txt \
        --gdc_bamslice_type region

    # mutiple region/gene or files may specified see Options below.


    Options:
    --out_dir                   Path where the FASTQ files will be stored.
    --accession_list            List of accession numbers (of files)/download links. One file per line.
    --accession                 Accession number (of a dataset) to download.
    --parallel_downloads        Number of parallel download slots (default 16).
    --gdc_file_id               GDC file uuid(s):
                                    - single uuid or comma separated list of uuids
                                    or
                                    - file containing uuids, one file per line
    --gdc_manifest              GDC portal data download manifest file obtained
                                from https://portal.gdc.cancer.gov/
    --gdc_bamslice_type         Type of BAM slice to download [region|gene] (default: region)
    --gdc_bamslice              BAM slice to download:
                                    - single region or comma separated list of regions, e.g.:
                                        chr1,chr2:1000000-2000000,[...]
                                    or
                                    - single gene or comma separated list of genes, e.g.:
                                        BRC1,TP53,[...]
                                    or
                                    - file containing regions, one file per line
                                    or
                                    - file containing genes, one file per line
    --gdc_bamslice_fastq        convert BAM slices to fastq (default false)
    --gdc_token                 GDC access token file for protected data
    --ascp_private_key_file     Path to the aspera private key file. Defaults
                                to \$(dirname \$(readlink -f \$(which ascp)))/../etc/asperaweb_id_dsa.openssh


    Download-modes:
    --ega                       EGA archive
    --wget                      Just download a plain list of ftp/http links
    --sra                       Download from SRA
    --gdc                       Download from GDC portal
    --ascp                      Download aspera connect links
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

if (params.ascp) {
    if(params.accession) {
        exit 1, "ascp download mode only supports accession_lists"
    }
    process download_ascp {
        executor 'local'
        maxForks params.parallel_downloads
        publishDir "${params.out_dir}", mode: params.publish_dir_mode
        errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }

        input:
        val url from Channel.fromPath(params.accession_list).splitText()

        output:
        file "${url.substring( url.lastIndexOf('/')+1, url.length() ).strip();}"

        script:
        // automatically convert EBI ftp links into ASCP links
        url = url.replace("ftp://", "").replace("ftp.sra.ebi.ac.uk/", "era-fasp@fasp.sra.ebi.ac.uk:").strip()
        """
        ascp -QT -l 1000m -P33001 -i ${params.ascp_private_key_file} $url .
        """
    }
}

if (params.wget) {
    if(params.accession) {
        exit 1, "wget download mode only supports accession_lists"
    }
    process download_wget {
        executor 'local'
        maxForks params.parallel_downloads
        publishDir "${params.out_dir}", mode: params.publish_dir_mode
        errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }

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
        fasterq-dump --outdir . --skip-technical --split-3 \\
            --threads ${task.cpus} \\
            ${prefetch_dir}
        pigz -p ${task.cpus} *.f*q
        """
    }
}


if(params.ega) {
    if(params.accession) {
        process get_ids {
            executor 'local'
            maxForks params.parallel_downloads

            conda "$baseDir/envs/default.yml"
            publishDir "${params.out_dir}", mode: params.publish_dir_mode

            input:
            val egad_identifier from Channel.value(params.accession)

            output:
            file "egaf_list.txt" into egaf_list

            script:
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
        conda "$baseDir/envs/default.yml"
        errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }
        publishDir "${params.out_dir}", mode: params.publish_dir_mode

        input:
        each egaf_identifier from egaf_list.readLines()

        output:
        file "**/*.f*q.gz" into fastqs

        script:
        """
        pyega3 -cf ${params.egaCredFile} -c ${params.downloadConnections} fetch $egaf_identifier
        """
    }
}

if(params.gdc) {
    if(params.gdc_file_id && !params.gdc_bamslice) {
        gdc_uuid_list_ = file(params.gdc_file_id)
        if (gdc_uuid_list_.isFile()) {
            Channel
                .fromPath(params.gdc_file_id)
                .splitText()
                .set{ gdc_uuid_list }
        } else {
            Channel
                .value(params.gdc_file_id)
                .tokenize(',')
                .set{ gdc_uuid_list }
        }

        process get_gdc_files_byID {
            executor 'local'
            maxForks params.parallel_downloads

            conda "$baseDir/envs/gdc.yml"
            publishDir "${params.out_dir}", mode: params.publish_dir_mode
            errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }

            input:
            each gdc_file_id from gdc_uuid_list

            output:
            file "**/*"

            script:
            if (params.gdc_token) {
                gdc_token = file(params.gdc_token)
            }
            if (params.gdc_token)
                """
                gdc-client download -n  ${params.downloadConnections} -t ${gdc_token} ${gdc_file_id.join(" ")}
                """
            else
                """
                gdc-client download -n  ${params.downloadConnections} ${gdc_file_id}
                """
        }
    } else if (params.gdc_manifest && !params.gdc_bamslice) {
        gdc_manifest = file(params.gdc_manifest)

        process get_gdc_files_byManifest {
            executor 'local'

            conda "$baseDir/envs/gdc.yml"
            errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }
            publishDir "${params.out_dir}", mode: params.publish_dir_mode

            input:
            file(manifest) from gdc_manifest

            output:
            file "**/*"

            script:
            if (params.gdc_token) {
                gdc_token = file(params.gdc_token)
            }
            if (params.gdc_token)
                """
                gdc-client download -n  ${params.downloadConnections} -t ${gdc_token} -m ${manifest}
                """
            else
                """
                gdc-client download -n  ${params.downloadConnections} -m ${manifest}
                """
        }
    }
    else if(params.gdc_file_id && params.gdc_bamslice) {
        gdc_region_list_ = file(params.gdc_bamslice)
        if (gdc_region_list_.isFile()) {
            Channel
                .fromPath(params.gdc_bamslice)
                .splitText()
                .set{ gdc_region_list }
        } else {
            Channel
                .value(params.gdc_bamslice)
                .tokenize(',')
                .set{ gdc_region_list }
        }
        gdc_uuid_list_ = file(params.gdc_file_id)
        if (gdc_uuid_list_.isFile()) {
            Channel
                .fromPath(params.gdc_file_id)
                .splitText()
                .set{ gdc_uuid_list }
        } else {
            Channel
                .value(params.gdc_file_id)
                .tokenize(',')
                .set{ gdc_uuid_list }
        }


        process get_gdc_bam_region {
            executor 'local'
            maxForks params.parallel_downloads

            errorStrategy { task.attempt <= 2 ? 'retry' : 'ignore' }
            publishDir "${params.out_dir}", mode: params.publish_dir_mode

            input:
            file (gdc_token) from Channel.fromPath(params.gdc_token)
            each file_uuid from gdc_uuid_list
            each slice from gdc_region_list

            output:
            file ("${file_uuid.strip()}_${slice.strip().replaceAll(/:/, "_")}.bam") into (gdc_bamslice_out)

            script:
            if(params.gdc_bamslice_type == "region")
                """
                gdc-bamslicer.py \\
                    --gdc_file_uuid ${file_uuid.strip()} \\
                    --slice_type region \\
                    --slice_req ${slice.strip()} \\
                    --outfile ${file_uuid.strip()}_${slice.strip().replaceAll(/:/, "_")}.bam \\
                    --token_file ${gdc_token}
                """
            else if(params.gdc_bamslice_type == "gene")
                """
                gdc-bamslicer.py \\
                    --gdc_file_uuid ${file_uuid.strip()} \\
                    --slice_type gene \\
                    --slice_req ${slice.strip()} \\
                    --outfile ${file_uuid.strip()}_${slice.strip().replaceAll(/:/, "_")}.bam \\
                    --token_file ${gdc_token}
                """
            else
                """
                echo "No such region type" > ${file_uuid.strip()}_${slice.strip().replaceAll(/:/, "_")}.bam
                exit(1)
                """
        }

        if(params.gdc_bamslice_fastq) {
            process gdc_bamslice_fastq {
                publishDir "${params.out_dir}", mode: params.publish_dir_mode

                input:
                file bam from gdc_bamslice_out

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
        }
    }
}

