SWIFT_BUILD_FLAGS=--configuration release
GIT_VERSION=$(shell git describe)

define termux
	echo "downloading $1..."
	-(cd "AndroidLibs/arm64-v8a/" && curl -f -s -O "https://packages.termux.dev/apt/termux-main/pool/main/$1_aarch64.deb")
	-(cd "AndroidLibs/armeabi-v7a/" && curl -f -s -O "https://packages.termux.dev/apt/termux-main/pool/main/$1_arm.deb")
	-(cd "AndroidLibs/x86_64/" && curl -f -s -O "https://packages.termux.dev/apt/termux-main/pool/main/$1_x86_64.deb")
endef

build:
	swift build -Xswiftc -enable-library-evolution -v $(SWIFT_BUILD_FLAGS)

update:
	swift package update
	
clean:
	rm -rf .build
	rm -rf ./AndroidNDK
	rm -f ./AndroidSDK/swift-5.8-android-24-sdk.tar.xz

libicu:
	# NOTE: use the fork (https://github.com/KittyMac/termux-packages/tree/silkroad) to compile
	# slimmed down versions of libicudata and put them into the AndroidLibs folders
	
	# ./scripts/run-docker.sh ./build-package.sh -f -a arm libicu
	# ./scripts/run-docker.sh ./build-package.sh -f -a aarch64 libicu
	# ./scripts/run-docker.sh ./build-package.sh -f -a x86_64 libicu
	
update-libs:
	# https://central.sonatype.com/artifact/org.webkit/android-jsc
	
	@$(call termux,"liba/libandroid-posix-semaphore/libandroid-posix-semaphore_0.1-3")
	@$(call termux,"liba/libarchive/libarchive_3.7.2")
	@$(call termux,"libb/libbz2/libbz2_1.0.8-6")
	@$(call termux,"libc/libcurl/libcurl_8.6.0-1")
	@$(call termux,"libi/libiconv/libiconv_1.17")
	@$(call termux,"libj/libjpeg-turbo/libjpeg-turbo_3.0.2")
	@$(call termux,"libl/liblzma/liblzma_5.6.0")
	@$(call termux,"libn/libnghttp2/libnghttp2_1.59.0")
	@$(call termux,"libn/libnghttp3/libnghttp3_1.1.0")
	@$(call termux,"libp/libpng/libpng_1.6.43")
	@$(call termux,"libr/libresolv-wrapper/libresolv-wrapper_1.1.7-4")
	@$(call termux,"libs/libssh2/libssh2_1.11.0")
	@$(call termux,"libt/libtiff/libtiff_4.6.0")
	@$(call termux,"libw/libwebp/libwebp_1.3.2")
	@$(call termux,"libx/libxml2/libxml2_2.12.5")
	
	@$(call termux,"g/giflib/giflib_5.2.1-2")
	@$(call termux,"l/leptonica/leptonica_1.84.1")
	@$(call termux,"o/openjpeg/openjpeg_2.5.0-1")
	@$(call termux,"o/openssl/openssl_1:3.2.1-1")
	@$(call termux,"t/tesseract/tesseract_5.3.4")
	@$(call termux,"z/zlib/zlib_1.3.1")
	@$(call termux,"z/zstd/zstd_1.5.5-1")

android-ndk:
	mkdir -p ./AndroidNDK
	@[ -f ./AndroidNDK/android-ndk-25c.zip ] && echo "skipping ndk download..." || wget -q -O ./AndroidNDK/android-ndk-25c.zip https://dl.google.com/android/repository/android-ndk-r25c-linux.zip
	
android-sdk:
	# NOTE: need to download manually from https://github.com/buttaface/swift-android-sdk/actions/workflows/sdks.yml
	# The CI puts the latest releases online, and the manual releases will lag behind
	mkdir -p ./AndroidSDK
	@[ -f ./AndroidSDK/swift-5.8-android-24-sdk.tar.xz ] && echo "skipping aarch64 sdk download..." || wget -q -O ./AndroidSDK/swift-5.8-android-24-sdk.tar.xz https://github.com/finagolfin/swift-android-sdk/releases/download/5.8/swift-5.8-android-24-sdk.tar.xz

docker-release: android-ndk android-sdk
	-DOCKER_HOST=ssh://rjbowli@192.168.111.203 docker buildx create --name cluster_builder203 --platform linux/amd64
	-docker buildx create --name cluster_builder203 --platform linux/arm64 --append
	-docker buildx use cluster_builder203
	-docker buildx inspect --bootstrap
	-docker login
	
	@if echo "$(GIT_VERSION)" | grep -q '-'; then																												\
		echo "BUILDING LATEST";																																	\
		docker buildx build --platform linux/amd64 --push -t kittymac/silkroad:latest . ;																		\
	else																																						\
		echo "BUILDING LATEST AND TAG $(GIT_VERSION)";																											\
		docker buildx build --platform linux/amd64 --push -t kittymac/silkroad:latest -t kittymac/silkroad:$(GIT_VERSION) . ;			    					\
	fi


docker-shell: docker-release
	docker pull --platform linux/amd64 kittymac/silkroad
	docker run --rm -it --entrypoint bash kittymac/silkroad

docker-test: docker-release
	docker pull --platform linux/amd64 kittymac/silkroad:latest
	
	# Build our Swift projects into shared libraries using Docker
	-DOCKER_HOST=ssh://rjbowli@192.168.111.203 docker buildx create --name cluster_builder203 --platform linux/amd64
	-docker buildx create --name cluster_builder203 --platform linux/arm64 --append
	-docker buildx use cluster_builder203
	-docker buildx inspect --bootstrap
	-docker login
	
	swift package resolve
	docker buildx build -f Dockerfile.silkroad --platform linux/amd64 --push -t kittymac/silkroadtest .
	docker pull --platform linux/amd64 kittymac/silkroadtest:latest
	
	# Copy the built shared libraries into our jniLibs folder
	rm -rf /tmp/jniLibs
	mkdir -p /tmp/jniLibs
	docker run --rm -v /tmp/jniLibs:/jniLibs kittymac/silkroadtest /bin/bash -lc 'cp -r /root/lib/* /jniLibs/'
	rm -rf ./SilkRoadAndroidTest/app/src/main/jniLibs/
	mkdir -p ./SilkRoadAndroidTest/app/src/main/jniLibs/
	cp -r /tmp/jniLibs/* ./SilkRoadAndroidTest/app/src/main/jniLibs/
	

docker-test-shell: docker-test
	docker pull --platform linux/amd64 kittymac/silkroadtest
	docker run --rm -it --entrypoint bash kittymac/silkroadtest

