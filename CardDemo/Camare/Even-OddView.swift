//
//  Even-OddView.swift
//  shapeLayer
//
//  Created by wkk on 2017/6/9.
//  Copyright © 2017年 TaikangOnline. All rights reserved.
//

import UIKit

class Even_OddView: UIView {
    fileprivate var type: DiscernType = .idCard
    
    fileprivate var tipRect: CGRect = CGRect.zero
    init(frame: CGRect,tipType: DiscernType,name: String) {
        super.init(frame: frame)
        type = tipType
        backgroundColor = UIColor.clear
//        let shapeLayer = CAShapeLayer()
//        tipRect = getTipRect()
//        shapeLayer.path = UIBezierPath(roundedRect:tipRect, cornerRadius: 5).cgPath
//        shapeLayer.strokeColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor
//        shapeLayer.fillColor = UIColor.clear.cgColor
//        shapeLayer.strokeStart = 0
//        shapeLayer.strokeEnd = 1
//        shapeLayer.lineWidth = 2
//        layer.addSublayer(shapeLayer)
        
        var image: UIImage?
        var tips: String = ""
        switch type {
        case .bankCard:
            image = #imageLiteral(resourceName: "zhezhao_card")
            tips = "银行卡"
        case .driveCard:
            image = #imageLiteral(resourceName: "zhezhao_jiazhao")
            tips = "驾驶证"
        case .idCard:
            image = #imageLiteral(resourceName: "zhezhao_shenfenzheng")
            tips = "身份证"
        case .phoneCard:
            image = #imageLiteral(resourceName: "zhezhao_iphone")
            tips = "手机"
        default:
            break
        }
        tipRect = getTipRect()
        let imageView = UIImageView(frame: tipRect)
        imageView.image = image
        addSubview(imageView)
        
        let tipLabel = UILabel()
        tipLabel.text = "将\(tips)正面置于此区域，并对其扫描框边缘"
        tipLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        tipLabel.textAlignment = .center
        tipLabel.sizeToFit()
        tipLabel.frame = CGRect(x: 0, y: tipRect.maxY + 20, width: UIScreen.main.bounds.width, height: 50)
        addSubview(tipLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        
        let path1 = UIBezierPath(rect: bounds)
        let path2 =  UIBezierPath(roundedRect: tipRect, cornerRadius: 5)
        context?.addPath(path1.cgPath)
        context?.addPath(path2.cgPath)
        context?.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context?.drawPath(using: .eoFill)
    }
    
    func getTipRect()->CGRect{
        var width: CGFloat = 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        switch type {
        case .phoneCard:
            width = bounds.width - 90
            height = width / 46 * 67
            x = 45
            y = (bounds.height - height) * 0.5
        default:
            width = bounds.width - 30
            height = width / 58 * 35
            x = 15
            y = (bounds.height - height) * 0.5 - 100
        }
        return  CGRect(x: x, y: y, width: width, height: height)
    }

}
