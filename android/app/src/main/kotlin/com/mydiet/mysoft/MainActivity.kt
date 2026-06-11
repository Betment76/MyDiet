package com.mydiet.mysoft

import android.graphics.Color
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.setBackgroundColor(Color.WHITE)
    }

    override fun onResume() {
        super.onResume()
        window.decorView.setBackgroundColor(Color.WHITE)
        window.decorView.requestLayout()
        window.decorView.invalidate()
    }
}
