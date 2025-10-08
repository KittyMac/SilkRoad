SWIFT_BUILD_FLAGS=--configuration release
GIT_VERSION=$(shell git describe)

ANDROID_SDK_HOME=${HOME}/Library/org.swift.swiftpm/swift-sdks/swift-6.2-RELEASE-android-0.1.artifactbundle/swift-android
ANDROID_NDK_HOME=${HOME}/Downloads/android-ndk-r27d "${ANDROID_SDK_HOME}/scripts/setup-android-sdk.sh"

define termux
	# https://packages.termux.dev/apt/termux-main/pool/main/
	rm -rf /tmp/termux
	mkdir -p /tmp/termux
	cp ./AndroidLibs2/$2/$4_$1.deb /tmp/termux/termux.deb
	cd /tmp/termux && ar x termux.deb
	cd /tmp/termux && tar xf data.tar.xz
	
	mkdir -p "${ANDROID_SDK_HOME}/termux"
	rsync -qav /tmp/termux/data/data/com.termux/files/ "${ANDROID_SDK_HOME}/termux/"
	
	cp /tmp/termux/data/data/com.termux/files/usr/lib/$5 ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/$6
	# patchelf --set-rpath '$$ORIGIN' ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/$6
	patchelf --set-soname $6 ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/$6
	
	rm -rf /tmp/termux
endef

define buildSwift62
	
	# clear out the old .so
	rm -f ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/*.so
	
	# termux built dependencies
	@$(call termux,$1,$2,$3,"zlib_1.3.1","libz.so","libzSR.so")
	@$(call termux,$1,$2,$3,"libpng_1.6.50","libpng.so","libpng.so")
	@$(call termux,$1,$2,$3,"leptonica_1.85.0","libleptonica.so","libleptonica.so")
	@$(call termux,$1,$2,$3,"tesseract_5.5.1","libtesseract.so","libtesseract.so")
	@$(call termux,$1,$2,$3,"openssl_1_3.5.0-1","libssl.so.3","libsslSR.so")
	@$(call termux,$1,$2,$3,"openssl_1_3.5.0-1","libcrypto.so.3","libcryptoSR.so")
	
	echo "swiftly run swift build  --configuration=release -Xcc -Oz -Xswiftc -Osize --swift-sdk $1-unknown-linux-android28 +6.2"
	swiftly run swift build  --configuration=release \
		-Xcc -Oz \
		-Xswiftc -Osize \
		-Xswiftc -whole-module-optimization \
		-Xswiftc -gnone \
		-Xcc "-I${ANDROID_SDK_HOME}/termux/usr/include" \
		-Xlinker "-L${ANDROID_SDK_HOME}/termux/usr/lib" \
		--swift-sdk $1-unknown-linux-android28 +6.2
		
	# copy ndk .so
	cp ${ANDROID_SDK_HOME}/swift-resources/usr/lib/swift-$1/android/*.so ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/
	# copy our .so
	cp .build/$1-unknown-linux-android28/release/*.so ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/
	# copy vendored .so
	cp AndroidLibs2/$2/*.so ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/
	
	# remove unnecessary
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libTesting.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libXCTest.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libFoundationXML.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswiftSwiftOnoneSupport.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswift_Differentiation.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswiftDistributed.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswiftRegexBuilder.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswiftObservation.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswift_Volatile.so
	rm ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/lib_Testing_Foundation.so
	
	# strip all .so (only if they have not been stripped previously)
	@find ./SilkRoadAndroidTest/app/src/main/jniLibs/$2 -name '*.so' | \
	while read sofile; do \
		if ${HOME}/Downloads/android-ndk-r27d/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readobj --sections "$$sofile" | grep -q '\.symtab'; then \
				${HOME}/Downloads/android-ndk-r27d/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objcopy --strip-all "$$sofile"; \
		fi \
	done
	
	# manually fix dependencies (perform add-needed after stripping)
	# JSC
	mv ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libjsc.so ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libjscSR.so
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libjscSR.so --set-soname "libjscSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libSilkRoadFramework.so --add-needed "libjscSR.so"
	
	# leptonica
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libSilkRoadFramework.so --add-needed "libleptonica.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libleptonica.so --replace-needed "libpng16.so" "libpng.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libpng.so --replace-needed "libz.so.1" "libzSR.so"
	
	# tesseract
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libtesseract.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	
	# openssl
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libSilkRoadFramework.so --replace-needed "libssl.so.3" "libsslSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libSilkRoadFramework.so --replace-needed "libcrypto.so.3" "libcryptoSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libsslSR.so --replace-needed "libcrypto.so.3" "libcryptoSR.so"
	
	# libc++_shared.so
	mv ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libc++_shared.so ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libc++_sharedSR.so
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libc++_sharedSR.so --set-soname "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libjscSR.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libSilkRoadFramework.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libSilkRoadFramework.so --replace-needed "libz.so.1" "libzSR.so"
	
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/lib_FoundationICU.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswift_Builtin_float.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswift_Concurrency.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswift_math.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswift_RegexParser.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswift_StringProcessing.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswiftAndroid.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswiftCore.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
	patchelf ./SilkRoadAndroidTest/app/src/main/jniLibs/$2/libswiftSynchronization.so --replace-needed "libc++_shared.so" "libc++_sharedSR.so"
endef

build:
	swift build -Xswiftc -enable-library-evolution -v $(SWIFT_BUILD_FLAGS)

update:
	swift package update
	
clean:
	rm -rf .build
	rm -rf ./AndroidNDK

swift62-test:
	# https://github.com/swift-android-sdk/swift-android-sdk/releases/
	@$(call buildSwift62,"aarch64","arm64-v8a","aarch64-linux-android")
	@$(call buildSwift62,"armv7","armeabi-v7a","arm-linux-androideabi")
	@$(call buildSwift62,"x86_64","x86_64","x86_64-linux-android")

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

docker-release:
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

check-alignment:
	export JAVA_HOME=/Applications/Android\ Studio.ladybug.app/Contents/jbr/Contents/Home && cd SilkRoadAndroidTest && ./gradlew clean assembleDebug
	./check_elf_alignment.sh ./SilkRoadAndroidTest/app/build/outputs/apk/debug/app-debug.apk
