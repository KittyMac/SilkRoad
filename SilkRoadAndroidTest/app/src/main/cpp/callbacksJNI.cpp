#include <jni.h>
#include <pthread.h>
#include <android/log.h>
#include <string.h>

// https://stackoverflow.com/questions/30026030/what-is-the-best-way-to-save-jnienv
static JavaVM* g_vm = nullptr;

jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    JNIEnv* env;
    if (vm->GetEnv((void**) &env, JNI_VERSION_1_6) != JNI_OK)
        return -1;
    g_vm = vm;
    return JNI_VERSION_1_6;
}

/**
 * Get a JNIEnv* valid for this thread, regardless of whether
 * we're on a native thread or a Java thread.
 * If the calling thread is not currently attached to the JVM
 * it will be attached, and then automatically detached when the
 * thread is destroyed.
 */

void DeferThreadDetach(JNIEnv *env) {
    static pthread_key_t thread_key;

    // Set up a Thread Specific Data key, and a callback that
    // will be executed when a thread is destroyed.
    // This is only done once, across all threads, and the value
    // associated with the key for any given thread will initially
    // be NULL.
    static auto run_once = [] {
        const auto err = pthread_key_create(&thread_key, [] (void *ts_env) {

            __android_log_write(ANDROID_LOG_ERROR, "TAG", "BEFORE DetachCurrentThread!!!!");

            if (ts_env) {
                __android_log_write(ANDROID_LOG_ERROR, "TAG", "BEFORE DetachCurrentThread");
                g_vm->DetachCurrentThread();
                __android_log_write(ANDROID_LOG_ERROR, "TAG", "AFTER DetachCurrentThread");
            }
        });
        if (err) {
            // Failed to create TSD key. Throw an exception if you want to.
            __android_log_write(ANDROID_LOG_ERROR, "TAG", "Failed to create TSD key");
        }
        return 0;
    }();

    // For the callback to actually be executed when a thread exits
    // we need to associate a non-NULL value with the key on that thread.
    // We can use the JNIEnv* as that value.
    const auto ts_env = pthread_getspecific(thread_key);
    if (!ts_env) {
        if (pthread_setspecific(thread_key, env)) {
            // Failed to set thread-specific value for key. Throw an exception if you want to.
            __android_log_write(ANDROID_LOG_ERROR, "TAG", "Failed to set thread-specific value for key");
        }
    }
}

JNIEnv *GetJniEnv() {
    JNIEnv *env = nullptr;
    // We still call GetEnv first to detect if the thread already
    // is attached. This is done to avoid setting up a DetachCurrentThread
    // call on a Java thread.

    // g_vm is a global.
    auto get_env_result = g_vm->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (get_env_result == JNI_EDETACHED) {
        if (g_vm->AttachCurrentThread(&env, nullptr) == JNI_OK) {
            DeferThreadDetach(env);
        } else {
            // Failed to attach thread. Throw an exception if you want to.
            __android_log_write(ANDROID_LOG_ERROR, "TAG", "Failed to attach thread");
        }
    } else if (get_env_result == JNI_EVERSION) {
        // Unsupported JNI version. Throw an exception if you want to.
        __android_log_write(ANDROID_LOG_ERROR, "TAG", "Unsupported JNI version");
    }
    return env;
}

jstring utf8ToJString(const char * utf8String) {
    // Note: Java uses "Modified" UTF8, which is not directly compatible with the utf8
    // we get from Swift. This method handle the conversion correctly.
    // https://stackoverflow.com/questions/60722231/jni-detected-error-in-application-input-is-not-valid-modified-utf-8-illegal-st
    JNIEnv *env = GetJniEnv();
    jobject bb = env->NewDirectByteBuffer((void *)utf8String, strlen(utf8String));

    jclass cls_Charset = env->FindClass("java/nio/charset/Charset");
    jmethodID mid_Charset_forName = env->GetStaticMethodID(cls_Charset, "forName", "(Ljava/lang/String;)Ljava/nio/charset/Charset;");
    jobject charset = env->CallStaticObjectMethod(cls_Charset, mid_Charset_forName, env->NewStringUTF("UTF-8"));

    jmethodID mid_Charset_decode = env->GetMethodID(cls_Charset, "decode", "(Ljava/nio/ByteBuffer;)Ljava/nio/CharBuffer;");
    jobject cb = env->CallObjectMethod(charset, mid_Charset_decode, bb);
    env->DeleteLocalRef(bb);

    jclass cls_CharBuffer = env->FindClass("java/nio/CharBuffer");
    jmethodID mid_CharBuffer_toString = env->GetMethodID(cls_CharBuffer, "toString", "()Ljava/lang/String;");
    return (jstring)env->CallObjectMethod(cb, mid_CharBuffer_toString);
}

void function1Invoke(jobject function1, jstring argument) {
    JNIEnv *env = GetJniEnv();
    jclass classFunction1 = env->GetObjectClass(function1);
    jmethodID invoke = env->GetMethodID(classFunction1, "invoke", "(Ljava/lang/String;)V");
    env->CallVoidMethod(function1, invoke, argument);
    env->DeleteGlobalRef(function1);
}

void function1Callback(void * function1, const char * resultCString) {
    JNIEnv *env = GetJniEnv();
    jstring resultJString = utf8ToJString(resultCString);
    function1Invoke((jobject) function1, resultJString);
    env->ReleaseStringUTFChars(resultJString, resultCString);
}

void * retain(jobject obj) {
    JNIEnv * env = GetJniEnv();
    return env->NewGlobalRef(obj);
}

void release(jobject obj) {
    JNIEnv * env = GetJniEnv();
    env->DeleteGlobalRef(obj);
}