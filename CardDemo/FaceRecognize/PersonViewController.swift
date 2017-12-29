//
//  PersonViewController.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/5.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit

class PersonViewController: UIViewController {

    @IBAction func btnAction(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    init() {
        super.init(nibName: "PersonViewController", bundle: nil)
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
    
    func configUI() {
        let backButton = UIButton(type: UIButtonType.custom)
        backButton.setImage(UIImage(named: "top"), for: UIControlState())
        backButton.sizeToFit()
        //            backButton.backgroundColor = UIColor.blackColor()
        backButton.addTarget(self, action: #selector(backButtonClick(_:)), for: .touchUpInside)
        backButton.contentEdgeInsets = UIEdgeInsetsMake(0, -((backButton.currentImage?.size.width)! * 0.8), 0, 0)
        let backItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = backItem
    }
}
