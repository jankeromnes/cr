# CR

`cr` is a tool to help you work on the Chromium browser sources

## What can it do for me?

- Download fresh Chromium sources (`cr clone`)
- Build Chromium browser (`cr build`)
- Update Chromium sources (`cr update`)
- Install Chromium depot\_tools and dependencies (`cr clone` makes sure you have everything)
- Download separate WebKit sources (`cr webkit` replaces your `third_party/WebKit` with a fresh WebKit clone)

## What not?

- Run Chromium (soon)
- Help upload Chromium patches (soon)
- Help upload WebKit patches (soon)

## Usage

    usage: cr <command> [<args>]

    The cr commands are:

       clone     Clone the Chromium sources into a new repository
       clean     Remove a previously built Chromium browser
       build     Build the Chromium browser from sources
       devtools  Setup hard links for Web Inspector files
       gclient   Install gclient and the depot_tools
       runhooks  Call gclient runhooks
       update    Update a Chromium repository and its dependencies
       webkit    Clone separate WebKit sources into your repository
       help      Display this helpful message

## Install

(or **Update**)

    sudo wget -O /usr/local/bin/cr "https://raw.github.com/jankeromnes/cr/master/cr" && sudo chmod +x /usr/local/bin/cr

---

(also works with `curl`)

    sudo curl -o /usr/local/bin/cr "https://raw.github.com/jankeromnes/cr/master/cr" && sudo chmod +x /usr/local/bin/cr

## Uninstall

    sudo rm -rf /usr/local/bin/cr

