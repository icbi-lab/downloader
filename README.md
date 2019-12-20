# ega_downloader

Download Smartseq2 data from EGA with nextflow.

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
