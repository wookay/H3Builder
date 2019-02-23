# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "H3"
version = v"3.4.2"
#
# function url2hash(url)
#     path = download(url)
#     open(io-> bytes2hex(BinaryProvider.sha256(io)), path)
# end
# url2hash("https://github.com/uber/h3/archive/v3.4.2.zip") |> println

sources = [
    "https://github.com/uber/h3/archive/v3.4.2.zip" =>
    "c5d024af8f7a852349ffce69fe33b456f96d7c940c4ffbeb872f98318b21e03c",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/h3-*/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain \
      -DRUN_HAVE_STD_REGEX=0 \
      -DRUN_HAVE_STEADY_CLOCK=0 \
      ../
make
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libh3", :libh3),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
