FROM swift:5.8-jammy

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get install -y \
    libssl-dev \
    libjavascriptcoregtk-4.0-dev \
    libatomic1 \
    unzip \
    curl \
    wget \
    unzip \
    xz-utils \
    patchelf \
    binutils

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /root/
# COPY "./AndroidSDK/android-x86_64.json" "./android-x86_64.json"
COPY "./AndroidSDK/android-aarch64.json" "./android-aarch64.json"
COPY "./AndroidSDK/android-armv7.json" "./android-armv7.json"

COPY "./AndroidSDK/swift-release-android-aarch64-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidSDK/swift-release-android-armv7-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidSDK/swift-release-android-x86_64-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidNDK/android-ndk-r25c-linux.zip" ./tmp.zip
RUN unzip ./tmp.zip
RUN mv ./android-ndk-r25c ./android-ndk
RUN rm -rf ./tmp.zip

RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-release-android-aarch64-24-sdk/usr/lib/swift/clang"
RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-release-android-armv7-24-sdk/usr/lib/swift/clang"
RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-release-android-x86_64-24-sdk/usr/lib/swift/clang"

# Import vendored debian packages
COPY "./AndroidLibs" "./AndroidLibs"

# Generate the lib folder for output libraries
WORKDIR /root/lib
# WORKDIR /root/lib/x86_64
# RUN rm -rf ./*
# RUN cp /root/swift-release-android-x86_64-24-sdk/usr/lib/*.so ./
# RUN cp /root/swift-release-android-x86_64-24-sdk/usr/lib/swift/android/*.so ./

