//
//  ViewController.swift
//  FDAppleIpg
//
//  
// 
//

import UIKit
import PassKit
import CommonCrypto

extension Date {
    func toMillis() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

class ViewController: UIViewController, PKPaymentAuthorizationViewControllerDelegate {
    
//All the variables required for the Apple Pay Payment Processing.
    
    var amt:String = " "
    var mchtId:String = " "
    var transType:String = "WalletPreAuthTransaction"
    var transactionId = " "
    var status = " "
    var walletType = "EncryptedApplePayWalletPaymentMethod";
    var currency = "USD";
    var paymentRequest = PKPaymentRequest()
    var payload = " "
    let alert = UIAlertController(title: "Transaction Result", message: "", preferredStyle: .alert)
    let okAction: UIAlertAction = UIAlertAction(title:"OK", style: .default, handler: {(action: UIAlertAction) -> Void in
    })
    var base64:String = " "
    var resString:String = " "
    
    
//Hmac variables
    
    var timestamp = String(Date().toMillis())
    var signature:String = " "
    
//Configuration Details required for the remote connection
    
    var env:String = "CERT"
    var apiKey:String = "First data provided api key"
    var apiSecret:String = "First data provided api secret"
    var url:String = "https://cert.api.firstdata.com/gateway/v2/payments"
    
    
   

//The outlets to the components in the View.l
    @IBOutlet weak var merchant_id: UITextField!
    @IBOutlet weak var amount: UITextField!
    @IBOutlet weak var segControl: UISegmentedControl!
    
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func alertControllerBackgroundTapped()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func dismissOnTapOutside(){
          self.dismiss(animated: true, completion: nil)
       }
    


//Capture the mercchant id from the user.
    @IBAction func getMerchantId(_ sender: Any) {
        mchtId = merchant_id.text!
        print(mchtId)
    }
    
//Capture the Amount from the user.
    
    @IBAction func getAmt(_ sender: Any) {
        amt = amount.text!
        print(amt)
    }
//Caputre the transaction type (PreAuth/Sale)
    @IBAction func tyepeSelect(_ sender: Any) {
        let getIdx = segControl.selectedSegmentIndex;
        switch (getIdx) {
        case 0:
            amt = amount.text!
            print(amt)
            transType = "WalletPreAuthTransaction"
            print(transType)
        case 1:
            amt = amount.text!
            print(amt)
            transType = "WalletSaleTransaction"
            print(transType)
        default:
            print("Enter the correct type")
        }
    }
    
//Authorize Apple pay after clicking the apple pay button.
   
