package co.ichob.ccppflutterplugin

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import androidx.fragment.app.Fragment
import com.ccpp.pgw.sdk.android.callback.APIResponseCallback
import com.ccpp.pgw.sdk.android.core.authenticate.PGWJavaScriptInterface
import com.ccpp.pgw.sdk.android.core.authenticate.PGWWebViewClient
import com.ccpp.pgw.sdk.android.enums.APIResponseCode
import com.ccpp.pgw.sdk.android.model.api.TransactionResultResponse

class WebViewFragment : Fragment() {
    private var mRedirectUrl: String? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (arguments != null) {
            mRedirectUrl = arguments?.getString(ARG_REDIRECT_URL) ?: ""
        }
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        val webView = WebView(activity)
        webView.layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT)
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.webViewClient = PGWWebViewClient()
        webView.addJavascriptInterface(PGWJavaScriptInterface(mAPIResponseCallback),
                PGWJavaScriptInterface.JAVASCRIPT_TRANSACTION_RESULT_KEY)

        webView.loadUrl(mRedirectUrl)
        return webView
    }

    private val mAPIResponseCallback: APIResponseCallback<TransactionResultResponse> = object : APIResponseCallback<TransactionResultResponse> {
        override fun onResponse(response: TransactionResultResponse) {
            if (response.responseCode == APIResponseCode.TransactionCompleted) {
                val invoiceNo = response.invoiceNo
                val result = Intent()
                result.putExtra("invoiceNo", invoiceNo)
                activity?.setResult(Activity.RESULT_OK, result)
                activity?.finish()
            } else {
                //Get error response and display error
                val result = Intent()
                result.putExtra("errorMessage", response.responseDescription)
                activity?.setResult(Activity.RESULT_OK, result)
                activity?.finish()
            }
        }

        override fun onFailure(error: Throwable) {
            //Get error response and display error
            val result = Intent()
            result.putExtra("errorMessage", error.message)
            activity?.setResult(Activity.RESULT_OK, result)
            activity?.finish()
        }
    }

    companion object {
        private const val ARG_REDIRECT_URL = "ARG_REDIRECT_URL"
        
        fun newInstance(redirectUrl: String): WebViewFragment {
            val fragment = WebViewFragment()
            val args = Bundle()
            args.putString(ARG_REDIRECT_URL, redirectUrl)
            fragment.arguments = args
            return fragment
        }
    }
}