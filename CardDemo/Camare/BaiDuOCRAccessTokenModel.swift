//
//  BaiDuOCRAccessTokenModel.swift
//  Camare
//
//  Created by wkk on 2017/6/7.
//  Copyright © 2017年 TaikangOnline. All rights reserved.
//

import ObjectMapper

struct BaiDuOCRAccessTokenModel: Mappable {

    var scope : String?
    var accessToken : String?
    var expiresIn : Int?
    var refreshToken : String?
    var sessionKey : String?
    var sessionSecret : String?
    
    

    init?(map: Map){}
    
    mutating func mapping(map: Map)
    {
        scope <- map["scope"]
        accessToken <- map["access_token"]
        expiresIn <- map["expires_in"]
        refreshToken <- map["refresh_token"]
        sessionKey <- map["session_key"]
        sessionSecret <- map["session_secret"]
        
    }


}


struct CardInfoModel: Mappable {
    
    var imageStatus : String?
    var logId : Int?
    var wordsResult : WordsResult?
    var wordsResultNum : Int?
    var result:BankCardInfo?
    var errorMsg: String?
    init?(map: Map){}
    mutating func mapping(map: Map)
    {
        imageStatus <- map["image_status"]
        logId <- map["log_id"]
        wordsResult <- map["words_result"]
        wordsResultNum <- map["words_result_num"]
        result <- map["result"]
        errorMsg <- map["error_msg"]
    }
    
    
}
struct BankCardInfo: Mappable {
    var bankNumber : String?
    var bankName : String?
    var type : Int?
    
    init?(map: Map){}
    
    mutating func mapping(map: Map)
    {
        bankNumber <- map["bank_card_number"]
        bankName <- map["bank_name"]
        type <- map["bank_card_type"]
    }
    
}
struct WordsResult: Mappable {
    var address : InfoItem?
    var idNumber : InfoItem?
    var birthday : InfoItem?
    var name : InfoItem?
    var sex : InfoItem?
    var nation : InfoItem?
    var issueDate: InfoItem?
    var issueDepartment: InfoItem?
    var invalidDate: InfoItem?
    
    
    var licenseNum : InfoItem?
    var validTimeIntr : InfoItem?
    var carType : InfoItem?
    var validTimeStar : InfoItem?
    var country : InfoItem?
    var fisrtGetDate: InfoItem?
    
    init?(map: Map){}
    
    mutating func mapping(map: Map)
    {
        address <- map["住址"]
        idNumber <- map["公民身份号码"]
        birthday <- map["出生"]
        name <- map["姓名"]
        sex <- map["性别"]
        nation <- map["民族"]
        issueDate <- map["签发日期"]
        issueDepartment <- map["签发机关"]
        invalidDate <- map["失效日期"]
        
        
        licenseNum <- map["证号"]
        validTimeIntr <- map["有效期限"]
        carType <- map["准驾车型"]
        validTimeStar <- map["有效起始日期"]
        country <- map["国籍"]
        birthday <- map["出生日期"]
        fisrtGetDate <- map["初次领证日期"]
        
    }
}

struct InfoItem :  Mappable{
    
    var location : Location?
    var words : String?
    
    
    init?(map: Map){}
    mutating func mapping(map: Map)
    {
        location <- map["location"]
        words <- map["words"]
        
    }
}
struct Location : Mappable{
    
    var height : Int?
    var left : Int?
    var top : Int?
    var width : Int?
    
    
    
    init?(map: Map){}
    
    
    mutating func mapping(map: Map)
    {
        height <- map["height"]
        left <- map["left"]
        top <- map["top"]
        width <- map["width"]
        
    }
}
