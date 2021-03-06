# Get the right library name for the platform.
if [ "${PLATFORM_NAME}" == "macosx" ]
then
LIBRARY_EXTENSION="dylib"
else
LIBRARY_EXTENSION="a"
fi

# Break out if the dylibs already exist.
if [ -e "${TARGET_TEMP_DIR}/libcares.${LIBRARY_EXTENSION}" ]
then
exit 0
fi

# Include default paths for MacPorts & HomeBrew.
export PATH=${PATH}:/opt/local/bin:/usr/local/bin

ARCH_WORKING_DIR_PREFIX="${TARGET_TEMP_DIR}/${TARGET_NAME}/${TARGET_NAME}"
LIPO_ARGS=()

for ARCH in ${ARCHS}
do

# Copy source to a new location to build.
ARCH_WORKING_DIR="${ARCH_WORKING_DIR_PREFIX}-${ARCH}"
cd "${SRCROOT}"
mkdir -p "${ARCH_WORKING_DIR}"
cp -af c-ares/ "${ARCH_WORKING_DIR}"
cd "${ARCH_WORKING_DIR}"

# Configure and build.
export CC="clang -arch ${ARCH} -isysroot ${SDKROOT} -L${BUILT_PRODUCTS_DIR} -I${BUILT_PRODUCTS_DIR}/${PUBLIC_HEADERS_FOLDER_PATH} -g -w"
CONFIGURE_ARGS=("--host=${ARCH}-apple-darwin" "--with-sysroot=${SDKROOT}" "--enable-debug" "--enable-optimize" "--disable-warnings" "--disable-werror" "--disable-curldebug" "--disable-symbol-hiding" "--enable-nonblocking")
if [ "${PLATFORM_NAME}" == "macosx" ]
then
CONFIGURE_ARGS=("CFLAGS=-mmacosx-version-min=10.6" "${CONFIGURE_ARGS[@]}" "--enable-shared" "--disable-static")
else
CONFIGURE_ARGS=("${CONFIGURE_ARGS[@]}" "--enable-static" "--disable-shared")
fi

./buildconf
./configure "${CONFIGURE_ARGS[@]}"
make

if [ "${PLATFORM_NAME}" == "macosx" ]
then
LONG_DYLIB=.libs/`readlink -n .libs/libcares.dylib`
install_name_tool -id @rpath/libcares.dylib ${LONG_DYLIB}
install_name_tool -add_rpath @loader_path/../Frameworks ${LONG_DYLIB}
fi

# Add to the lipo args.
LIPO_ARGS=("${LIPO_ARGS[@]}" "-arch" "${ARCH}" "${ARCH_WORKING_DIR}/.libs/libcares.${LIBRARY_EXTENSION}")

# Copy headers.
mkdir -p "${BUILT_PRODUCTS_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}-${PLATFORM_NAME}-${ARCH}"
cp -fRL *.h "${BUILT_PRODUCTS_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}-${PLATFORM_NAME}-${ARCH}"

# Preserve .a files name & location. They are needed by dsymutil later.
# libcares.a

done

# Create final library.
cd "${TARGET_TEMP_DIR}"
lipo -create "${LIPO_ARGS[@]}" -output "libcares.${LIBRARY_EXTENSION}"

# Create dSYM.
# NOTE: dsymutil depends on the static libraries being in the same place and having the same name (see previous note).
if [ "${PLATFORM_NAME}" == "macosx" ]
then
dsymutil libcares.dylib
fi

# Strip library.
strip -x "libcares.${LIBRARY_EXTENSION}"

# Copy the final library to the products directory.
mkdir -p "${BUILT_PRODUCTS_DIR}"
cp -f "libcares.${LIBRARY_EXTENSION}" "${BUILT_PRODUCTS_DIR}"
if [ "${PLATFORM_NAME}" == "macosx" ]
then
cp -Rf libcares.dylib.dSYM "${BUILT_PRODUCTS_DIR}"
fi
