//
//  ResultViewController.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/4.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit
import ObjectMapper

class ResultViewController: UIViewController {

    @IBOutlet weak var titleLabel1: UILabel!
    @IBOutlet weak var titleLabel2: UILabel!
    @IBOutlet weak var titleLabel3: UILabel!
    @IBOutlet weak var titleLabel4: UILabel!
    @IBOutlet weak var nameLabel1: UILabel!
    @IBOutlet weak var nameLabel2: UILabel!
    @IBOutlet weak var nameLabel3: UILabel!
    @IBOutlet weak var nameLabel4: UILabel!
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint!
    @IBAction func btnAction(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }

    private var type: DiscernType = .idCard
    private var content: Mappable?

    var image: UIImage? {
        didSet {
            imageView?.image = image
        }
    }
    private var imageView: UIImageView?
    
    init(type: DiscernType, content: Mappable) {
        super.init(nibName: "ResultViewController", bundle: nil)
        self.type = type
        self.content = content
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }

    func backButtonClick(_ button:UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func configUI() {
        
        let backButton = UIButton(type: UIButtonType.custom)
        backButton.setImage(UIImage(named: "top"), for: UIControlState())
        backButton.sizeToFit()
        //            backButton.backgroundColor = UIColor.blackColor()
        backButton.addTarget(self, action: #selector(backButtonClick(_:)), for: .touchUpInside)
        backButton.contentEdgeInsets = UIEdgeInsetsMake(0, -((backButton.currentImage?.size.width)! * 0.8), 0, 0)
        let backItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backItem
        
//        imageView = UIImageView(frame: CGRect(x: 10, y: 300, width: 300, height: 200))
//        imageView?.image = image
//        view.addSubview(imageView!)
        
        
        switch type {
        case .bankCard:
            title = "银行卡扫描识别"
            viewHeightConstraint.constant = 100
            titleLabel1.text = "卡类型"
            titleLabel2.text = "银行卡号"
            let model =  content as! CardInfoModel
            nameLabel1.text = model.result?.bankName ?? ""
            nameLabel2.text = model.result?.bankNumber ?? ""
        case .idCard:
            title = "身份证扫描识别"
            titleLabel1.text = "姓名"
            titleLabel2.text = "性别"
            titleLabel3.text = "生日"
            titleLabel4.text = "身份证号"
            let model =  content as! CardInfoModel
            nameLabel1.text = model.wordsResult?.name?.words ?? ""
            nameLabel2.text = model.wordsResult?.sex?.words ?? ""
            nameLabel3.text = model.wordsResult?.birthday?.words ?? ""
            nameLabel4.text = model.wordsResult?.idNumber?.words ?? ""
            
        case .driveCard:
            title = "驾驶证扫描识别"
            titleLabel1.text = "姓名"
            titleLabel2.text = "证号"
            titleLabel3.text = "准驾车型"
            titleLabel4.text = "到期日期"
            let model =  content as! CardInfoModel
            nameLabel1.text = model.wordsResult?.name?.words ?? ""
            nameLabel2.text = model.wordsResult?.licenseNum?.words ?? ""
            nameLabel3.text = model.wordsResult?.carType?.words ?? ""
            nameLabel4.text = model.wordsResult?.invalidDate?.words ?? ""
        default:
            break
        }
    }
    
}
