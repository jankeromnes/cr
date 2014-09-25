# CR

`cr` is a tool to help you work on the Chromium browser sources

## What can it do for me?

- Download fresh Chromium sources (`cr clone`)
- Autoinstall Chromium depot\_tools and dependencies (`cr clone` makes sure you have everything)
- Build the latest Chromium browser (`cr build`)
- Update ALL the source codes (`cr update`)

And also...

- Guarantee that you always use the latest best practices to make things go faster
- Help to skip builds for Web Inspector (`cr devtools` sets up hard links for inspector files)

## What not?

- Run Chromium (soon)
- Help doing Chromium patches (soon)
- Help doing Blink patches (soon)

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
       help      Display this helpful message

## Install

(also **Update**)

    su -c "curl -o /usr/local/bin/cr https://raw.githubusercontent.com/jankeromnes/cr/master/cr && chmod a+rx /usr/local/bin/cr"

---

(also works with `wget`)

    su -c "wget -O /usr/local/bin/cr https://raw.githubusercontent.com/jankeromnes/cr/master/cr && chmod a+rx /usr/local/bin/cr"

## Uninstall

    su -c "rm -rf /usr/local/bin/cr"

