FROM swiftarm/swift:5.6.2-ubuntu-focal

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

# Import helper scripts
COPY ./Scripts/swift-build-all /usr/bin/swift-build-all
RUN chmod 755 /usr/bin/swift-build-all

# Import SPM project
WORKDIR /root/SilkRoad
COPY ./Makefile ./Makefile
COPY ./Package.swift ./Package.swift
COPY ./Sources ./Sources
COPY ./Tests ./Tests

RUN /usr/bin/swift-build-all

# At this point, all of the built dynamic libraries should exist in /root/lib. You can then use docker cp to copy the files out and into your Android studio
# project's jniLibs folder. Your script should delete any of the .so files you app does not actually use.
