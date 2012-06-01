#!/bin/bash

show_help() {
  echo "usage: cr <command> [<args>]"
  echo ""
  echo "The cr commands are:"
  echo "   clone     Clone the Chromium sources into a new repository"
  echo "   help      Display this helpful message"
  echo "   update    Update a Chromium repository"
  echo ""
}

do_clone() {
  # Try to guess CHROMIUM_HOME
  if [ -z "$CHROMIUM_HOME" ]; then
    if [ -d /usr/local/google ]; then
      CHROMIUM_HOME="/usr/local/google"
    else
      CHROMIUM_HOME=`pwd`
    fi
  fi

  # Ask the user where to install Chromium
  echo -n "Where should I put chromium sources? [$CHROMIUM_HOME]:"
  read CHROMIUM_HOME_CUSTOM
  if [ -n "$CHROMIUM_HOME_CUSTOM" ]; then
    CHROMIUM_HOME="$CHROMIUM_HOME_CUSTOM"
  fi


  # Make sure we have depot_tools
  command -v gclient >/dev/null 2>&1 || {
    if [ -z "$DEPOT_TOOLS_HOME" ]; then
      DEPOT_TOOLS_HOME="$CHROMIUM_HOME/depot_tools"
    fi
    echo -n "Where should I install depot_tools? [$DEPOT_TOOLS_HOME]:"
    read DEPOT_TOOLS_HOME_CUSTOM
    if [ -n "$DEPOT_TOOLS_HOME_CUSTOM" ]; then
      DEPOT_TOOLS_HOME="$DEPOT_TOOLS_HOME_CUSTOM"
    fi
    git clone https://git.chromium.org/chromium/tools/depot_tools.git $DEPOT_TOOLS_HOME
    export PATH="$PATH:$DEPOT_TOOLS_HOME"
    if ! grep -qs "$DEPOT_TOOLS_HOME" $HOME/.bashrc; then
      echo "export PATH=\"\$PATH:$DEPOT_TOOLS_HOME\"" >> $HOME/.bashrc
    fi
  }


  # Check if the `src` folder already exists
  if [ -d "$CHROMIUM_HOME/src" ]; then
    echo -n "The folder $CHROMIUM_HOME/src already exists! Overwrite? [Y/n]:"
    read OVERWRITE_CUSTOM
    if [ "$OVERWRITE_CUSTOM" == "n" ]; then
      echo "Leaving current installation intact."
      exit 0
    fi
  fi

  # Create the `.gclient` file
  mkdir $CHROMIUM_HOME > /dev/null 2>&1
  cd $CHROMIUM_HOME
  gclient config http://git.chromium.org/chromium/src.git --git-deps

  # Avoid checking out enormous folders
  mv .gclient{,.old}
  cat .gclient.old | grep -B42 "custom_deps" > .gclient
  echo "      \"src/third_party/WebKit/LayoutTests\": None," >> .gclient
  echo "      \"src/chrome_frame/tools/test/reference_build/chrome\": None," >> .gclient
  echo "      \"src/chrome_frame/tools/test/reference_build/chrome_win\": None," >> .gclient
  echo "      \"src/chrome/tools/test/reference_build/chrome\": None," >> .gclient
  echo "      \"src/chrome/tools/test/reference_build/chrome_linux\": None," >> .gclient
  echo "      \"src/chrome/tools/test/reference_build/chrome_mac\": None," >> .gclient
  echo "      \"src/chrome/tools/test/reference_build/chrome_win\": None" >> .gclient
  cat .gclient.old | grep -B1 -A42 "safesync_url" >> .gclient
  rm -rf .gclient.old

  # Allow users to customize the `.gclient` file
  echo -n "Do you want to customize the $CHROMIUM_HOME/.gclient file? [y/N]:"
  read GCLIENT_CUSTOM
  if [ "$GCLIENT_CUSTOM" == "y" ]; then
    vim .gclient
  fi

  # Get the sources
  echo "Downloading chromium, grab a coffee..."
  gclient sync --nohooks
  ./src/build/install-build-deps.sh
  gclient sync

  echo "If there were no errors above, cloning in $CHROMIUM_HOME was successful."
  echo "Welcome to your new Chromium!"
}

do_update() {
  if [ "`basename $PWD`" == "src" ]; then
    echo "Updating..."
  else
    echo -n "WARNING: You're not in \"src\", do you know what you are doing? [Y/n]:"
    read I_THE_MAN
    if [ "$I_THE_MAN" == "n" ]; then
      echo "Aborting update."
      exit 0
    fi
  fi
  git pull --rebase
  if cat ../.gclient | grep "\"src/third_party/WebKit/*\" *: *None" > /dev/null; then
    # Special WebKit update
    ./tools/sync-webkit-git.py
    cd third_party/WebKit && git rebase gclient && cd ../..
  fi
  gclient sync
  echo "Everything up-to-date."
}

case $1 in
  clone)
    do_clone
  ;;
  update)
    do_update
  ;;
  *)
    show_help
  ;;
esac