    @IBAction func applePayBtnTapped(_ sender: Any) {
        amt = amount.text!
        print(amt)
        let paymentNetworks = [PKPaymentNetwork.amex, .masterCard, .visa,.discover]
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetworks)
        {
            paymentRequest.currencyCode = "USD"
            paymentRequest.countryCode = "US"
            paymentRequest.merchantIdentifier = mchtId
            paymentRequest.supportedNetworks = paymentNetworks
            paymentRequest.merchantCapabilities = .capability3DS
            paymentRequest.requiredShippingAddressFields = .all
            paymentRequest.paymentSummaryItems = itemsToSell(shipping: Double(amt)!)
            let appString = "RefCode:12345; TxID:34234089240982304823094823432"
            paymentRequest.applicationData = Data(appString.utf8)
            
             base64 = paymentRequest.applicationData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            //print(base64)
            
            
            let appStr = String(decoding: paymentRequest.applicationData!, as: UTF8.self)
            print(appStr)
            
            let sameDayShipping = PKShippingMethod(label: "Same Day", amount: 0.00)
            sameDayShipping.detail = "Items shipped in the same day"
            sameDayShipping.identifier = "sameDayShipping"
            let twoDayShipping = PKShippingMethod(label: "twoDay", amount: 0.00)
            twoDayShipping.detail = "Items will be shipped in two days"
            twoDayShipping.identifier = "TwoDayShip"
            let freeShipping = PKShippingMethod(label: "freeShiping", amount:0.00)
            freeShipping.detail = "Free shipping"
            freeShipping.identifier = "FreeShip"
            
            paymentRequest.shippingMethods = [sameDayShipping,twoDayShipping,freeShipping]
            let applePayVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
            applePayVC?.delegate = self
            self.present(applePayVC!, animated: true, completion: nil)
            }
        else
        {
            print("Device cannot make Apple Pay payments.")
           // self.alert.message = "Device cannot make Apple Pay payments."
           // self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func itemsToSell(shipping: Double)->[PKPaymentSummaryItem]{
        let TShirt = PKPaymentSummaryItem(label: "TShirt", amount: NSDecimalNumber(string:"\(amt)"))
        let discount = PKPaymentSummaryItem(label: "dicount", amount: 0.00)
        let shipping = PKPaymentSummaryItem(label: "shipping", amount: 0.00)
        let totalAmt = TShirt.amount.adding(discount.amount).adding(shipping.amount)
        let totalPrice = PKPaymentSummaryItem(label: "ABC", amount: totalAmt)
        return [TShirt,discount,shipping,totalPrice]
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        
        struct encryptedHeader: Decodable {
               let applicationData: String
               let ephemeralPublicKey: String
               let publicKeyHash: String
               let transactionId: String
               
               init(jsonHead:[String:Any]){
                   applicationData = jsonHead["applicationData"] as? String ?? " "
                   ephemeralPublicKey = jsonHead["ephemeralPublicKey"] as? String ?? " "
                   publicKeyHash = jsonHead["publicKeyHash"] as? String ?? " "
                   transactionId = jsonHead["transactionId"] as?String ?? " "
               }
           }
           
           
           struct encryptedPayload: Decodable {
               
               let data: String
               let signature: String
               let version: String
               let header: encryptedHeader
               
              init(jsonEncBody:[String:Any]){
                   data = jsonEncBody["data"] as? String ?? " "
                   header = (jsonEncBody["header"]as? encryptedHeader ?? nil)!
                   version = jsonEncBody["version"] as? String ?? " "
                   signature = jsonEncBody["signature"] as? String ?? " "
                  
               }
               
           
           }
        let jsonBody = payment.token.paymentData
       
        /*Tests for apple pay Payloads*/
        // print("jsonBody = \(jsonBody)")
        //let str = String(decoding:jsonBody, as: UTF8.self)
        
        //let decryptedPaymentData:NSString! = NSString(data: jsonBody, encoding: String.Encoding.utf8.rawValue)*/
       // print(str)
        
        do{
        let encry = try JSONDecoder().decode(encryptedPayload.self, from: jsonBody)
        let json : [String:Any] =
            ["requestType":transType,"walletPaymentMethod":["walletType":"EncryptedApplePayWalletPaymentMethod","encryptedApplePay":["version":encry.version,"applicationData":base64,"header":["applicationDataHash":encry.header.applicationData,"ephemeralPublicKey":encry.header.ephemeralPublicKey,"publicKeyHash":encry.header.publicKeyHash,"transactionId":encry.header.transactionId],"signature":encry.signature,"data":encry.data,"merchantId":mchtId]],"transactionAmount":["total":amt,"currency":"USD"]]
               
        
       
        do{
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        payload = String(decoding: jsonData, as: UTF8.self)
        print(payload)
            
        let uuid: CFUUID = CFUUIDCreate(nil)
               let nonce: CFString = CFUUIDCreateString(nil, uuid)
               //Remove this swift will manage the memory managment.This line is causing crash
                print("createdNonce:\(nonce)")
               
               //HMAC calculation:
                   
               let msg = apiKey+(nonce as String)+timestamp+payload
               if let msgData = msg.data(using: .utf8)
               {
                   if let apiSecData = apiSecret.data(using: .utf8){
                       let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
                       let digestBytes = UnsafeMutablePointer<UInt8>.allocate(capacity:digestLength)
                        
                       CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), [UInt8](apiSecData), apiSecData.count, [UInt8](msgData), msgData.count, digestBytes)
                        
                       //base64 output
                       let hmacData = Data(bytes: digestBytes, count: digestLength)
                       signature = hmacData.base64EncodedString()
                       //print("The HMAC signature in base64 is " + signature)
                   }
                   
               }
            
                     /*Payload formation for IPG Rest API*/
            var request = URLRequest(url:URL(string: url)!)
            request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
            request.addValue((nonce as String), forHTTPHeaderField: "Client-Request-Id")
            request.addValue(timestamp, forHTTPHeaderField: "Timestamp")
            request.addValue(signature, forHTTPHeaderField: "Message-Signature")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            request.httpBody = jsonData
            
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                 
                if let resData = data{
                    do{
                        
                        self.definesPresentationContext = true
                        let res = try JSONSerialization.jsonObject(with: resData, options:[])
                        self.resString = "\(res)"
                        print(self.resString)
                        self.present(self.alert, animated: true){
                            self.alert.view.superview?.isUserInteractionEnabled = true
                            self.alert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.alertControllerBackgroundTapped)))
                        }
                    } catch {print(error)}
                }
                
            }.resume()
            
        }catch{print(error)}
        
        }catch{print("error:")}
        
       
        /*
        let status = PKPaymentAuthorizationStatus(rawValue: 0)!
        self.transactionId = payment.token.transactionIdentifier
        switch status.rawValue {
        case 0:
            self.status = "approved"
        default:
            self.status = "failed"
        }*/
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

           //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
           //tap.cancelsTouchesInView = false

         view.addGestureRecognizer(tap)
        
    }
    
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didSelect shippingMethod: PKShippingMethod, completion: @escaping (PKPaymentAuthorizationStatus, [PKPaymentSummaryItem]) -> Void) {
        completion(.success,itemsToSell(shipping: Double(truncating: shippingMethod.amount)))
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
        self.alert.message = self.resString
        self.present(self.alert, animated: true, completion: nil)


    }
}



