package com.prodapt.pro_dine

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager
import android.os.Bundle

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ensure screenshots are NOT blocked (Clear FLAG_SECURE if it was somehow set)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
