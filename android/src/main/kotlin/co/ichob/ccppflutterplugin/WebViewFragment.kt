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
import com.ccpp.pgw.sdk.android.core.PGWSDK
import com.ccpp.pgw.sdk.android.core.authenticate.PGWWebViewClient
import com.ccpp.pgw.sdk.android.enums.APIResponseCode
import com.ccpp.pgw.sdk.android.model.api.TransactionStatusRequest
import com.ccpp.pgw.sdk.android.model.api.TransactionStatusResponse

class WebViewFragment : Fragment() {
    private var mRedirectUrl: String = "https://www.chomchob.com"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (arguments != null) {
            mRedirectUrl = arguments?.getString(ARG_REDIRECT_URL) ?: ""
        }
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        val webView = WebView(requireContext())
        webView.layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT)

        with(webView) {
            //Optional
            settings.builtInZoomControls = true;
            settings.setSupportZoom(true)
            settings.loadWithOverviewMode = true;
            settings.useWideViewPort = true;
            settings.cacheMode = android.webkit.WebSettings.LOAD_NO_CACHE;

            //Require
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
        };

        webView.webViewClient = PGWWebViewClient({ paymentToken ->
            paymentToken?.let {
                inquiryTransactionStatus(it)
            }
        }, null)
        webView.loadUrl(mRedirectUrl)
        return webView
    }

    private fun inquiryTransactionStatus(paymentToken: String) {
        val transactionStatusRequest = TransactionStatusRequest(paymentToken)
        transactionStatusRequest.setAdditionalInfo(true)
        PGWSDK.getInstance().transactionStatus(
                transactionStatusRequest,
                object : APIResponseCallback<TransactionStatusResponse> {
                    override fun onResponse(response: TransactionStatusResponse) {
                        when(response.responseCode) {
                            APIResponseCode.TransactionNotFound, APIResponseCode.TransactionCompleted -> {
                                //Read transaction status inquiry response.
                                val data = Intent()
                                data.putExtra("invoiceNo", response.invoiceNo)
                                activity?.setResult(Activity.RESULT_OK, data)
                                activity?.finish()
                            }
                            else -> {
                                //Get error response and display error.
                                val data = Intent()
                                data.putExtra("errorMessage", response.responseDescription)
                                activity?.setResult(Activity.RESULT_OK, data)
                                activity?.finish()
                            }
                        }
                    }

                    override fun onFailure(error: Throwable) {
                        //Get error response and display error.
                        val data = Intent()
                        data.putExtra("errorMessage", error.message)
                        activity?.setResult(Activity.RESULT_OK, data)
                        activity?.finish()
                    }
                }
        )
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