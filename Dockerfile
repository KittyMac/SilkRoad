FROM swiftarm/swift:5.6.2-ubuntu-focal

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get install -y \
    libatomic1 \
    curl \
    unzip \
    xz-utils \
    patchelf

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
COPY ./Scripts/patch-dependency /usr/bin/patch-dependency
RUN chmod 755 /usr/bin/swift-build-all
RUN chmod 755 /usr/bin/patch-dependency

# At this point, all of the built dynamic libraries should exist in /root/lib. You can then use docker cp to copy the files out and 
# into your Android studio project's jniLibs folder. Your script should delete any of the .so files your app does not actually use.

# Swift package manager does not appear to format the .so files it generates correctly. Specifically they will
# not have their dependencies listed. To fix this, use the included patch-dependency script after you run /usr/bin/swift-build-all
# Example:
# patch-dependency DependencyName ProjectName
# This will run patchelf --add-needed to insert the dependency libDependencyName.so to each architecture's libProjectName.so.

# In your Android project, you then System.loadLibrary("ProjectName") to load libProjectName.so the appropriate dependencies should
# also be loaded.
