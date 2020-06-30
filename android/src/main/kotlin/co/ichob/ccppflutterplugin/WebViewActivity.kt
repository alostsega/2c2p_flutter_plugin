package co.ichob.ccppflutterplugin

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.MenuItem
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.Toolbar

class WebViewActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_web_view)

        initToolbar()
        initFragment()
    }

    override fun onBackPressed() {
        val result = Intent()
        result.putExtra("errorMessage", "Canceled")
        setResult(Activity.RESULT_OK, result)
        finish()
    }

    private fun initToolbar() {
        val toolbar = findViewById<Toolbar>(R.id.toolbar)
        setSupportActionBar(toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.setDisplayShowHomeEnabled(true)
        supportActionBar?.setDisplayShowTitleEnabled(false)
    }

    private fun initFragment() {
        val redirect = intent.getStringExtra("redirect")
        val fragment: WebViewFragment = WebViewFragment.newInstance(redirect)
        supportFragmentManager.beginTransaction()
                .add(R.id.content, fragment, "")
                .commit()
    }

    override fun onOptionsItemSelected(item: MenuItem?): Boolean {
        if (item?.itemId == android.R.id.home) {
            onBackPressed()
        }
        return super.onOptionsItemSelected(item)
    }
}