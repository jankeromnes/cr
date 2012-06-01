# CR

`cr` is a tool to help you work on the Chromium browser sources

## What can it do for me?

- Download fresh Chromium sources
- Build Chromium browser
- Update Chromium sources
- Update separate WebKit sources automatically
- Install Chromium depot_tools and dependencies

## What not?

- Run Chromium (soon)
- Install separate WebKit sources (soon)
- Help upload Chromium patches (soon)
- Help upload WebKit patches (soon)

## Usage

    usage: cr <command> [<args>]

    The cr commands are:

       clone     Clone the Chromium sources into a new repository
       build     Build the Chromium browser from sources
       update    Update a Chromium repository
       help      Display this helpful message

## Install

    sudo wget -O /usr/local/bin/cr "https://raw.github.com/jankeromnes/cr/master/cr" && sudo chmod +x /usr/local/bin/cr

## Uninstall

    sudo rm -rf /usr/local/bin/cr

