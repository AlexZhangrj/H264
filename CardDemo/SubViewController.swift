//
//  SubViewController.swift
//  
//
//  Created by rayootech on 2017/7/4.
//
//

import UIKit
import MBProgressHUD
import CoreGraphics

class SubViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var type: DiscernType = .idCard
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBAction func nextBtnAction(_ sender: Any) {
        if type == .phoneCard {
            phoneAction()
        }else if type == .faceCard {
//            faceAction()
            let registerVC = FaceRecognizeViewController()
            navigationController?.pushViewController(registerVC, animated: true)
        }else {
            let vc = TKOCRViewController()
            vc.getCardInfo(with: type, name: "", complete: nil)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    //MARK: - 新的
    
    func faceAction() {
        let imagepickerController = UIImagePickerController()
        imagepickerController.delegate = self
        imagepickerController.sourceType = .camera
        imagepickerController.cameraDevice = .front
        //设置遮罩
        let maskView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        maskView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: 180)
        maskView.image = #imageLiteral(resourceName: "faceno")
        imagepickerController.cameraOverlayView = maskView
        present(imagepickerController, animated: true, completion: nil)
    }
    
    func faceDealInfo(info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            dismiss(animated: true, completion: {
                self.imageView.contentMode = .scaleAspectFit
                self.imageView.image = image
                let subImage = image.scaleImageToWidth(480)
                let finalImage = self.finalImage(image: subImage, width: 480)
                UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
                let imgData = UIImageJPEGRepresentation(finalImage, 1)!
                let imgStr = imgData.base64EncodedString()
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                ServerManager.shared.faceRegister(success: {[weak self] (response) in
                    hud.hide(animated: true)
                    guard let dict = response as? [String : Any] else {
                        self?.showMessage("注册失败")
                        return
                    }
                    let result = FaceRegisterModel(JSON: dict)!
                    let id = result.id
                    if result.err == "0" && id != nil && id! != ""  {
                        self?.faceRegisterSucceed(id: result.id!)
                    }else {
                        self?.showMessage("注册失败")
                    }
                    }, failure: {[weak self] (error) in
                        hud.hide(animated: true)
                        self?.showMessage("注册超时!")
                })
//                self.faceRegisterSucceed(id: "222")
            })
        }
    }
    
    func finalImage(image: UIImage, width: CGFloat) -> UIImage {
        let height = width / 4 * 3
        // 3. 图像的上下文
        let s = CGSize(width: width, height: height)
        // 提示：一旦开启上下文，所有的绘图都在当前上下文中
        UIGraphicsBeginImageContextWithOptions(s, false, 1)
        let context = UIGraphicsGetCurrentContext()
        context?.addRect(CGRect(x: 0, y: 0, width: width, height: height))
        context?.clip()
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: image.size.height))
        let newPic = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        return newPic!
    }
    
    func correctImage(originImage: UIImage) -> UIImage? {
        
        //翻转图片的方向
        var flipImageOrientation = (originImage.imageOrientation.rawValue + 4) % 8
        flipImageOrientation += flipImageOrientation%2==0 ? 1 : -1
        if let cgImage = originImage.cgImage, let orientation = UIImageOrientation(rawValue: flipImageOrientation) {
            //翻转图片
            let finalImage = UIImage(cgImage: cgImage, scale: originImage.scale, orientation: orientation)
            return finalImage
        }else {
            return nil
        }
    }
    
    func faceRegisterSucceed(id: String) {
        let faceVC = FaceRecognizeViewController()
        faceVC.id = id
        navigationController?.pushViewController(faceVC, animated: true)
    }
    
    /// 碎屏拍照
    func phoneAction() {
        let imagepickerController = UIImagePickerController()
        imagepickerController.delegate = self
        imagepickerController.sourceType = .camera
//        imagepickerController.allowsEditing = true                                     //允许编辑
        present(imagepickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if type == .faceCard {
            faceDealInfo(info: info)
        }
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            dismiss(animated: true, completion: { 
                self.imageView.image = image
                let data = UIImageJPEGRepresentation(image, 0.5)!
                let imgStr = data.base64EncodedString()
                let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                ServerManager.shared.uploadImage(img: imgStr, type: .phoneCard, success: {[weak self] (response) in
                    hud.hide(animated: true)
                    guard let dict = response as? [String : Any] else {
                        self?.showMessage("识别失败")
                        return
                    }
                    let resultDict = dict["result"] as? [String:Any]
                    let value = resultDict?["value"] as? String
                    let status = dict["status"] as? Int
                    if status == 0 {
                        self?.recogniseSucceed(percentStr: value)
                    }else {
                        self?.showMessage("识别失败")
                    }
                }, failure: {[weak self] (error) in
                    hud.hide(animated: true)
                    self?.showMessage("识别超时!")
                })
            })
        }
    }
    
    func showMessage(_ message: String) {
        let alertVc = UIAlertController(title: message, message: "", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "确定", style: .cancel, handler: nil)
        alertVc.addAction(alertAction)
        self.present(alertVc, animated: true, completion: nil)
    }
    
    func recogniseSucceed(percentStr: String?) {
        if let perStr = percentStr {
            let percent = Float(perStr) ?? 0
            let resultVC = PhoneResultViewController(percent: percent)
            navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    //MARK: - 旧的
    
    init(type: DiscernType) {
        super.init(nibName: "SubViewController", bundle: nil)
        self.type = type
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configUI()
    }
    
    private func configUI() {
        let screenWIdth = UIScreen.main.bounds.width
        switch type {
        case .bankCard:
            title = "银行卡扫描识别"
            titleLabel.text = "请拍摄您的银行卡正面，用于读取信息"
            imageViewHeightConstraint.constant = (screenWIdth - 40) / 539 * 341
            imageView.image = #imageLiteral(resourceName: "card")
        case .idCard:
            title = "身份证扫描识别"
            titleLabel.text = "请拍摄您的身份证正面，用于读取信息"
            imageViewHeightConstraint.constant = (screenWIdth - 40) / 539 * 341
            imageView.image = #imageLiteral(resourceName: "shenfenzheng")
        case .driveCard:
            title = "驾驶证扫描识别"
            titleLabel.text = "请拍摄您的驾驶证正面，用于读取信息"
            imageViewHeightConstraint.constant = (screenWIdth - 40) / 539 * 341
            imageView.image = #imageLiteral(resourceName: "jiazhao")
        case .phoneCard:
            title = "碎屏鉴定"
            titleLabel.text = "请拍摄您受损的手机正面，用于技术鉴定"
            imageViewHeightConstraint.constant = (screenWIdth - 40) / 539 * 672
            imageView.image = #imageLiteral(resourceName: "iphone")
        default:
            title = "认脸识图"
            titleLabel.text = ""
            imageViewHeightConstraint.constant = (screenWIdth - 40) / 539 * 524
            imageView.image = #imageLiteral(resourceName: "face")
        }
    }
    
    
}
