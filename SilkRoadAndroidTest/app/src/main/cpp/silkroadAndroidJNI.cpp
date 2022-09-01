#include <jni.h>
//#include "silkroadAndroidJNI.h"

extern "C" int silkroad_add(int x, int y);

extern "C" JNIEXPORT jlong JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_addLocal(JNIEnv *env, jclass clazz, jlong x, jlong y) {
    //return x + y;
    return silkroad_add(x, y);
}