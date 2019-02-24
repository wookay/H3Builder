# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "H3"
version = v"3.4.2"

# function url2hash(url)
#     path = download(url)
#     open(io-> bytes2hex(BinaryProvider.sha256(io)), path)
# end
# url2hash("https://github.com/uber/h3/archive/v3.4.2.zip") |> println

sources = [
    "https://github.com/uber/h3/archive/v$version.zip" => "c5d024af8f7a852349ffce69fe33b456f96d7c940c4ffbeb872f98318b21e03c",
]

# Bash recipe for building across all platforms
script = """
cd \$WORKSPACE/srcdir/h3-$version/
cat <<EOF > CMakeLists.txt.patch
diff -uNr h3-3.4.2-original/CMakeLists.txt h3-3.4.2/CMakeLists.txt
--- h3-3.4.2-original/CMakeLists.txt    2019-02-23 18:30:30.000000000 +0900
+++ h3-3.4.2/CMakeLists.txt 2019-02-23 17:58:02.000000000 +0900
@@ -53,6 +53,8 @@

 project(h3 LANGUAGES C VERSION \\\${H3_VERSION})

+set(CMAKE_C_FLAGS "-std=c99 \\\${CMAKE_C_FLAGS}")
+
 set(H3_COMPILE_FLAGS "")
 set(H3_LINK_FLAGS "")
 if(NOT WIN32)
@@ -495,21 +497,6 @@
     add_h3_executable(mkRandGeo src/apps/testapps/mkRandGeo.c \\\${APP_SOURCE_FILES})
     add_h3_executable(mkRandGeoBoundary src/apps/testapps/mkRandGeoBoundary.c \\\${APP_SOURCE_FILES})

-    # Benchmarks
-    add_custom_target(benchmarks)
-
-    macro(add_h3_benchmark name srcfile)
-        add_h3_executable(\\\${name} \\\${srcfile} \\\${APP_SOURCE_FILES})
-        add_custom_target(bench_\\\${name} COMMAND \\\${TEST_WRAPPER} \\\$<TARGET_FILE:\\\${name}>)
-        add_dependencies(benchmarks bench_\\\${name})
-    endmacro()
-
-    add_h3_benchmark(benchmarkH3Api src/apps/benchmarks/benchmarkH3Api.c)
-    add_h3_benchmark(benchmarkKRing src/apps/benchmarks/benchmarkKRing.c)
-    add_h3_benchmark(benchmarkH3Line src/apps/benchmarks/benchmarkH3Line.c)
-    add_h3_benchmark(benchmarkH3SetToLinkedGeo src/apps/benchmarks/benchmarkH3SetToLinkedGeo.c)
-    add_h3_benchmark(benchmarkPolyfill src/apps/benchmarks/benchmarkPolyfill.c)
-    add_h3_benchmark(benchmarkPolygon src/apps/benchmarks/benchmarkPolygon.c)
 endif()

 # Installation (https://github.com/forexample/package-example)
EOF
patch -p1 -i CMakeLists.txt.patch
mkdir build
cd build
cmake -DBUILD_SHARED_LIBS=1 -DCMAKE_INSTALL_PREFIX=\$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/\$target/\$target.toolchain ..
make
make install
rm -rf \$WORKSPACE/destdir/bin/{g,h,k}* \$WORKSPACE/destdir/lib/cmake \$WORKSPACE/destdir/logs
ls \$WORKSPACE/destdir/lib
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
