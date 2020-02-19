# nf-downloader: Download files from public repositories.

```
Usage:
  # Download from EGA
  ./main.nf --ega --out_dir="/path/to/downloaded/fastqs" --accession="EGAD000XXXXX"

  # Dwonload from SRA
  ./main.nf --sra --out_dir="results" --accession_list="SRA_Acc_List.txt"

  # Download from a plain list of ftp/http links
  ./main.nf --wget --out_dir="results" --accession_list="urls.txt"

Options: 
  --out_dir                   Path where the FASTQ files will be stored. 
  --accession_list            List of accession numbers (of files)/download links. One file per line. 
  --accession                 Accession number (of a dataset) to download. 
  --parallel_downloads        Number of parallel download slots (default 16). 

Download-modes:
  --ega                       EGA archive
  --wget                      Just download a plain list of ftp/http links
  --sra                       Download from SRA
```

## Setup credentials for EGA download

Store your credentials in `~/.ega.json`:

```
{
  "username": "my.email@university.edu",
   "password": "SuperSecurePasswordIncludes123",
}
```
