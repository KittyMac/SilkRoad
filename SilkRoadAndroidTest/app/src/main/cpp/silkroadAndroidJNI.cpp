#include <jni.h>

// From callbacksJNI.cpp
extern JNIEnv * GetJniEnv();
extern void function1Callback(void * function1, const char * resultCString);
extern void * retain(jobject obj);

// From libSilkRoadFramework.so
extern "C" int silkroad_add(jlong x, jlong y);
extern "C" const char * silkroad_uppercase(const char * ptr);
extern "C" const char * silkroad_jsonpath(const char * path, const char * json);
extern "C" void silkroad_flynnTest(const char * ptr, void * functionPtr, void * infoPtr);
extern "C" void silkroad_download(const char * ptr, void * functionPtr, void * infoPtr);
extern "C" const char * silkroad_eval(const char * ptr);

// JNI methods
extern "C" JNIEXPORT jlong JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_add(JNIEnv *env,
                                                          jclass clazz,
                                                          jlong x,
                                                          jlong y) {
    return silkroad_add(x, y);
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_uppercase(JNIEnv *env,
                                                                jclass clazz,
                                                                jstring string) {
    const char *jsonCString = env->GetStringUTFChars(string, nullptr);
    jstring result = env->NewStringUTF(silkroad_uppercase(jsonCString));
    env->ReleaseStringUTFChars(string, jsonCString);
    return result;
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_jsonpath(JNIEnv *env,
                                                               jclass clazz,
                                                               jstring pathJString,
                                                               jstring jsonJString) {
    const char *pathCString = env->GetStringUTFChars(pathJString, nullptr);
    const char *jsonCString = env->GetStringUTFChars(jsonJString, nullptr);
    jstring result = env->NewStringUTF(silkroad_jsonpath(pathCString, jsonCString));
    env->ReleaseStringUTFChars(pathJString, pathCString);
    env->ReleaseStringUTFChars(jsonJString, jsonCString);
    return result;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_flynnTest(JNIEnv *env,
                                                                jclass clazz,
                                                                jstring jsString,
                                                                jobject return_callback) {
    const char *cString = env->GetStringUTFChars(jsString, nullptr);
    silkroad_flynnTest(cString, (void *)function1Callback, retain(return_callback));
    env->ReleaseStringUTFChars(jsString, cString);
}

extern "C"
JNIEXPORT jstring JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_eval(JNIEnv *env,
                                                           jclass clazz,
                                                           jstring jsJString) {
    const char *jsCString = env->GetStringUTFChars(jsJString, nullptr);
    jstring result = env->NewStringUTF(silkroad_eval(jsCString));
    env->ReleaseStringUTFChars(jsJString, jsCString);
    return result;

}
extern "C"
JNIEXPORT void JNICALL
Java_com_chimerasw_silkroadandroidtest_MainActivityKt_download(JNIEnv *env, jclass clazz,
                                                               jstring urlJString,
                                                               jobject return_callback) {
    const char *cString = env->GetStringUTFChars(urlJString, nullptr);
    silkroad_download(cString, (void *)function1Callback, retain(return_callback));
    env->ReleaseStringUTFChars(urlJString, cString);
}