FROM swiftarm/swift:5.6.2-ubuntu-focal as builder

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get install -y \
    libatomic1 \
    curl \
    unzip \
    xz-utils

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
RUN cp /root/swift-5.6-android-x86_64-24-sdk/usr/lib/swift/android/*.so ./
RUN cp /root/swift-5.6-android-x86_64-24-sdk/usr/lib/*.so ./

WORKDIR /root/lib/arm64-v8a
RUN cp /root/swift-5.6-android-aarch64-24-sdk/usr/lib/swift/android/*.so ./
RUN cp /root/swift-5.6-android-aarch64-24-sdk/usr/lib/*.so ./

WORKDIR /root/lib/armeabi-v7a
RUN cp /root/swift-5.6-android-armv7-24-sdk/usr/lib/swift/android/*.so ./
RUN cp /root/swift-5.6-android-armv7-24-sdk/usr/lib/*.so ./

# Import your SPM project
WORKDIR /root/SilkRoad
COPY ./Makefile ./Makefile
COPY ./Package.swift ./Package.swift
COPY ./Sources ./Sources
COPY ./Tests ./Tests

# Cross-compile for x86_64 Android
RUN /usr/bin/swift build --build-tests --destination "/root/android-x86_64.json" -Xlinker -rpath -Xlinker "/root/swift-5.6-android-x86_64-24-sdk/usr/lib/swift/android"
RUN cp *.so /root/lib/x86_64/

# Cross-compile for aarch64 Android
RUN /usr/bin/swift build --build-tests --destination "/root/android-aarch64.json" -Xlinker -rpath -Xlinker "/root/swift-5.6-android-aarch64-24-sdk/usr/lib/swift/android"
RUN cp *.so /root/lib/arm64-v8a/

# Cross-compile for armv7 Android
RUN /usr/bin/swift build --build-tests --destination "/root/android-armv7.json" -Xlinker -rpath -Xlinker "/root/swift-5.6-android-armv7-24-sdk/usr/lib/swift/android"
RUN cp *.so /root/lib/armeabi-v7a/

# At this point, all of the built dynamic libraries should exist in /root/lib. You can then use docker cp to copy the files out and into your Android studio
# project's jniLibs folder.

# By default everything is set up to build dynamic libraries. This is done by passing -emit-library in the extra-swiftc-flags of the *.json build config files
# After each build, the relevant files will be in the SPM folder (ie ./libSilkRoadFramework.so). This is the file you will need to copy out of the container
# to include in your Android project.

# You will also need the Swift runtime libraries from the following paths (for each architecture you want to support):
# /root/swift-5.6-android-aarch64-24-sdk/usr/lib/swift/android
# /root/swift-5.6-android-armv7-24-sdk/usr/lib/swift/android
# /root/swift-5.6-android-x86_64-24-sdk/usr/lib/swift/android
#
# And the libraries you will likely need:
# libBlocksRuntime.so
# libFoundation.so
# libdispatch.so
# libswiftDispatch.so
# libswiftCore.so
# libswiftGlibc.so
# libswiftSwiftOnoneSupport.so
# libswift_Concurrency.so
# libswift_Differentiation.so
# libswift_MatchingEngine.so
# libswift_StringProcessing.so
# libFoundationNetworking.so
# libFoundationXML.so
