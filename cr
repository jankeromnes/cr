#! /bin/bash

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
  echo "   help      Display this helpful message"
  echo ""
}

# Detect preferred shell rc file
SHELL_INIT="$HOME/.bashrc"
if [ "${SHELL##*/}" == "zsh" ]; then
  SHELL_INIT="$HOME/.zshrc"
fi

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
  echo "The Chromium sources expect to live in a directory named \"src\"."
  echo -n "Where should I put this src directory? [$CHROMIUM_HOME]:"
  read CHROMIUM_HOME_CUSTOM
  if [ -n "$CHROMIUM_HOME_CUSTOM" ]; then
    CHROMIUM_HOME="$CHROMIUM_HOME_CUSTOM"
  fi

  # Make sure we have git
  command -v git >/dev/null 2>&1 || {
    echo -n "Git is required to check out sources. Install git using apt-get? [Y/n]:"
    read INSTALL_GIT_CUSTOM
    if [ "$INSTALL_GIT_CUSTOM" == "n" ]; then
      echo "Aborting. Please install git."
      exit 0
    fi
    sudo apt-get install git
  }

  # Make sure we have depot_tools
  do_gclient

  # Configure Git
  git config --global core.autocrlf false
  git config --global core.filemode false

  # Configure ninja
  # TODO handle already defined GYP_GENERATORS better
  if [ "$GYP_GENERATORS" != "ninja" ]; then
    echo "Configuring ninja..."
    export GYP_GENERATORS="ninja"
    echo -e "\n# Build Chromium with ninja (faster than make)" >> "$SHELL_INIT"
    echo "export GYP_GENERATORS=\"ninja\"" >> "$SHELL_INIT"
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

  if [ -z "$FETCH_RECIPE" ]; then
    FETCH_RECIPE="blink"
    echo -n "Will you be developing Chrome for Android? [y/N]:"
    read ANDROID_RECIPE_CUSTOM
    if [ "$ANDROID_RECIPE_CUSTOM" == "y" ]; then
      FETCH_RECIPE="android"
    fi
  fi

  # Get the sources
  mkdir $CHROMIUM_HOME > /dev/null 2>&1
  cd $CHROMIUM_HOME
  echo "Downloading Chromium, grab a coffee..."
  fetch $FETCH_RECIPE --nosvn=True # --nohooks --jobs=16
  ./src/build/install-build-deps.sh
  gclient sync --jobs=16
  ./src/build/gyp_chromium

  # TODO git config merge.changelog.driver "perl Tools/Scripts/resolve-ChangeLogs --fix-merged --merge-driver %O %A %B"

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
  BUILD_THREADS="10000"
  command -v goma_ctl.sh >/dev/null 2>&1 || [ -n "$GOMA_DIR" ] || {
    BUILD_THREADS="16"
  }
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
  echo -n "Number of threads? [$BUILD_THREADS]:"
  read BUILD_THREADS_CUSTOM
  if [ -n "$BUILD_THREADS_CUSTOM" ]; then
    BUILD_THREADS="$BUILD_THREADS_CUSTOM"
  fi
  if [[ "$GYP_GENERATORS" == *"ninja"* ]]; then
    mkdir -p "out/$BUILD_TYPE" > /dev/null 2>&1
    ninja -C "out/$BUILD_TYPE" $TARGET"" -j"$BUILD_THREADS"
  else
    make "$TARGET" BUILDTYPE="$BUILD_TYPE" -j"$BUILD_THREADS"
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
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_HOME
    export PATH="$PATH:$DEPOT_TOOLS_HOME"
    if ! grep -qs "$DEPOT_TOOLS_HOME" "$SHELL_INIT"; then
      echo -e "\n# Add Chromium's depot_tools to the PATH" >> "$SHELL_INIT"
      echo "export PATH=\"\$PATH:$DEPOT_TOOLS_HOME\"" >> "$SHELL_INIT"
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
    mkdir -p "$GYP_FILE" && rmdir "$GYP_FILE"
    echo "{
  'variables': {
    'debug_devtools': 1
  }
}" > "$GYP_FILE"
  fi
  echo -n "Calling gclient runhooks... "
  gclient runhooks
  echo "Done."
}

do_runhooks() {
  gclient runhooks
}

do_update() {
  . "$(git --exec-path)/git-sh-setup"
  require_clean_work_tree "update `pwd`"
  echo "Updating..."
  git fetch && git rebase origin/master
  gclient sync --jobs=16
  echo "Everything up-to-date."
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
  *)
    show_help
  ;;
esac
