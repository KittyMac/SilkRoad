package com.chimerasw.silkroadandroidtest

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.util.Log

external fun add(x: Long, y: Long): Long
external fun uppercase(string: String): String

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
        val x = add(40, 2)
        Log.d("TAG", "the value is ${x}")

        val hello = uppercase("hello world!")
        Log.d("TAG", "uppercase: ${hello}")
    }
}



















