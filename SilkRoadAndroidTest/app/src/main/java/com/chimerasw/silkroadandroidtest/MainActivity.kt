package com.chimerasw.silkroadandroidtest

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.util.Log

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        testSilkRoad()
    }

    fun testSilkRoad() {
        System.loadLibrary("SilkRoadFramework")

        val x = add(40, 2)
        Log.d("TAG", "the value is ${x}")
    }
    external fun add(x: Long, y: Long): Long
}



















