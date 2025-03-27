#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Import processes
include { helpMessage } from './modules/help.nf'
include { DOWNLOAD_ASCP } from './modules/download_ascp.nf'
include { DOWNLOAD_WGET } from './modules/download_wget.nf'
include { SRA_PREFETCH } from './modules/download_sra.nf'
include { SRA_DUMP } from './modules/download_sra.nf'
include { GET_IDS } from './modules/download_ega.nf'
include { DOWNLOAD_FASTQ } from './modules/download_ega.nf'
include { GET_GDC_FILES_BYID } from './modules/download_gdc.nf'
include { GET_GDCFILES_BYMANIFEST } from './modules/download_gdc.nf'
include { GET_GDC_BAM_REGION } from './modules/download_gdc.nf'
include { GDC_BAM_TO_FASTQ } from './modules/download_gdc.nf'

// Show help message
if (params.help) {
    helpMessage()
    System.exit(0)
}

// Check accession list and accession parameters
if (params.accession_list  && params.accession) {
    error "You can only specify either of accession_list or accession"
}

workflow {
    // Run if ascp is enabled
    if (params.ascp) {
        if (params.accession) {
            error "ascp download mode only supports accession_lists"
        }
        ascp_ch = Channel.fromPath(params.accession_list).splitText()
        DOWNLOAD_ASCP(ascp_ch)
    }
    // Run if wget is enabled
    if (params.wget) {
        if(params.accession) {
            error "wget download mode only supports accession_lists"
        }
        wget_ch = Channel.fromPath(params.accession_list).splitText()
        DOWNLOAD_WGET(wget_ch)
    }
    if (params.sra) {
        if(params.accession) {
            error "sra download mode only supports accession_lists"
        }
        sra_ch = Channel.fromPath(params.accession_list).splitText()
        sra_prefetch = SRA_PREFETCH(sra_ch)
        SRA_DUMP(sra_prefetch)
    }
    if (params.ega) {
        if (params.accession) {
            ega_ch = Channel.value(params.accession)
            egaf_list = GET_IDS(ega_ch).splitText()
        } else {
            egaf_list = Channel.fromPath(params.accession_list).splitText()
        }
        DOWNLOAD_FASTQ(egaf_list)
    }
    if (params.gdc) {
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
                    .flatten()
                    .set{ gdc_uuid_list }
            }
            gdc_bam = GET_GDC_FILES_BYID(gdc_uuid_list)

        } else if (params.gdc_manifest && !params.gdc_bamslice) {
            gdc_manifest = Channel.fromPath(params.gdc_manifest)
            gdc_bam = GET_GDCFILES_BYMANIFEST(gdc_manifest)

        } else if (params.gdc_file_id && params.gdc_bamslice) {
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
                    .flatten()
                    .set{ gdc_uuid_list }
            } else {
                Channel
                    .value(params.gdc_file_id)
                    .tokenize(',')
                    .flatten()
                    .set{ gdc_uuid_list }
            }
            gdc_bam = GET_GDC_BAM_REGION(params.gdc_token, gdc_uuid_list, gdc_region_list)
        
        } else if (params.gdc_manifest && params.gdc_bamslice) {
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
            gdc_uuid_list = Channel
                                .fromPath(params.gdc_manifest)
                                .map { file -> file.text.readLines().drop(1) } 
                                .flatten()
                                .map { line -> line.tokenize('\t')[0] }  
           gdc_bam = GET_GDC_BAM_REGION(params.gdc_token, gdc_uuid_list, gdc_region_list)
        } 
        if (params.gdc_fastq) {
            GDC_BAM_TO_FASTQ(gdc_bam)
        }
    }
}
