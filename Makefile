SWIFT_BUILD_FLAGS=--configuration release
GIT_VERSION=$(shell git describe)

build:
	swift build -Xswiftc -enable-library-evolution -v $(SWIFT_BUILD_FLAGS)

update:
	swift package update
	
clean:
	rm -rf .build
	rm -rf ./AndroidNDK
	rm -f ./AndroidSDK/swift-5.9-android-24-sdk.tar.xz

android-ndk:
	mkdir -p ./AndroidNDK
	@[ -f ./AndroidNDK/android-ndk-25c.zip ] && echo "skipping ndk download..." || wget -q -O ./AndroidNDK/android-ndk-25c.zip https://dl.google.com/android/repository/android-ndk-r25c-linux.zip
	
android-sdk:
	# NOTE: need to download manually from https://github.com/buttaface/swift-android-sdk/actions/workflows/sdks.yml
	# The CI puts the latest releases online, and the manual releases will lag behind
	mkdir -p ./AndroidSDK
	@[ -f ./AndroidSDK/swift-5.9-android-24-sdk.tar.xz ] && echo "skipping aarch64 sdk download..." || wget -q -O ./AndroidSDK/swift-5.9-android-24-sdk.tar.xz https://github.com/finagolfin/swift-android-sdk/releases/download/5.9/swift-5.9-android-24-sdk.tar.xz

docker-release: android-ndk android-sdk
	-docker buildx create --name cluster_builder203
	-DOCKER_HOST=ssh://rjbowli@192.168.111.203 docker buildx create --name cluster_builder203 --platform linux/amd64 --append
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
	-docker buildx create --name cluster_builder203
	-DOCKER_HOST=ssh://rjbowli@192.168.111.203 docker buildx create --name cluster_builder203 --platform linux/amd64 --append
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
	
	# Copy any vendored shared libraries we might have
	cp -r ./externalLibs/* ./SilkRoadAndroidTest/app/src/main/jniLibs/
	

docker-test-shell: docker-test
	docker pull --platform linux/amd64 kittymac/silkroadtest
	docker run --rm -it --entrypoint bash kittymac/silkroadtest

