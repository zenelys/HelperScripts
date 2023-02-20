# Scripts to faster interact with s3 buckets

## Prerequisites

- [python3]([python3](https://www.python.org/))
- [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)

## Installation

1. Make all files `executable` in the `bin`
2. Copy `bin` to somewhere in the `$PATH`

```bash
git clone git@github.com:zenelys/HelperScripts.git
cd HelperScripts/s3-scripts
chmod -R +x bin/
cp bin/* ~/.local/bin/
```

## Scripts

- `empty_s3_bucket.py`: To empty entire s3 bucket or delete folder (prefix) with all versions (permanently)
