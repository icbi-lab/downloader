# nf-downloader: Download files from public repositories.

```
Usage:
    # Download from EGA
    ./main.nf --ega --out_dir="/path/to/downloaded/fastqs" --accession="EGAD000XXXXX"

    # Dwonload from SRA
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


    Download-modes:
    --ega                       EGA archive
    --wget                      Just download a plain list of ftp/http links
    --sra                       Download from SRA
    --gdc                       Download from GDC portal 
```

## Setup credentials for EGA download

Store your credentials in `~/.ega.json`:

```
{
  "username": "my.email@university.edu",
   "password": "SuperSecurePasswordIncludes123",
}
```
