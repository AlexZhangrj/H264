//
//  CustomNavigationController.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/4.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit

class CustomNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if viewControllers.count > 0 {            //自定义返回按钮
            let backButton = UIButton(type: UIButtonType.custom)
            backButton.setImage(UIImage(named: "top"), for: UIControlState())
            backButton.sizeToFit()
            //            backButton.backgroundColor = UIColor.blackColor()
            backButton.addTarget(self, action: #selector(backButtonClick(_:)), for: .touchUpInside)
            backButton.contentEdgeInsets = UIEdgeInsetsMake(0, -((backButton.currentImage?.size.width)! * 0.8), 0, 0)
            let backItem = UIBarButtonItem(customView: backButton)
            viewController.navigationItem.leftBarButtonItem = backItem
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: true)
    }
    
    func backButtonClick(_ button:UIButton) {
        super.popViewController(animated: true)
    }

}
