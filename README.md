# nf-downloader: Download files from public repositories.

```
Usage:
    # Download from EGA
    ./main.nf --ega --out_dir="/path/to/downloaded/fastqs" --accession="EGAD000XXXXX"

    # Download from a plain list of ascp links
    # Automatically converts EBI ftp links into ascp links.
    ./main.nf --ascp --out_dir="/path/to/downloaded/fastqs" --accession_list="urls.txt"

    # Download from SRA
    ./main.nf --sra --out_dir="results" --accession_list="SRA_Acc_List.txt"

    # Download from a plain list of ftp/http links
    ./main.nf --wget --out_dir="results" --accession_list="urls.txt"

    # Download open file from GDC
    ./main.nf --gdc --out_dir="results" --gdc_file_id 57c425f6-9625-407e-93b8-1d03858fd1f6

    # Download multiple open files from GDC
    ./main.nf --gdc --out_dir="results" \
        --gdc_file_id 57c425f6-9625-407e-93b8-1d03858fd1f6,00cdff29-697a-4a17-ba67-cf55c006b827
    or
    ./main.nf --gdc --out_dir="results" --gdc_file_id myGDCFileIds.txt

    # Download multiple open files from GDC using a manifest file
    ./main.nf --gdc --out_dir="results" --gdc_manifest manifest.txt

    # Download protected files from GDC
    [same as above but] --gdc_token myGDCtokenFile.txt

    # Download BAM slices from GDC
    ./main.nf --gdc --out_dir="results" \
        --gdc_bamslice chr1,chr2:1000000-2000000 \
        --gdc_file_id 5fd00a1f-e6cf-4d32-885b-a5a6939aedb1 \
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
                                        chr1,chr2:1000000-2000000,unmapped,[...]
                                    or
                                    - single gene or comma separated list of genes, e.g.:
                                        BRC1,TP53,[...]
                                    or
                                    - file containing regions, one file per line
                                    or
                                    - file containing genes, one file per line
    --gdc_fastq                 convert BAM files to fastq (default false)
    --gdc_token                 GDC access token file for protected data
    --ascp_private_key_file     Path to the aspera private key file. Defaults
                                to \$(dirname \$(readlink -f \$(which ascp)))/../etc/asperaweb_id_dsa.openssh
    --ascp_params               Parameters for aspera download, Default "-QT -l 1000m -P33001"


    Download-modes:
    --ega                       EGA archive
    --wget                      Just download a plain list of ftp/http links
    --sra                       Download from SRA
    --gdc                       Download from GDC portal
    --ascp                      Download aspera connect links
```

## SRA
Hint: to get faster, more reliable download links for SRA identifiers
use [SRA Explorer](https://sra-explorer.info/).

## Setup credentials for EGA download

Store your credentials in `~/.ega.json`:

```
{
  "username": "my.email@university.edu",
   "password": "SuperSecurePasswordIncludes123",
}
```

## GDC
A authentication token file is required to download protected data from GDC.
Users with access to protected data may download a token file from https://portal.gdc.cancer.gov/
when logged in.

