#!/bin/sh

# this is where this script will store downloaded files and check for already
# downloaded files
dlwhere="$HOME/tmp"

# will append the target string to the prefix dir mentioned here
# Note that the user running this script must be able to do make install in
# this given prefix directory. Also make sure that this given root dir
# exists.
prefix="/usr/local"

# The binutils version to use
binutils="2.16.1"

##############################################################################

findtool(){
  file="$1"

  IFS=":"
  for path in $PATH
  do
    # echo "checks for $file in $path" >&2
    if test -f "$path/$file"; then
      echo "$path/$file"
      return
    fi
  done
}

input() {
    read response
    echo $response
}

#$1 file
#$2 URL"root
getfile() {
  tool=`findtool curl`
  if test -z "$tool"; then
    tool=`findtool wget`
    if test -n "$tool"; then
      # wget download
      echo "download $2/$1 using wget"
      $tool -O $dlwhere/$1 $2/$1
    fi
  else
     # curl download
      echo "download $2/$1 using curl"
     $tool -Lo $dlwhere/$1 $2/$1
  fi
  if test -z "$tool"; then 
    echo "couldn't find downloader tool to use!"
    exit
  fi
  

}

echo "Pick target arch:"
echo "s. sh"
echo "m. m68k"
echo "a. arm"

arch=`input`

case $arch in
  [Ss])
    target="sh-elf"
    gccver="4.0.3"
    ;;
  [Mm])
    target="m68k-elf"
    gccver="3.4.6"
    ;;
  [Aa])
    target="arm-elf"
    gccver="4.0.3"
    ;;
  *)
    echo "unsupported"
    exit
    ;;
esac

if test -d build-rbdev; then
  echo "you have a build-rbdev dir already, please remove and rerun"
  exit
fi

bindir="$prefix/$target/bin"
echo "Summary:"
echo "Target: $target"
echo "gcc $gccver"
echo "binutils $binutils"
echo "install in $prefix/$target"
echo ""
echo "Set your PATH to point to $bindir"


if test -f "$dlwhere/binutils-$binutils.tar.bz2"; then
  echo "binutils $binutils already downloaded"
else
  getfile binutils-$binutils.tar.bz2 ftp://ftp.gnu.org/pub/gnu/binutils
fi

if test -f "$dlwhere/gcc-$gccver.tar.bz2"; then
  echo "gcc $gccver already downloaded"
else
  getfile gcc-$gccver.tar.bz2 ftp://ftp.gnu.org/pub/gnu/gcc/gcc-$gccver
fi


mkdir build-rbdev
cd build-rbdev
echo "extracting binutils"
tar xjf $dlwhere/binutils-$binutils.tar.bz2
echo "extracting gcc"
tar xf $dlwhere/gcc-$gccver.tar.bz2

mkdir build-binu
cd build-binu
../binutils-$binutils/configure --target=$target --prefix=$prefix/$target
make
make install
PATH="${PATH}:$bindir"
SHELL=/bin/sh # seems to be needed by the gcc build in some cases

cd ../
mkdir build-gcc
cd build-gcc
../gcc-$gccver/configure --target=$target --prefix=$prefix/$target --enable-languages=c
make
make install

echo "done"
