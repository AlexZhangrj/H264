//
//  CustomerIDInfoModel.swift
//  Camare
//
//  Created by wkk on 2017/6/7.
//  Copyright © 2017年 TaikangOnline. All rights reserved.
//

import ObjectMapper

struct CustomerIDInfoModel: Mappable {

    var status: Int?
    var skill : String?
    var result : [String: String]?
    init?(map: Map){}
    mutating func mapping(map: Map)
    {
        status <- map["status"]
        skill <- map["skill"]
        result <- map["result"]
    }


}

