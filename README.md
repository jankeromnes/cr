# CR

`cr` is a utility to help you work on the Chromium browser sources

## What can it do?

- Download Chromium sources
- Install Chromium depot_tools
- Install Chomium dependencies
- Update Chromium sources
- Update separate WebKit sources

## What not?

- Build Chromium (soon)
- Run Chromium (soon)
- Install separate WebKit sources (soon)
- Help upload Chromium patches (soon)
- Help upload WebKit patches (soon)

## Usage

    usage: cr <command> [<args>]

    The cr commands are:

       clone     Clone the Chromium sources into a new repository
       help      Display this helpful message
       update    Update a Chromium repository

## Install

    sudo wget -O /usr/local/bin/cr "https://raw.github.com/jankeromnes/cr/master/cr" && sudo chmod +x /usr/local/bin/cr

## Uninstall

    sudo rm -rf /usr/local/bin/cr