WORKDIR /root/lib/arm64-v8a
RUN rm -rf ./*
RUN cp /root/swift-release-android-aarch64-24-sdk/usr/lib/*.so ./
RUN cp /root/swift-release-android-aarch64-24-sdk/usr/lib/swift/android/*.so ./

WORKDIR /root/lib/armeabi-v7a
RUN rm -rf ./*
RUN cp /root/swift-release-android-armv7-24-sdk/usr/lib/*.so ./
RUN cp /root/swift-release-android-armv7-24-sdk/usr/lib/swift/android/*.so ./

# Import helper scripts
COPY ./Scripts/swift-build-all /usr/bin/swift-build-all
COPY ./Scripts/swift-build-all-debug /usr/bin/swift-build-all-debug
COPY ./Scripts/patch-elf /usr/bin/patch-elf
COPY ./Scripts/remove-so /usr/bin/remove-so
COPY ./Scripts/strip-so /usr/bin/strip-so
COPY ./Scripts/termux-install /usr/bin/termux-install
COPY ./Scripts/vendored-so-install /usr/bin/vendored-so-install
RUN chmod 755 /usr/bin/swift-build-all
RUN chmod 755 /usr/bin/swift-build-all-debug
RUN chmod 755 /usr/bin/patch-elf
RUN chmod 755 /usr/bin/remove-so
RUN chmod 755 /usr/bin/strip-so
RUN chmod 755 /usr/bin/termux-install
RUN chmod 755 /usr/bin/vendored-so-install

# Process all dependent libs (make update-libs)
RUN /usr/bin/vendored-so-install libc++_shared.so libc++_shared.so

RUN /usr/bin/vendored-so-install libjsc.so libjscSR.so
RUN /usr/bin/patch-elf libjscSR.so --set-soname "libjscSR.so"
RUN /usr/bin/strip-so libjscSR.so

RUN /usr/bin/termux-install liba/libandroid-spawn/libandroid-spawn_0.3 libandroid-spawn.so libandroid-spawn.so

RUN /usr/bin/termux-install libi/libicu/libicu_77.1-1 libicudata.so libicudata.so
RUN /usr/bin/patch-elf libicudata.so --set-soname "libicudata.so"
RUN /usr/bin/strip-so libicudata.so

RUN /usr/bin/termux-install libi/libicu/libicu_77.1-1 libicui18n.so libicui18n.so
RUN /usr/bin/patch-elf libicui18n.so --replace-needed "libicuuc.so.77" "libicuuc.so"
RUN /usr/bin/patch-elf libicui18n.so --set-soname "libicui18n.so"
RUN /usr/bin/strip-so libicui18n.so

RUN /usr/bin/termux-install libi/libicu/libicu_77.1-1 libicuuc.so libicuuc.so
RUN /usr/bin/patch-elf libicuuc.so --replace-needed "libicudata.so.77" "libicudata.so"
RUN /usr/bin/patch-elf libicuuc.so --set-soname "libicuuc.so"
RUN /usr/bin/strip-so libicuuc.so





RUN /usr/bin/termux-install z/zlib/zlib_1.3.1 libz.so libzSR.so
RUN /usr/bin/patch-elf libzSR.so --set-soname "libzSR.so"
RUN /usr/bin/strip-so libzSR.so

# libs and dependencies for libtesseract
RUN /usr/bin/termux-install libi/libiconv/libiconv_1.18 libiconv.so libiconv.so
RUN /usr/bin/strip-so libiconv.so

RUN /usr/bin/termux-install libl/liblzma/liblzma_5.8.1 liblzma.so liblzma.so
RUN /usr/bin/strip-so liblzma.so

RUN /usr/bin/termux-install libb/libbz2/libbz2_1.0.8-6 libbz2.so libbz2.so
RUN /usr/bin/strip-so libbz2.so

RUN /usr/bin/termux-install z/zstd/zstd_1.5.7 libzstd.so libzstd.so
RUN /usr/bin/strip-so libzstd.so

RUN /usr/bin/termux-install o/openjpeg/openjpeg_2.5.3 libopenjp2.so libopenjp2.so
RUN /usr/bin/strip-so libopenjp2.so

RUN /usr/bin/termux-install libx/libxml2/libxml2_2.14.4 libxml2.so libxml2.so
RUN /usr/bin/patch-elf libxml2.so --replace-needed "libz.so.1" "libzSR.so"
RUN /usr/bin/patch-elf libxml2.so --replace-needed "liblzma.so.5" "liblzma.so"
RUN /usr/bin/strip-so libxml2.so

RUN /usr/bin/termux-install libj/libjpeg-turbo/libjpeg-turbo_3.1.1 libjpeg.so libjpeg.so
RUN /usr/bin/strip-so libjpeg.so

RUN /usr/bin/termux-install libp/libpng/libpng_1.6.50 libpng.so libpng.so
RUN /usr/bin/patch-elf libpng.so --replace-needed "libz.so.1" "libzSR.so"
RUN /usr/bin/strip-so libpng.so

RUN /usr/bin/termux-install liba/libandroid-posix-semaphore/libandroid-posix-semaphore_0.1-3 libandroid-posix-semaphore.so libandroid-posix-semaphore.so

RUN /usr/bin/termux-install liba/libarchive/libarchive_3.8.1 libarchive.so libarchive.so
RUN /usr/bin/patch-elf libarchive.so --replace-needed "libcrypto.so.3" "libcryptoSR.so"
RUN /usr/bin/patch-elf libarchive.so --replace-needed "liblzma.so.5" "liblzma.so"
RUN /usr/bin/patch-elf libarchive.so --replace-needed "libbz2.so.1.0" "libbz2.so"
RUN /usr/bin/patch-elf libarchive.so --replace-needed "libz.so.1" "libzSR.so"
RUN /usr/bin/patch-elf libarchive.so --replace-needed "libxml2.so.16" "libxml2.so"
RUN /usr/bin/strip-so libarchive.so

RUN /usr/bin/termux-install g/giflib/giflib_5.2.1-2 libgif.so libgif.so
RUN /usr/bin/strip-so libgif.so

RUN /usr/bin/termux-install libt/libtiff/libtiff_4.7.0 libtiff.so libtiff.so
RUN /usr/bin/patch-elf libtiff.so --replace-needed "liblzma.so.5" "liblzma.so"
RUN /usr/bin/patch-elf libtiff.so --replace-needed "libzstd.so.1" "libzstd.so"
RUN /usr/bin/patch-elf libtiff.so --replace-needed "libjpeg.so.8" "libjpeg.so"
RUN /usr/bin/patch-elf libtiff.so --replace-needed "libz.so.1" "libzSR.so"
RUN /usr/bin/strip-so libtiff.so

RUN /usr/bin/termux-install libw/libwebp/libwebp_1.6.0-rc1-0 libwebp.so libwebp.so
RUN /usr/bin/termux-install libw/libwebp/libwebp_1.6.0-rc1-0 libwebpmux.so libwebpmux.so
RUN /usr/bin/termux-install libw/libwebp/libwebp_1.6.0-rc1-0 libsharpyuv.so libsharpyuv.so
RUN /usr/bin/strip-so libwebp.so

RUN /usr/bin/termux-install t/tesseract/tesseract_5.5.1 libtesseract.so libtesseract.so
RUN /usr/bin/patch-elf libtesseract.so --replace-needed "libz.so.1" "libzSR.so"
RUN /usr/bin/strip-so libtesseract.so

RUN /usr/bin/termux-install l/leptonica/leptonica_1.85.0 libleptonica.so libleptonica.so
RUN /usr/bin/patch-elf libleptonica.so --replace-needed "libpng16.so" "libpng.so"
RUN /usr/bin/patch-elf libleptonica.so --replace-needed "libjpeg.so.8" "libjpeg.so"
RUN /usr/bin/patch-elf libleptonica.so --replace-needed "libz.so.1" "libzSR.so"
RUN /usr/bin/patch-elf libleptonica.so --replace-needed "libgif.so.7" "libgif.so"
RUN /usr/bin/strip-so libleptonica.so

# For libetpan?

# RUN /usr/bin/termux-install libd/libdb/libdb_18.1.40-4 libdb.so libdb.so
# RUN /usr/bin/strip-so libdb.so

# Required for libFoundationNetworking.so
#
# See https://curl.haxx.se/docs/sslcerts.html
# For SSL on Android you need a "cacert.pem" to be
# accessible at the path pointed to by this env var.
# Downloadable here: https://curl.haxx.se/ca/cacert.pem
#
RUN /usr/bin/termux-install libc/libcurl/libcurl_8.14.1 libcurl.so libcurl.so
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libnghttp2.so" "libnghttp2.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libnghttp3.so" "libnghttp3.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libssh2.so" "libssh2.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libssl.so.3" "libsslSR.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libcrypto.so.3" "libcryptoSR.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libz.so.1" "libzSR.so"

RUN /usr/bin/termux-install libr/libresolv-wrapper/libresolv-wrapper_1.1.7-4 libresolv_wrapper.so libresolv_wrapper.so

RUN /usr/bin/termux-install libn/libnghttp2/libnghttp2_1.66.0 libnghttp2.so libnghttp2.so
RUN /usr/bin/termux-install libn/libnghttp3/libnghttp3_1.10.1 libnghttp3.so libnghttp3.so
RUN /usr/bin/termux-install libs/libssh2/libssh2_1.11.1 libssh2.so libssh2.so

RUN /usr/bin/termux-install o/openssl/openssl_1:3.5.0-1 libssl.so.3 libsslSR.so
RUN /usr/bin/termux-install o/openssl/openssl_1:3.5.0-1 libcrypto.so.3 libcryptoSR.so

RUN /usr/bin/patch-elf libssh2.so --replace-needed "libssl.so.3" "libsslSR.so"
RUN /usr/bin/patch-elf libssh2.so --replace-needed "libcrypto.so.3" "libcryptoSR.so"
RUN /usr/bin/patch-elf libssh2.so --replace-needed "libz.so.1" "libzSR.so"

RUN /usr/bin/patch-elf libsslSR.so --set-soname "libsslSR.so"
RUN /usr/bin/patch-elf libsslSR.so --replace-needed "libcrypto.so.3" "libcryptoSR.so"

RUN /usr/bin/patch-elf libcryptoSR.so --set-soname "libcryptoSR.so"


# At this point, all of the built dynamic libraries should exist in /root/lib. You can then use docker cp to copy the files out and 
# into your Android studio project's jniLibs folder. Your script should delete any of the .so files your app does not actually use.


# Note: When SPM builds shared libraries, the shared libraries are not formed as correctly
# as we need them to be. They are lacking in two areas:
# 1. They lack the soname field being populated
# 2. They lack the NEEDED fields being populated for the other libs they depend on
#
# For the libraries we need to recreate these fields using patchelf. There is a script
# (/usr/bin/patch-elf) included which will run the patchelf command on all architectures
# of the .so provided.
#
# Warning: we have experienced issues with calling patchelf too many times on the same
# .so and/or adding soname field to all .so. To combat this, the recommendation is to
# call patch-elf only once per .so, sending multiple modification commads at the same time
# and to add the soname only when absolutely necessary.

# Example:
# RUN /usr/bin/patch-elf libSpanker.so --add-needed "libHitch.so"
# This will run patchelf --add-needed to insert the dependency libHitch.so to libSextant.so for each architecture

# In your Android project, you can then System.loadLibrary("Sextant") to load libSextant.so the
# appropriate dependency libHitch.so should also be loaded.
