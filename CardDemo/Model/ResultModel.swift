//
//  ResultModel.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/6.
//  Copyright © 2017年 demon. All rights reserved.
//

import ObjectMapper

struct ResultModel: Mappable {
    
    var status: Int?
    var skill : String?
    var result : PhoneModel?
    init?(map: Map){}
    mutating func mapping(map: Map)
    {
        status <- map["status"]
        skill <- map["skill"]
        result <- map["result"]
    }
    
}

struct PhoneModel: Mappable {
    var value: String?
    init?(map: Map){}
    mutating func mapping(map: Map)
    {
        value <- map["status"]
    }
}

//人脸识别

struct FaceRegisterModel: Mappable {
    var err : String?
    var id : String?
    var status: String?
    init?(map: Map){}
    mutating func mapping(map: Map)
    {
        err <- map["err"]
        id <- map["id"]
        status <- map["status"]
    }
}

struct FaceRecognizeModel: Mappable {
    var err : String?
    var status : String?
    var sceneScript: String?
    init?(map: Map){}
    mutating func mapping(map: Map)
    {
        err <- map["err"]
        status <- map["status"]
        sceneScript <- map["sceneScript"]
    }
}

