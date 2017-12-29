//
//  PhoneResultViewController.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/5.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit

class PhoneResultViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    
    @IBAction func backBtnAction(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    private var percent: Float = 0
    
    init(percent: Float) {
        super.init(nibName: "PhoneResultViewController", bundle: nil)
        self.percent = percent
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configUI()
    }

    func configUI() {
        title = "鉴定结果"
        percentLabel.text = String(format: "%.1f", percent * 100) + "%"
    }

}
