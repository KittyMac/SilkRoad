all: docker
	
clean:
	rm -rf ./AndroidNDK
	rm -f ./AndroidSDK/swift-5.6-android-aarch64-24-sdk.tar.xz
	rm -f ./AndroidSDK/swift-5.6-android-x86_64-24-sdk.tar.xz
	rm -f ./AndroidSDK/swift-5.6-android-armv7-24-sdk.tar.xz

android-ndk:
	mkdir -p ./AndroidNDK
	@[ -f ./AndroidNDK/androidndk.zip ] && echo "skipping ndk download..." || wget -q -O ./AndroidNDK/androidndk.zip https://dl.google.com/android/repository/android-ndk-r23c-linux.zip
	
android-sdk:
	mkdir -p ./AndroidSDK
	@[ -f ./AndroidSDK/swift-5.6-android-aarch64-24-sdk.tar.xz ] && echo "skipping aarch64 sdk download..." || wget -q -O ./AndroidSDK/swift-5.6-android-aarch64-24-sdk.tar.xz https://github.com/buttaface/swift-android-sdk/releases/download/5.6/swift-5.6-android-aarch64-24-sdk.tar.xz
	@[ -f ./AndroidSDK/swift-5.6-android-x86_64-24-sdk.tar.xz ] && echo "skipping x86_64 sdk download..." || wget -q -O ./AndroidSDK/swift-5.6-android-x86_64-24-sdk.tar.xz https://github.com/buttaface/swift-android-sdk/releases/download/5.6/swift-5.6-android-x86_64-24-sdk.tar.xz
	@[ -f ./AndroidSDK/swift-5.6-android-armv7-24-sdk.tar.xz ] && echo "skipping armv7 sdk download..." || wget -q -O ./AndroidSDK/swift-5.6-android-armv7-24-sdk.tar.xz https://github.com/buttaface/swift-android-sdk/releases/download/5.6/swift-5.6-android-armv7-24-sdk.tar.xz
	
	@[ -f ./AndroidSDK/android-aarch64.json ] && echo "skipping android-aarch64.json download..." || wget -q -O ./AndroidSDK/android-aarch64.json https://raw.githubusercontent.com/buttaface/swift-android-sdk/main/android-aarch64.json
	@[ -f ./AndroidSDK/android-x86_64.json ] && echo "skipping android-x86_64.json download..." || wget -q -O ./AndroidSDK/android-x86_64.json https://raw.githubusercontent.com/buttaface/swift-android-sdk/main/android-x86_64.json
	@[ -f ./AndroidSDK/android-armv7.json ] && echo "skipping android-armv7.json download..." || wget -q -O ./AndroidSDK/android-armv7.json https://raw.githubusercontent.com/buttaface/swift-android-sdk/main/android-armv7.json

docker: android-ndk android-sdk
	-docker buildx create --name local_builder
	-DOCKER_HOST=tcp://192.168.1.198:2376 docker buildx create --name local_builder --platform linux/amd64 --append
	-docker buildx use local_builder
	-docker buildx inspect --bootstrap
	-docker login
	#docker buildx build --platform linux/amd64,linux/arm64 --push -t kittymac/silkroad .
	docker buildx build --platform linux/amd64 --push -t kittymac/silkroad .

docker-shell:
	docker pull kittymac/silkroad
	docker run --rm -it --entrypoint bash kittymac/silkroad

docker-export: docker
	docker pull kittymac/silkroad
	rm -rf /tmp/jniLibs
	mkdir -p /tmp/jniLibs
	docker run --rm -v /tmp/jniLibs:/jniLibs kittymac/silkroad /bin/bash -lc 'cp -r /root/lib/* /jniLibs/'
	cp -r /tmp/jniLibs/* ./SilkRoadAndroidTest/app/src/main/jniLibs/
	

docker-dev: docker docker-shell
