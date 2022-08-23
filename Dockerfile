FROM swiftarm/swift:5.6.2-ubuntu-focal as builder

ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get install -y \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libjavascriptcoregtk-4.0-dev \
    libatomic1 \
    curl \
    unzip \
    xz-utils

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /root/
COPY "./AndroidSDK/android-x86_64.json" "./android-x86_64.json"
RUN sed -i "s%/home/butta/swift-5.6.2-RELEASE-ubuntu20.04%%" android-x86_64.json
RUN sed -i "s%/home/butta/%/root/%" android-x86_64.json
COPY "./AndroidSDK/swift-5.6-android-x86_64-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidSDK/android-aarch64.json" "./android-aarch64.json"
RUN sed -i "s%/home/butta/swift-5.6.2-RELEASE-ubuntu20.04%%" android-aarch64.json
RUN sed -i "s%/home/butta/%/root/%" android-aarch64.json
COPY "./AndroidSDK/swift-5.6-android-aarch64-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidSDK/android-armv7.json" "./android-armv7.json"
RUN sed -i "s%/home/butta/swift-5.6.2-RELEASE-ubuntu20.04%%" android-armv7.json
RUN sed -i "s%/home/butta/%/root/%" android-armv7.json
COPY "./AndroidSDK/swift-5.6-android-armv7-24-sdk.tar.xz" ./tmp.tar.xz
RUN tar -xf tmp.tar.xz
RUN rm -rf ./tmp.tar.xz

COPY "./AndroidNDK/androidndk.zip" ./tmp.zip
RUN unzip ./tmp.zip
RUN rm -rf ./tmp.zip

RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-5.6-android-x86_64-24-sdk/usr/lib/swift/clang"
RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-5.6-android-aarch64-24-sdk/usr/lib/swift/clang"
RUN ln -sf /usr/lib/clang/13.0.0 "/root/swift-5.6-android-armv7-24-sdk/usr/lib/swift/clang"

# Confirm we can compile for Android
WORKDIR /root/SilkRoad
COPY ./Makefile ./Makefile
COPY ./Package.swift ./Package.swift
COPY ./Sources ./Sources
COPY ./Tests ./Tests

# Test cross-compile for x86_64 Android
RUN /usr/bin/swift build --build-tests --destination "/root/android-x86_64.json" -Xlinker -rpath -Xlinker "/root/swift-5.6-android-x86_64-24-sdk/usr/lib/swift/android"

# Test cross-compile for aarch64 Android
RUN /usr/bin/swift build --build-tests --destination "/root/android-aarch64.json" -Xlinker -rpath -Xlinker "/root/swift-5.6-android-aarch64-24-sdk/usr/lib/swift/android"

# Test cross-compile for armv7 Android
RUN /usr/bin/swift build --build-tests --destination "/root/android-armv7.json" -Xlinker -rpath -Xlinker "/root/swift-5.6-android-armv7-24-sdk/usr/lib/swift/android"
