#!/bin/bash

. "$(git --exec-path)/git-sh-setup"

show_help() {
  echo "usage: cr <command> [<args>]"
  echo ""
  echo "The cr commands are:"
  echo "   clone     Clone the Chromium sources into a new repository"
  echo "   clean     Remove a previously built Chromium browser"
  echo "   build     Build the Chromium browser from sources"
  echo "   devtools  Setup hard links for Web Inspector files"
  echo "   gclient   Install gclient and the depot_tools"
  echo "   runhooks  Call gclient runhooks"
  echo "   update    Update a Chromium repository and its dependencies"
  echo "   webkit    Clone separate WebKit sources into your repository"
  echo "   help      Display this helpful message"
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
  do_gclient

  # Configure ninja
  if [ "$GYP_GENERATORS" != "ninja" ]; then
    echo "Configuring ninja..."
    export GYP_GENERATORS="ninja"
    echo -e "\n# build chromium with ninja (faster than make)" >> "$HOME/.bashrc"
    echo "export GYP_GENERATORS=\"ninja\"" >> "$HOME/.bashrc"
  fi

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
  cat .gclient.old | grep -A42 "custom_deps" | tail -n +2 >> .gclient
  rm -rf .gclient.old

  # Allow users to customize the `.gclient` file
  echo -n "Do you want to customize the $CHROMIUM_HOME/.gclient file? [y/N]:"
  read GCLIENT_CUSTOM
  if [ "$GCLIENT_CUSTOM" == "y" ]; then
    vim .gclient
  fi

  # Get the sources
  echo "Downloading chromium, grab a coffee..."
  gclient sync --nohooks --jobs=16
  ./src/build/install-build-deps.sh
  gclient sync --jobs=16
  ./src/build/gyp_chromium

  echo "If there were no errors above, cloning in $CHROMIUM_HOME was successful."
  echo "Welcome to your new Chromium!"
}

assert_src() {
  if [ "`basename $PWD`" != "src" ]; then
    echo -n "WARNING: You're not in \"src\", do you know what you are doing? [Y/n]:"
    read I_THE_MAN
    if [ "$I_THE_MAN" == "n" ]; then
      echo "Aborting."
      exit 0
    fi
  fi
}

do_clean() {
  rm -rf out
  gclient runhooks
}

do_build() {
  BUILD_TYPE="Release"
  if [ -d "$HOME/goma" ]; then
    BUILD_CORES="500"
  else
    BUILD_CORES="16"
  fi
  if [ -z "$TARGET" ]; then
    TARGET="chrome"
  fi
  echo -n "TARGET? [$TARGET]:"
  read TARGET_CUSTOM
  if [ -n "$TARGET_CUSTOM" ]; then
    TARGET="$TARGET_CUSTOM"
  fi
  echo -n "BUILDTYPE? [$BUILD_TYPE]:"
  read BUILD_TYPE_CUSTOM
  if [ -n "$BUILD_TYPE_CUSTOM" ]; then
    BUILD_TYPE="$BUILD_TYPE_CUSTOM"
  fi
  echo -n "Use how many cores? [$BUILD_CORES]:"
  read BUILD_CORES_CUSTOM
  if [ -n "$BUILD_CORES_CUSTOM" ]; then
    BUILD_CORES="$BUILD_CORES_CUSTOM"
  fi
  if [ "$GYP_GENERATORS" == "ninja" ]; then
    mkdir -p "out/$BUILD_TYPE" > /dev/null 2>&1
    ninja -C "out/$BUILD_TYPE" $TARGET"" -j"$BUILD_CORES"
  else
    make "$TARGET" BUILDTYPE="$BUILD_TYPE" -j"$BUILD_CORES"
  fi
}

do_gclient() {
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
      echo -e "\n# add chromium's depot_tools to the PATH" >> "$HOME/.bashrc"
      echo "export PATH=\"\$PATH:$DEPOT_TOOLS_HOME\"" >> "$HOME/.bashrc"
    fi
  }
  echo "gclient is installed as $(which gclient)"
}

do_devtools() {
  GYP_FILE="$HOME/.gyp/include.gypi"
  if [ -f "$GYP_FILE" ]; then
    echo "WARNING: $GYP_FILE already exists! Leaving as is:"
    cat "$GYP_FILE"
  else
    cat "{\n  'variables': {\n    'debug_devtools': 1\n  }\n}" > "$GYP_FILE"
  fi
  echo -n "Calling gclient runhooks... "
  gclient runhooks
  echo "Done."
}

do_runhooks() {
  gclient runhooks
}

do_update() {
  require_clean_work_tree "update `pwd`"
  echo "Updating..."
  git fetch && git rebase origin/master
  if cat ../.gclient | grep "\"src/third_party/WebKit/*\" *: *None" > /dev/null; then
    # Special WebKit update
    cd third_party/WebKit && require_clean_work_tree "update `pwd`" && git fetch && git rebase origin/master && cd ../..
  fi
  gclient sync --jobs=16
  echo "Everything up-to-date."
}

do_webkit() {
  rm -rf third_party/WebKit
  git clone http://git.chromium.org/external/Webkit.git third_party/WebKit
  cat ../.gclient | grep -v "WebKit" > ../.gclient.old
  cat ../.gclient.old | grep -B42 "custom_deps" > ../.gclient
  echo "      \"src/third_party/WebKit\": None," >> ../.gclient
  cat ../.gclient.old | grep -A42 "custom_deps" | tail -n +2 >> ../.gclient
  rm -rf ../.gclient.old
}

case $1 in
  clone)
    do_clone
  ;;
  clean)
    assert_src
    do_clean
  ;;
  build)
    assert_src
    do_build
  ;;
  devtools)
    assert_src
    do_devtools
  ;;
  gclient)
    do_gclient
  ;;
  runhooks)
    assert_src
    do_runhooks
  ;;
  update)
    assert_src
    do_update
  ;;
  webkit)
    assert_src
    do_webkit
  ;;
  *)
    show_help
  ;;
esac
