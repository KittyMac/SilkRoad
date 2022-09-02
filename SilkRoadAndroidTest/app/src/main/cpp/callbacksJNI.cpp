#include <jni.h>
#include <pthread.h>

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
            if (ts_env) {
                g_vm->DetachCurrentThread();
            }
        });
        if (err) {
            // Failed to create TSD key. Throw an exception if you want to.
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
        }
    }
}

JNIEnv * GetJniEnv() {
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
        }
    } else if (get_env_result == JNI_EVERSION) {
        // Unsupported JNI version. Throw an exception if you want to.
    }
    return env;
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
    jstring resultJString = env->NewStringUTF(resultCString);
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