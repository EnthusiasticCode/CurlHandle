# Get the right library name for the platform.
if [ "${PLATFORM_NAME}" == "macosx" ]
then
LIBRARY_EXTENSION="dylib"
else
LIBRARY_EXTENSION="a"
fi

# Break out if the dylibs already exist.
if [ -e "${TARGET_TEMP_DIR}/libcurl.${LIBRARY_EXTENSION}" ]
then
exit 0
fi

# Include default paths for MacPorts & HomeBrew.
export PATH=${PATH}:/opt/local/bin:/usr/local/bin

ARCH_WORKING_DIR_PREFIX="${TARGET_TEMP_DIR}/${TARGET_NAME}/${TARGET_NAME}"
LIPO_ARGS=()

# Configure needs to be able to run programs linked with the dylibs. For this we need to copy libssh2 dependencies to where libssh2 expects them to be.
# if [ "${PLATFORM_NAME}" == "macosx" ]
# then
# mkdir -p ${BUILT_PRODUCTS_DIR}/../Frameworks
# cp -f ${BUILT_PRODUCTS_DIR}/libcrypto.dylib ${BUILT_PRODUCTS_DIR}/../Frameworks
# cp -f ${BUILT_PRODUCTS_DIR}/libssl.dylib ${BUILT_PRODUCTS_DIR}/../Frameworks
# fi

for ARCH in ${ARCHS}
do

# Copy source to a new location to build.
ARCH_WORKING_DIR="${ARCH_WORKING_DIR_PREFIX}-${ARCH}"
cd "${SRCROOT}"
mkdir -p "${ARCH_WORKING_DIR}"
cp -af curl/ "${ARCH_WORKING_DIR}"
cd "${ARCH_WORKING_DIR}"

# Configure and build.
export CC="clang -arch ${ARCH} -isysroot ${SDKROOT} -L${BUILT_PRODUCTS_DIR} -I${BUILT_PRODUCTS_DIR}/${PUBLIC_HEADERS_FOLDER_PATH} -I${BUILT_PRODUCTS_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}-${PLATFORM_NAME}-${ARCH} -g -w"
# On osx we need to add the rpath so the configure script can run test programs.
if [ "${PLATFORM_NAME}" == "macosx" ]
then
export LDFLAGS="-rpath ${BUILT_PRODUCTS_DIR}"
fi
CONFIGURE_ARGS=("--host=${ARCH}-apple-darwin" "--with-sysroot=${SDKROOT}" "--with-darwinssl" "--with-libssh2" "--enable-ares" "--without-libidn" "--enable-debug" "--enable-optimize" "--disable-warnings" "--disable-werror" "--disable-curldebug" "--disable-symbol-hiding" "--enable-proxy")
if [ "${PLATFORM_NAME}" == "macosx" ]
then
CONFIGURE_ARGS=("CFLAGS=-mmacosx-version-min=10.6" "${CONFIGURE_ARGS[@]}" "--enable-shared" "--disable-static")
else
CONFIGURE_ARGS=("CFLAGS=-miphoneos-version-min=5.0" "${CONFIGURE_ARGS[@]}" "--enable-static" "--disable-shared")
fi

./buildconf

./configure "${CONFIGURE_ARGS[@]}"

# On osx we need to remove the default rpath from the Makefile or it's going to clash with the one we specified earlier.
if [ "${PLATFORM_NAME}" == "macosx" ]
then
sed -ie "s/-rpath \$(libdir) //" "lib/Makefile"
fi

make

if [ "${PLATFORM_NAME}" == "macosx" ]
then
LONG_DYLIB=lib/.libs/`readlink -n lib/.libs/libcurl.dylib`
install_name_tool -id @rpath/libcurl.dylib ${LONG_DYLIB}
install_name_tool -add_rpath @loader_path/../Frameworks ${LONG_DYLIB}
fi

# Add to the lipo args.
LIPO_ARGS=("${LIPO_ARGS[@]}" "-arch" "${ARCH}" "${ARCH_WORKING_DIR}/lib/.libs/libcurl.${LIBRARY_EXTENSION}")

# Copy headers.
mkdir -p "${BUILT_PRODUCTS_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}-${PLATFORM_NAME}-${ARCH}/curl"
cp -fRL include/curl/*.h "${BUILT_PRODUCTS_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}-${PLATFORM_NAME}-${ARCH}/curl"

# Preserve .a files name & location. They are needed by dsymutil later.
# libcurl.a

done

# Create final library.
cd "${TARGET_TEMP_DIR}"
lipo -create "${LIPO_ARGS[@]}" -output "libcurl.${LIBRARY_EXTENSION}"

# Create dSYM.
# NOTE: dsymutil depends on the static libraries being in the same place and having the same name (see previous note).
if [ "${PLATFORM_NAME}" == "macosx" ]
then
dsymutil libcurl.dylib
fi

# Strip library.
strip -x "libcurl.${LIBRARY_EXTENSION}"

# Copy the final library to the products directory.
mkdir -p "${BUILT_PRODUCTS_DIR}"
cp -f "libcurl.${LIBRARY_EXTENSION}" "${BUILT_PRODUCTS_DIR}"
if [ "${PLATFORM_NAME}" == "macosx" ]
then
cp -Rf libcurl.dylib.dSYM "${BUILT_PRODUCTS_DIR}"
fi
