package com.chimerasw.silkroadandroidtest

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        testSilkRoad()
    }

    fun testSilkRoad() {
        System.loadLibrary("Foundation")
    }
}