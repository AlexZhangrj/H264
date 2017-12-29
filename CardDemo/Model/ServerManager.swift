//
//  ServerManager.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/3.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit
import Alamofire
import AFNetworking

class ServerManager: NSObject {

    static let shared = ServerManager()
    private let baseURL = "http://ecuat.tk.cn/tkeservice_app/rest/api/dynamic"
    private var type: DiscernType  = .bankCard
    
    var asscessTokenModel: BaiDuOCRAccessTokenModel?
    
    
    /// 发送注册请求
    ///
    /// - Parameters:
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func faceRegister(success:((Any)->())?, failure:((String)->())?) {
        
        Alamofire.upload(multipartFormData: { (formData) in
            
        }, to: URL(string: "http://10.90.7.10/FaceMatcher/register")!) { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _ ):
                upload.responseJSON(completionHandler: { (respones) in
                    let object = respones.result.value
                    guard let obj = object else {
                        failure!("失败")
                        return
                    }
                    print("注册结果:\(obj)")
                    success?(obj)
                })
            case .failure(let encodingError):
                failure!(encodingError.localizedDescription)
            }
        }
    }
    
    /// 发送识别请求
    ///
    /// - Parameters:
    ///   - id: 会话id
    ///   - audio: 录音data
    ///   - reset: 1，恢复初始化,通知服务器开始新一轮的活体检测
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func faceRecognize(id: String, audio: String? = nil, reset: Bool = false, success:((Any)->())?, failure:((String)->())?) {
        
        Alamofire.upload(multipartFormData: { (formData) in
            formData.append(id.data(using: .utf8)!, withName: "id")
            if let au = audio, au != "" {
                formData.append(au.data(using: .utf8)!, withName: "audio")
            }
            if reset {
                formData.append("1".data(using: .utf8)!, withName: "reset")
            }
        }, to: URL(string: "http://10.90.7.10/FaceMatcher/recognize")!) { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _ ):
                upload.responseJSON(completionHandler: { (respones) in
                    let object = respones.result.value
                    guard let obj = object else {
                        failure!("失败")
                        return
                    }
                    print("识别结果:\(obj)")
                    success?(obj)
                })
            case .failure(let encodingError):
                failure!(encodingError.localizedDescription)
            }
        }
    }
    
    func uploadImage(img: String, type: DiscernType, success:((Any)->())?, failure:((String)->())?) {
        var methodName = ""
        var typeName = ""
        switch type {
        case .phoneCard:
            methodName = "localmethod.commonMatcherOperater"
            typeName = "brokenDetection"
            let parametersDictionary = ["main":["method":methodName, "type":typeName, "img":img]]
            let tempData = try! JSONSerialization.data(withJSONObject: parametersDictionary, options: .prettyPrinted)
            var request = URLRequest(url: URL(string: baseURL)!)
            let manager = AFURLSessionManager()
            manager.responseSerializer = AFJSONResponseSerializer()
            request.httpBody = tempData
            request.httpMethod = "POST"
            request.timeoutInterval = 15
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            manager.dataTask(with: request) { (response, obj, error) in
                if error == nil && obj != nil {
                    print("结果:\(obj ?? "")")
                    success?(obj!)
                }else {
                    failure?("请求失败")
                }
            }.resume()
        case .driveCard,.idCard,.bankCard:
            weak var `self` = self
            getAccessToken(success: { 
                
                self?.discernIdentifercation(img: img, type: type, success: success, failure: failure)
            })
        default:
            break
        }
    }
    
    
    
    /// 获取token
    func getAccessToken(success:(()->())?){
        if asscessTokenModel != nil{
            success?()
        }
        let param = [
            "grant_type": "client_credentials",
            "client_id":"t59OXO7bCBztG2KTBSVdmzgk",
            "client_secret":"2GTHdfMi99AtGsVxAWAKwNFWUf6g9OvW"
        ]
        weak var `self` = self
        Alamofire.request("https://aip.baidubce.com/oauth/2.0/token", method: .post, parameters: param, encoding: URLEncoding.default, headers: nil).responseJSON { (respone) in
            if let dict = respone.result.value{
                let value = dict as! [String: Any]
                self?.asscessTokenModel = BaiDuOCRAccessTokenModel(JSON: value)
                success?()
            }
        }
    }

    
    /// 图片发送到服务器识别
    func discernIdentifercation(img: String, type: DiscernType, success:((CardInfoModel?)->())?, failure:((String)->())?){
        let typePath = type.rawValue
        let cardSide = "front"
        let url = "https://aip.baidubce.com/rest/2.0/ocr/v1" + typePath + "?access_token=" + "\(asscessTokenModel?.accessToken ?? "")"
        Alamofire.upload(multipartFormData: { (formData) in
            formData.append(img.data(using: .utf8)!, withName: "image")
            formData.append(cardSide.data(using: .utf8)!, withName: "id_card_side")
            formData.append("true".data(using: .utf8)!, withName: "detect_direction")
        }, to: url) { encodingResult in
            switch encodingResult {
            case .success(let upload, _, _ ):
                upload.responseJSON(completionHandler: { (respones) in
                    let object = respones.result.value
                    guard let obj = object else {
                        failure!("失败")
                        return
                    }
                    let dict = obj as!  [String : Any]
                    let infoModel = CardInfoModel(JSON: dict)
                    success?(infoModel)
                })
            case .failure(let encodingError):
                failure!(encodingError.localizedDescription)
            }
        }
    }
    
}



