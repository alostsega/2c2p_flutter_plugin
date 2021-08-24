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
                let isSandbox = args["isSandBox"] as! Bool
                let apiEnv = isSandbox ? APIEnvironment.Sandbox : APIEnvironment.Production
                
                let params: PGWSDKParams = PGWSDKParamsBuilder(apiEnvironment: apiEnv).build()
                
                PGWSDK.initialize(params: params)
                result(nil)
            case "paymentWithCreditCard":
                let args = call.arguments as! Dictionary<String, Any>
                let paymentToken = args["paymentToken"] as! String
                let ccNumber = args["ccNumber"] as! String
                let expMonth = args["expMonth"] as! Int
                let expYear = args["expYear"] as! Int
                let securityCode = args["securityCode"] as! String
                let storeCard = args["storeCard"] as! Bool
                paymentWithCreditCard(paymentToken,
                                      ccNumber: ccNumber,
                                      expMonth: expMonth,
                                      expYear: expYear,
                                      securityCode: securityCode,
                                      storeCard: storeCard)
            case "paymentWithToken":
                let args = call.arguments as! Dictionary<String, Any>
                let paymentToken = args["paymentToken"] as! String
                let cardToken = args["cardToken"] as! String
                let securityCode = args["securityCode"] as! String
                paymentWithToken(paymentToken,
                                 cardToken: cardToken,
                                 securityCode: securityCode)
            default:
                result(FlutterMethodNotImplemented)
        }
    }
        
    fileprivate func paymentWithCreditCard(_ paymentToken: String, ccNumber: String, expMonth: Int, expYear: Int, securityCode: String, storeCard: Bool) {
        //Construct credit card request
        let paymentCode: PaymentCode = PaymentCode(channelCode: "CC")
          
        let paymentRequest: PaymentRequest = CardPaymentBuilder(paymentCode: paymentCode, ccNumber)
                                             .expiryMonth(expMonth)
                                             .expiryYear(expYear)
                                             .securityCode(securityCode)
                                             .tokenize(storeCard)
                                             .build()
    
        //Construct transaction request
        let transactionResultRequest: TransactionResultRequest = TransactionResultRequestBuilder(paymentToken: paymentToken)
                                                                 .with(paymentRequest)
                                                                 .build()
    
        //Execute payment request
        proceedTransaction(transactionResultRequest: transactionResultRequest)
    }
    
    fileprivate func paymentWithToken(_ paymentToken: String, cardToken: String, securityCode: String) {
        let paymentCode: PaymentCode = PaymentCode(channelCode: "CC")
           
        let paymentRequest: PaymentRequest = CardTokenPaymentBuilder(paymentCode: paymentCode, cardToken)
                                             .securityCode(securityCode)
                                             .build()
        
        //Construct transaction request
        let transactionResultRequest: TransactionResultRequest = TransactionResultRequestBuilder(paymentToken: paymentToken)
                                                                 .with(paymentRequest)
                                                                 .build()
        
        //Execute payment request
        proceedTransaction(transactionResultRequest: transactionResultRequest)
    }
    
    fileprivate func proceedTransaction(transactionResultRequest: TransactionResultRequest) {
        
        PGWSDK.shared.proceedTransaction(transactionResultRequest: transactionResultRequest,
                                         { (response: TransactionResultResponse) in
        //For 3DS
        if response.responseCode == APIResponseCode.TransactionAuthenticateRedirect
            || response.responseCode == APIResponseCode.TransactionAuthenticateFullRedirect {
            
            guard  let redirectUrl: String = response.data else { return }
            
            let webView = WKWebViewController()
            webView.redirectUrl = redirectUrl
            webView.transaction3dsDelegate = self
            
            let nav = UINavigationController.init(rootViewController: webView)
            nav.modalPresentationStyle = .fullScreen
            self.viewController?.present(nav, animated: true, completion: nil)
          
        } else if response.responseCode == APIResponseCode.TransactionCompleted {
            //Inquiry payment result by using transaction id.
            let invoiceNo = response.invoiceNo
            let response = ["invoiceNo": invoiceNo]
            self.result!(response)
        } else {
            //Get error response and display error
            let response = ["errorMessage": response.responseDescription]
            self.result!(response)
        }
                                        
        }) { (error:NSError) in
            //Get error response and display error
            let response = ["errorMessage": error.description]
            self.result!(response)
        }
    }
    
    func onTransactionResult(_ invoiceNo: String?, _ errorMessage: String?) {
        if(invoiceNo != nil) {
            let response = ["invoiceNo": invoiceNo]
            self.result!(response)
        }
        else{
            let response = ["errorMessage": errorMessage]
            self.result!(response)
        }
    }
}

//For WKWebView implementation
class WKWebViewController: UIViewController {
    var webView:WKWebView!
    var pgwWebViewDelegate: PGWWebViewNavigationDelegate!
    var redirectUrl: String?
    var transaction3dsDelegate: Transaction3DSDelegate!
  
    override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    }

    @objc
    func cancel(sender: UIBarButtonItem){
        self.dismiss(animated: true, completion: nil)
        self.transaction3dsDelegate.onTransactionResult(nil, "Canceled")
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

    func transactionResultCallback() -> PGWWebViewNavigationDelegate {
        self.pgwWebViewDelegate = PGWWebViewNavigationDelegate { [weak self] paymentToken in
            guard let self = self else {return}
            self.requestPGWStatus(paymentToken: paymentToken)
        }
        
        return self.pgwWebViewDelegate
    }

    private func requestPGWStatus(paymentToken: String) {
        let transactionStatusRequest = TransactionStatusRequest(paymentToken: paymentToken)
        transactionStatusRequest.additionalInfo = true

        PGWSDK.shared.transactionStatus(transactionStatusRequest: transactionStatusRequest) { [weak self] response in
            guard let self = self else {return}
            if response.responseCode == APIResponseCode.TransactionCompleted {
                //Inquiry payment result by using invoice no.
                let invoiceNo:String = response.invoiceNo
                self.transaction3dsDelegate.onTransactionResult(invoiceNo, nil)
                self.dismiss(animated: true, completion: nil)
            } else {
                //Get error response and display error
                self.transaction3dsDelegate.onTransactionResult(nil, response.responseDescription!)
                self.dismiss(animated: true, completion: nil)
            }
        } _: { [weak self] error in
            guard let self = self else {return}
            self.transaction3dsDelegate.onTransactionResult(nil, error.description)
            self.dismiss(animated: true, completion: nil)
        }
    }
}

protocol Transaction3DSDelegate{
  func onTransactionResult(_ invoiceNo: String?, _ errorMessage: String?)
}
