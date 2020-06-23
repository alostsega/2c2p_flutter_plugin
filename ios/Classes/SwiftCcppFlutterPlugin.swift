import Flutter
import UIKit
import WebKit
import PGW

public class SwiftCcppFlutterPlugin: NSObject, FlutterPlugin, Transaction3DSDelegate {
    fileprivate var result: FlutterResult?
    fileprivate var viewController: UIViewController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "co.ichob/ccpp", binaryMessenger: registrar.messenger())
        let vc = UIApplication.shared.delegate?.window??.rootViewController
        let instance = SwiftCcppFlutterPlugin(viewController: vc)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public init(viewController: UIViewController?) {
      self.viewController = viewController
      super.init()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        switch(call.method){
            case "initialize":
                let args = call.arguments as! Dictionary<String, Any>
                let merchantId = args["merchantId"] as! String
                let isSandbox = args["isSandBox"] as! Bool
                let apiEnv = isSandbox ? APIEnvironment.SANDBOX : APIEnvironment.PRODUCTION
                PGWSDK.builder()
                    .merchantID(merchantId)
                    .apiEnvironment(apiEnv)
                    .initialize();
                result("initialize success")
            case "paymentWithCreditCard":
                let args = call.arguments as! Dictionary<String, Any>
                let paymentToken = args["paymentToken"] as! String
                let ccNumber = args["ccNumber"] as! String
                let expMonth = args["expMonth"] as! Int
                let expYear = args["expYear"] as! Int
                let cvv = args["cvv"] as! String
                let storeCard = args["storeCard"] as! Bool
                paymentWithCreditCard(paymentToken,
                                      ccNumber: ccNumber,
                                      expMonth: expMonth,
                                      expYear: expYear,
                                      cvv: cvv,
                                      storeCard: storeCard)
            case "paymentWithToken":
                let args = call.arguments as! Dictionary<String, Any>
                let paymentToken = args["paymentToken"] as! String
                let cardToken = args["cardToken"] as! String
                let cvv = args["cvv"] as! String
                paymentWithToken(paymentToken,
                                 cardToken: cardToken,
                                 cvv: cvv)
            default:
                result(FlutterMethodNotImplemented)
        }
    }
        
    fileprivate func paymentWithCreditCard(_ paymentToken: String, ccNumber: String, expMonth: Int, expYear: Int, cvv: String, storeCard: Bool) {
        //Construct credit card request
        let creditCardPayment = CreditCardPaymentBuilder(pan: ccNumber)
            .expiryMonth(expMonth)
            .expiryYear(expYear)
            .securityCode(cvv)
            .storeCard(storeCard)
            .build()
    
        //Construct transaction request
        let transactionRequest:TransactionRequest = TransactionRequestBuilder(paymentToken: paymentToken)
            .withCreditCardPayment(creditCardPayment)
            .build()
    
        //Execute payment request
        proceedTransaction(transactionRequest: transactionRequest)
    }
    
    fileprivate func paymentWithToken(_ paymentToken: String, cardToken: String, cvv: String) {
        let tokenPayment = CardTokenPaymentBuilder(cardToken: cardToken)
            .securityCode(cvv)
            .build()
        let transactionRequest:TransactionRequest = TransactionRequestBuilder(paymentToken: paymentToken)
            .withCreditCardPayment(tokenPayment)
            .build()
        
        //Execute payment request
        proceedTransaction(transactionRequest: transactionRequest)
    }
    
    fileprivate func proceedTransaction(transactionRequest: TransactionRequest) {
        
        PGWSDK.shared.proceedTransaction(transactionRequest: transactionRequest,
                                       success: { (response:TransactionResultResponse) in
        //For 3DS
        if response.responseCode == APIResponseCode.TRANSACTION_AUTHENTICATE {
          let redirectUrl:String = response.redirectUrl!
          let webView = WKWebViewController()
          webView.redirectUrl = redirectUrl
          webView.transaction3dsDelegate = self
          let nav = UINavigationController.init(rootViewController: webView)
          self.viewController?.present(nav, animated: true, completion: nil)
          
        } else if response.responseCode == APIResponseCode.TRANSACTION_COMPLETED {
          //Inquiry payment result by using transaction id.
          let transactionID:String = response.transactionID!
          self.result!(transactionID)
          
        } else {
          //Get error response and display error
          self.result!("ERROR " + response.responseDescription!)
          
        }
                                        
        }) { (error:NSError) in
            //Get error response and display error
          self.result!("ERROR " + error.description)
        }
    }
    
    func onTransactionResult(_ transactionId: String?, _ errorMessage: String?) {
        if(transactionId != nil){
          self.result!(transactionId)
        }
        else{
          self.result!("ERROR " + errorMessage!)
        }
    }
}

//For WKWebView implementation
class WKWebViewController: UIViewController {
    var webView:WKWebView!
    var pgwWebViewDelegate:PGWWKWebViewDelegate!
    var redirectUrl:String?
    var transaction3dsDelegate: Transaction3DSDelegate!
  
    override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    }

    @objc
    func cancel(sender: UIBarButtonItem){
        self.dismiss(animated: true, completion: nil)
        self.transaction3dsDelegate.onTransactionResult(nil, "Cancelled")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(sender:)))
        self.navigationItem.leftBarButtonItem = cancelButton

        //Authentication handling for 3DS payment
        let requestUrl:URL = URL.init(string: self.redirectUrl!)!
        let request:URLRequest = URLRequest.init(url: requestUrl)

        let webConfiguration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: UIScreen.main.bounds, configuration: webConfiguration)
        self.webView.navigationDelegate = self.transactionResultCallback()
        self.webView.load(request)

        self.view.addSubview(self.webView)
    }

    func transactionResultCallback() -> PGWWKWebViewDelegate {
        self.pgwWebViewDelegate = PGWWKWebViewDelegate(success: { (response: TransactionResultResponse) in
            if response.responseCode == APIResponseCode.TRANSACTION_COMPLETED {
                //Inquiry payment result by using transaction id.
                let transactionID:String = response.transactionID!
                self.transaction3dsDelegate.onTransactionResult(transactionID, nil)
            } else {
                //Get error response and display error
                self.transaction3dsDelegate.onTransactionResult(nil, response.responseDescription!)
            }
        }, failure: { (error: NSError) in
            //Get error response and display error
            self.transaction3dsDelegate.onTransactionResult(nil, error.description)
        })
        return self.pgwWebViewDelegate
    }
}

protocol Transaction3DSDelegate{
  func onTransactionResult(_ transactionId: String?, _ errorMessage: String?)
}
