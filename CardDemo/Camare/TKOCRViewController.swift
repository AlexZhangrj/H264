//
//  ViewController.swift
//  Camare
//
//  Created by wkk on 2017/5/27.
//  Copyright © 2017年 TaikangOnline. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import ObjectMapper



enum  DiscernType: String{
    case idCard = "/idcard"
    case bankCard = "/bankcard"
    case driveCard = "/driving_license"
    case phoneCard = "phone"
    case faceCard = "face"
}

class TKOCRViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    typealias completeClouse = (_ action: String,_ msg:[String: Any])->()
    /// 照片Data数组
    fileprivate var imageData:Data?
    
    /// 控制输入和输出设备之间的数据传递
    fileprivate var session = AVCaptureSession()
    
    /// 调用所有的输入硬件。例如摄像头和麦克风
    fileprivate var videoIput: AVCaptureDeviceInput?
    
    /// 镜头捕捉到得预览图层
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    
    /// 是否在去照片
    fileprivate var isPhoto: Bool = false
    
    /// 获取的身份证信息信息
    fileprivate var infoModel: CustomerIDInfoModel?
    
    /// 已经识别的次数
    fileprivate var count = 0
    
    /// 展示获取到的信息的视图
    fileprivate var showInfoView: UIView?
    
    /// 识别请求地址
    fileprivate let baseURL = "http://10.90.7.10"
    
    /// 最大重试次数
    fileprivate let MAXTRYCOUNT = 4
    
    /// 遮罩view
    fileprivate var maskView:Even_OddView?
    
    /// 识别类型
    fileprivate var type: DiscernType = .bankCard
    
    /// 完成执行的闭包
    fileprivate var complete: completeClouse! = {_ in}
    
    fileprivate var customerName:String = ""
    var hasToResult = false
    
    /// 上传的图片
    private var updateImage: UIImage?
    
    /// 设置类型和完成后的闭包
    ///
    /// - Parameters:
    ///   - recongizeType: 识别类型
    ///   - complete: 完成后要做的事
    func getCardInfo(with recongizeType: DiscernType,name: String,complete: completeClouse?){
        self.complete = complete
        type = recongizeType
        customerName = name
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        //设置标题
        switch type {
        case .bankCard:
            title = "银行卡扫描识别"
        case .idCard:
            title = "身份证扫描识别"
        case .driveCard:
            title = "驾驶证扫描识别"
        default:
            break
        }
        //设置相机
        setCaramer()
    }
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global().async {[weak self] in
            self?.session.stopRunning()
        }
    }
    
    /// 对相机进行初始化
    func setCaramer(){
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        //更改闪关灯和对焦模式，更改设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
        try! device?.lockForConfiguration()
        device?.flashMode = .off
        device?.focusMode = .continuousAutoFocus
        device?.unlockForConfiguration()
        // 初始化输入
        try? videoIput = AVCaptureDeviceInput(device: device)
        // 添加输入
        if session.canAddInput(videoIput){
            session.addInput(videoIput)
        }
        // 初始化输出
        let videoDataOutPut = AVCaptureVideoDataOutput()
        videoDataOutPut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable:kCVPixelFormatType_32BGRA]
        videoDataOutPut.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue.global())
        // 添加输出
        if session.canAddOutput(videoDataOutPut){
            session.addOutput(videoDataOutPut)
        }
        // 初始化预览层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.addSublayer(previewLayer!)
        
        maskView = Even_OddView(frame: view.bounds, tipType: type,name:customerName)
        view.addSubview(maskView!)
        // 开始捕获图像
//        DispatchQueue.global().async {[weak self] in
            self.session.startRunning()
//        }
    }
    //捕获取样buffer里的内容，创建一个图片
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if isPhoto == true{
            return
        }else{
            isPhoto = true
            print(2)
        }
        let data = image(from: sampleBuffer)
        imageData = data
        //上传服务器进行识别
        discernIdentifercation()

    }

    ///  捕获取样buffer里的内容，创建一个图片
    func image(from sampleBuffer:CMSampleBuffer) -> Data{
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let width = CVPixelBufferGetWidth(imageBuffer!)
        let height = CVPixelBufferGetHeight(imageBuffer!)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        /// 初始化一个
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        let quartzImage = context!.makeImage()
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let image = UIImage(cgImage: quartzImage!)
        let data = cutImage(originalImage: image)
        return data
        
    }
    
    /// 停止扫描
    func stopScaning() {
//        DispatchQueue.global().async {[weak self] in
            self.session.stopRunning()
//        }
    }
    
    /// 图片发送到服务器识别
    func discernIdentifercation(){
        guard let imageData = imageData else {
            return
        }
        count += 1
        updateImage = UIImage(data: imageData)
        let img = imageData.base64EncodedString()
        ServerManager.shared.uploadImage(img: img, type: type, success: { (obj) in
            self.handleResult(obj)
        }) { (error) in
            self.reStart()
        }
    }
   
    /// 处理请求结果
    func handleResult(_ obj: Any?){
     
        switch type {
        case .bankCard,.idCard,.driveCard:
            let model = obj as! CardInfoModel
            if model.errorMsg == nil || model.imageStatus == "normal"{
                 complete(data: model,type: type)
            }else{
                reStart()
            }
        case .phoneCard:
            guard let object = obj, let dict = object as? [String : Any] else {
                self.reStart()
                return
            }
            self.infoModel = CustomerIDInfoModel(JSON: dict)
        default:
            break
        }
    }
    func showfailAlert(){
        let alertVc = UIAlertController(title: "识别超时！", message: "", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "确定", style: .cancel, handler: { (action) in
            self.tryAgain()
        })
        alertVc.addAction(alertAction)
        self.present(alertVc, animated: true, completion: nil)

    }
    
    func complete(data model: Mappable,type: DiscernType){
        if !hasToResult{
            hasToResult = true
            let vc = ResultViewController(type: type, content: model)
            vc.image = updateImage
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    /// 再试一次
    func tryAgain(){
        count = 0
        showInfoView?.isHidden = true
        maskView?.isHidden = false
        isPhoto = false
    }

    /// 重新识别
    func reStart(){
        showInfoView?.isHidden = true
        maskView?.isHidden = false
        isPhoto = false
    }
    
    /// 裁剪原图
    ///
    /// - Returns: 裁剪后的图片
    func cutImage(originalImage: UIImage) -> Data{
        var width: CGFloat = 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        let scale = (originalImage.size.height/UIScreen.main.bounds.width)
        width = UIScreen.main.bounds.width
        
        switch type {
        case .phoneCard:
            height = width / 46 * 67 + 100
            x = 45
            y = (UIScreen.main.bounds.height - height) * 0.5
        default:
            height = width / 58 * 35
            x = 15
            y = (UIScreen.main.bounds.height - height) * 0.5 - 100
        }
        
        let cropFrame = CGRect(x: y * scale, y: x * scale, width: height * scale, height: width * scale)
        let newCGImage = originalImage.cgImage!.cropping(to: cropFrame)
        let newImage = UIImage(cgImage: newCGImage!)
        
        UIGraphicsBeginImageContext(CGSize(width: width, height: height));
        let context = UIGraphicsGetCurrentContext();
        //做CTM变换
        context?.translateBy(x: 0, y: 0)
        context?.rotate(by: CGFloat.pi * 0.5)
        context?.scaleBy(x: 1, y: -1)
        //绘制图片
        context?.draw(newImage.cgImage!, in: CGRect(x: 0, y: 0, width: height, height: width))
        let newPic = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        let data = UIImageJPEGRepresentation(newPic!, 1)
        return data!
    }

}


