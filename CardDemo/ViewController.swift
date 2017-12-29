//
//  ViewController.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/3.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let identifier = "ItemTableViewCell"
    private var tableView: UITableView?
    private let titleArray = ["扫描识别黑科技", "人脸识别黑科技", "出险鉴定黑科技"]
    private let imageArray = [[#imageLiteral(resourceName: "home1"), #imageLiteral(resourceName: "home2"), #imageLiteral(resourceName: "home3")], [#imageLiteral(resourceName: "home4")], [#imageLiteral(resourceName: "home5")]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    //MARK: - event
    
    func cardAction(type: DiscernType) {
        let vc = SubViewController(type: type)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - 代理
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageArray[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 {
            return 10
        }else {
            return 0.00001
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = titleArray[section]
        return label
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! ItemTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.clear
        let image = imageArray[indexPath.section][indexPath.row]
        cell.update(image: image)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cardAction(type: .idCard)
        case (0, 1):
            cardAction(type: .driveCard)
        case (0, 2):
            cardAction(type: .bankCard)
        case (1, 0):
            cardAction(type: .faceCard)
        case (2, 0):
            cardAction(type: .phoneCard)
        default:
            break
        }
    }
    
    //MARK: - private methods
    
    private func configUI() {
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.estimatedRowHeight = 100
        tableView?.rowHeight = UITableViewAutomaticDimension
        tableView?.separatorStyle = .none
        tableView?.bounces = false
        let nib = UINib(nibName: "ItemTableViewCell", bundle: nil)
        tableView?.register(nib, forCellReuseIdentifier: "ItemTableViewCell")
        //headerView
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width / 64 * 20))
        headerView.backgroundColor = UIColor.clear
        tableView?.tableHeaderView = headerView
//        let bgView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width / 64 * 150))
//        bgView.image = #imageLiteral(resourceName: "homepj")
//        tableView?.backgroundView = bgView
        
        let image  = #imageLiteral(resourceName: "homepj").scaleImageToWidth(UIScreen.main.bounds.width)
        tableView?.backgroundColor = UIColor(patternImage: image)
        
        view.addSubview(tableView!)
    }

}

