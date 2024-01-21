package com.chimerasw.silkroadandroidtest

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.util.Log


external fun setup(tmpPath: String)
external fun add(x: Long, y: Long): Long
external fun uppercase(string: String): String
external fun jsonpath(path: String, json: String): String
external fun flynnTest(tolower: String, returnCallback: (String) -> Unit)
external fun eval(javascript: String): String
external fun download(url: String, returnCallback: (String) -> Unit)
external fun ocr()

class MainActivity : AppCompatActivity() {
    companion object {
        init {
            System.loadLibrary("icuuc")
            System.loadLibrary("icui18n")
            System.loadLibrary("SilkRoadFramework")
            System.loadLibrary("silkroadAndroidJNI")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        testSilkRoad()
    }

    fun testSilkRoad() {
        setup(getApplicationContext().getCacheDir().getPath())

        val x = add(40, 2)
        Log.d("TAG", "the value is ${x}")

        val hello = uppercase("hello world!")
        Log.d("TAG", "uppercase: ${hello}")

        val results = jsonpath("$[3,6,-2]", "[0,1,2,3,4,5,6,7,8,9]")
        Log.d("TAG", "jsonpath: ${results}")

        flynnTest("HELLO WORLD 1") {
            Log.d("TAG", "flynnResult: ${it}")
        }

        flynnTest("HELLO WORLD 2") {
            Log.d("TAG", "flynnResult: ${it}")
        }

        flynnTest("HELLO WORLD 3") {
            Log.d("TAG", "flynnResult: ${it}")
        }

        val jsResult = eval("""
            function f(x,y) { return x + y; }
            f(2, 42);
        """)
        Log.d("TAG", "javascript: ${jsResult}")

        download("https://www.google.com/") {
            Log.d("TAG", "download: ${it}")
        }

        ocr()
        Log.d("TAG", "ocr")
    }
}



















