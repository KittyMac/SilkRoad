cmake_minimum_required(VERSION 3.4.1)

set(jniLibs_DIR ${CMAKE_SOURCE_DIR}/../jniLibs)

add_library(silkroadAndroidJNI SHARED silkroadAndroidJNI.cpp callbacksJNI.cpp)

find_library(log-lib  log)

# Include libraries needed for silkroad lib
target_link_libraries(
        silkroadAndroidJNI
        android
        ${log-lib}
        "-lSilkRoadFramework -L${jniLibs_DIR}/${ANDROID_ABI}/ -Wl,--build-id,-z,max-page-size=16384"
        )
