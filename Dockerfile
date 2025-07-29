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
COPY ./Scripts/silkroad-fix-so /usr/bin/silkroad-fix-so
RUN chmod 755 /usr/bin/swift-build-all
RUN chmod 755 /usr/bin/swift-build-all-debug
RUN chmod 755 /usr/bin/patch-elf
RUN chmod 755 /usr/bin/remove-so
RUN chmod 755 /usr/bin/strip-so
RUN chmod 755 /usr/bin/termux-install
RUN chmod 755 /usr/bin/vendored-so-install
RUN chmod 755 /usr/bin/silkroad-fix-so

# Run the script to patch all .so files in preparation for building for Android
RUN /usr/bin/silkroad-fix-so

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
