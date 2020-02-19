# Download files from public repositories.

USAGE:
```
# Download from EGA
./main.nf --ega --out_dir="/path/to/downloaded/fastqs" --accession="EGAD000XXXXX"

# Dwonload from SRA
./main.nf --sra --out_dir="results" --accession_list="SRA_Acc_List.txt"

# Download from a plain list of ftp/http links
./main.nf --wget --out_dir="results" --accession_list="urls.txt"
```

## SRA


## EGA

## Store ega credenctials
First, store your credentials in ~/.ega.json:

```
{
  "username": "my.email@university.edu",
   "password": "SuperSecurePasswordIncludes123",
}
```

## Usage

```
./main.nf --outputDir=/dir/where/fastqs/will/be/stored --datasetID EGAD000XXXXXX
```

You can adjust additional parameters in `nextflow.config`.
