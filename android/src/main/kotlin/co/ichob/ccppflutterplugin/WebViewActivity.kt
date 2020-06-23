package co.ichob.ccppflutterplugin

import android.os.Bundle
import android.src.main.kotlin.co.ichob.ccppflutterplugin.WebViewFragment
import androidx.appcompat.app.AppCompatActivity

class WebViewActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        setTheme(android.R.style.Theme_DeviceDefault_Light_NoActionBar)
        super.onCreate(savedInstanceState)
        val i = intent
        val redirect = i.getStringExtra("redirect")
        val fragment: WebViewFragment = WebViewFragment.newInstance(redirect)
        supportFragmentManager.beginTransaction()
                .add(android.R.id.content, fragment, "")
                .commit()
    }
}