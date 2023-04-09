# dropbox-cui

A command-line tool for Dropbox API

## Description

This tool lets you work with files and folders in your Dropbox account from the command line. To use it, you'll need an access token from the Dropbox developer console. The tool has different functions for tasks like downloading, moving, and listing files and folders. It uses "jq" to interpret JSON responses from the Dropbox API and "curl" to make HTTP requests. To authorize access to your Dropbox account, the script uses the "w3m" command-line browser and stores your app key and access token in files for later use.

## Usage

```bash
./dropbox.sh <command> [<args>]
```

## Dependencies

- curl
- jq
- w3m
