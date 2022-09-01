#include <jni.h>

extern "C" int silkroad_add(int x, int y);
extern "C" const char * silkroad_uppercase(const char * ptr);

extern "C" JNIEXPORT jlong JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_add(JNIEnv *env, jclass clazz, jlong x, jlong y) {
    return silkroad_add(x, y);
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_uppercase(JNIEnv *env, jclass clazz,
                                                                jstring string) {
    const char *jsonCString = env->GetStringUTFChars(string, 0);
    jstring result = env->NewStringUTF(silkroad_uppercase(jsonCString));
    env->ReleaseStringUTFChars(string, jsonCString);
    return result;
}