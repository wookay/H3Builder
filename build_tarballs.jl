# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "H3"
version = v"3.7.2"

#=
using BinaryProvider
function url2hash(url)
     path = download(url)
     open(io-> bytes2hex(BinaryProvider.sha256(io)), path)
end
url2hash("https://github.com/uber/h3/archive/v3.7.2.zip") |> println
=#

sources = [
    "https://github.com/uber/h3/archive/v$version.zip" => "805f787912608b09afa7c0e9c432c0e4b43f17a9d10faed880b3f74f038ce576",
]

# Bash recipe for building across all platforms
script = """
cd \$WORKSPACE/srcdir/h3-$version/
cat <<EOF > CMakeLists.txt.patch
diff -uNr h3-3.7.2-original/CMakeLists.txt h3-3.7.2/CMakeLists.txt > CMakeLists.txt.patch
--- h3-3.7.2-original/CMakeLists.txt    2021-08-12 16:32:04.000000000 +0900
+++ h3-3.7.2/CMakeLists.txt 2021-08-12 16:33:03.000000000 +0900
@@ -58,6 +58,9 @@

 project(h3 LANGUAGES C VERSION \\\${H3_VERSION})

+set(CMAKE_C_FLAGS "-std=c99 \\\${CMAKE_C_FLAGS}")
+set(CMAKE_C_LINK_FLAGS "-lm \\\${CMAKE_C_LINK_FLAGS}")
+
 set(H3_COMPILE_FLAGS "")
 set(H3_LINK_FLAGS "")
 if(NOT WIN32)
EOF
patch -p1 -i CMakeLists.txt.patch
mkdir build
cd build
cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_INSTALL_PREFIX=\${prefix} -DCMAKE_TOOLCHAIN_FILE=\${CMAKE_TARGET_TOOLCHAIN} -DBUILD_BENCHMARKS=0 -DBUILD_TESTING=0 ..
make
make install
rm -rf \$WORKSPACE/destdir/bin/{g,h,k}* \$WORKSPACE/destdir/lib/cmake \$WORKSPACE/destdir/logs
ls \$WORKSPACE/destdir/lib
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libh3", :libh3),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
