# nf-fastqc


## Usage

### Single-end data

```bash
nextflow run bioinfo-tsukuba/nf-fastqc -profile <docker/singularity> --reads '*.fastq.gz' --single_end
```

### Paired-end data

```bash
nextflow run bioinfo-tsukuba/nf-fastqc -profile <docker/singularity> --reads '*_R{1,2}.fastq.gz'
```

## Test


*1.* Example of test using Docker

```bash
nextflow run bioinfo-tsukuba/nf-fastqc -profile test,docker
```

*2.* Example of test using Singularity

```bash
nextflow run bioinfo-tsukuba/nf-fastqc -profile test,singularity
```


## Quick Start

i. Install [`nextflow`](https://nf-co.re/usage/installation)

ii. Install either [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility (see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles)). Note that nf-fastqc does not support conda.

iii. Download the pipeline automatically and test it on a minimal dataset with a single command

*1.* Example of test using Docker

```bash
nextflow run bioinfo-tsukuba/nf-fastqc -profile test,docker
```

*2.* Example of test using Singularity

```bash
nextflow run bioinfo-tsukuba/nf-fastqc -profile test,singularity
```

iv. Start running your own analysis!

## Inputs and outputs

### Inputs

- FASTQ files

### Outputs

- `fastqc_raw/`
  - HTML reports of FastQC results for each FASTQ file
  - `zips/`
    - Zip files for FastQC reports.
- `pipeline_info/`
  - `execution_report.html`
  - `execution_timeline.html`
  - `execution_trace.txt`
  - `pipeline_dag.dot`
  - `pipeline_report.html`
  - `pipeline_report.txt`
- `nf-fastqc-YYYY-MM-DD-hh-mm-ss.log`
