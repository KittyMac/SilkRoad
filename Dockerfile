FROM swiftarm/swift:5.6.2-ubuntu-focal

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get install -y \
    libatomic1 \
    curl \
    unzip \
    xz-utils \
    patchelf \
    binutils \
    libjavascriptcoregtk-4.0-dev

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /root/
COPY "./AndroidSDK/android-x86_64.json" "./android-x86_64.json"
COPY "./AndroidSDK/swift-5.6-android-x86_64-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidSDK/android-aarch64.json" "./android-aarch64.json"
COPY "./AndroidSDK/swift-5.6-android-aarch64-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidSDK/android-armv7.json" "./android-armv7.json"
COPY "./AndroidSDK/swift-5.6-android-armv7-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidNDK/androidndk.zip" ./tmp.zip
RUN unzip ./tmp.zip
RUN rm -rf ./tmp.zip

RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-5.6-android-x86_64-24-sdk/usr/lib/swift/clang"
RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-5.6-android-aarch64-24-sdk/usr/lib/swift/clang"
RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-5.6-android-armv7-24-sdk/usr/lib/swift/clang"

# Generate the lib folder for output libraries
WORKDIR /root/lib
WORKDIR /root/lib/x86_64
RUN rm -rf ./*
RUN cp /root/swift-5.6-android-x86_64-24-sdk/usr/lib/swift/android/*.so ./
RUN cp /root/swift-5.6-android-x86_64-24-sdk/usr/lib/*.so ./

WORKDIR /root/lib/arm64-v8a
RUN rm -rf ./*
RUN cp /root/swift-5.6-android-aarch64-24-sdk/usr/lib/swift/android/*.so ./
RUN cp /root/swift-5.6-android-aarch64-24-sdk/usr/lib/*.so ./

WORKDIR /root/lib/armeabi-v7a
RUN rm -rf ./*
RUN cp /root/swift-5.6-android-armv7-24-sdk/usr/lib/swift/android/*.so ./
RUN cp /root/swift-5.6-android-armv7-24-sdk/usr/lib/*.so ./

# Import helper scripts
COPY ./Scripts/swift-build-all /usr/bin/swift-build-all
COPY ./Scripts/patch-elf /usr/bin/patch-elf
COPY ./Scripts/remove-so /usr/bin/remove-so
COPY ./Scripts/strip-so /usr/bin/strip-so
COPY ./Scripts/termux-install /usr/bin/termux-install
RUN chmod 755 /usr/bin/swift-build-all
RUN chmod 755 /usr/bin/patch-elf
RUN chmod 755 /usr/bin/remove-so
RUN chmod 755 /usr/bin/strip-so
RUN chmod 755 /usr/bin/termux-install

# from https://packages.termux.dev/apt/termux-main/pool/main/
RUN /usr/bin/termux-install z/zlib/zlib_1.2.13 libz.so libz.so

# Required for libFoundationNetworking.so
#
# See https://curl.haxx.se/docs/sslcerts.html
# For SSL on Android you need a "cacert.pem" to be
# accessible at the path pointed to by this env var.
# Downloadable here: https://curl.haxx.se/ca/cacert.pem
#
RUN /usr/bin/termux-install libc/libcurl/libcurl_7.85.0 libcurl.so libcurl.so

RUN /usr/bin/termux-install libn/libnghttp2/libnghttp2_1.50.0 libnghttp2.so libnghttp2.so
RUN /usr/bin/termux-install libs/libssh2/libssh2_1.10.0-2 libssh2.so libssh2.so

RUN /usr/bin/termux-install o/openssl/openssl_1:3.0.5 libssl.so.3 libssl.so
RUN /usr/bin/termux-install o/openssl/openssl_1:3.0.5 libcrypto.so.3 libcrypto.so

RUN /usr/bin/patch-elf libssh2.so --replace-needed "libssl.so.3" "libssl.so"
RUN /usr/bin/patch-elf libssh2.so --replace-needed "libcrypto.so.3" "libcrypto.so"
RUN /usr/bin/patch-elf libssh2.so --replace-needed "libz.so.1" "libz.so"

RUN /usr/bin/patch-elf libcurl.so --replace-needed "libnghttp2.so" "libnghttp2.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libssh2.so" "libssh2.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libssl.so.3" "libssl.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libcrypto.so.3" "libcrypto.so"
RUN /usr/bin/patch-elf libcurl.so --replace-needed "libz.so.1" "libz.so"

RUN /usr/bin/patch-elf libssl.so --set-soname "libssl.so"
RUN /usr/bin/patch-elf libssl.so --replace-needed "libcrypto.so.3" "libcrypto.so"

RUN /usr/bin/patch-elf libcrypto.so --set-soname "libcrypto.so"


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
