//
//  FaceRegisterViewController.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/7.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit
import AVFoundation
import MBProgressHUD

/// 人脸识别注册界面
class FaceRegisterViewController: UIViewController {

    private var device: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var stillImageOutput = AVCaptureStillImageOutput()
    private var maskView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = "认脸识图"
        setSession()
    }
    
    func photoAction() {
        let connection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo)
        stillImageOutput.captureStillImageAsynchronously(from: connection) { (imageDataSampleBuffer, error) in
            if let dataBuffer = imageDataSampleBuffer {
                self.session.stopRunning()
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(dataBuffer)!
                let image = UIImage(data: imageData)!
                let finalImage = self.cutImage(originImage: image, maskView: self.maskView!)
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
            }
        }
    }
    
    func faceRegisterSucceed(id: String) {
        let faceVC = FaceRecognizeViewController()
        faceVC.id = id
        navigationController?.pushViewController(faceVC, animated: true)
    }
    
    func cutImage(originImage: UIImage, maskView: UIView) -> UIImage{
        let maskX = maskView.frame.origin.x
        let maskY = maskView.frame.origin.y
        let maskWidth = maskView.frame.size.width
        let maskHeight = maskView.frame.size.height
        
        let finalWidth = maskWidth / 240 * 640
        let finalHeight = maskHeight / 240 * 480
        let finalX = (maskX + maskWidth / 2) - finalWidth / 2
        let finalY = maskY - 95 / 480 * finalHeight
        let scale = (originImage.size.width/finalHeight)
        
        let cropFrame = CGRect(x: finalY * scale, y: finalX * scale, width: finalHeight * scale, height: finalWidth * scale)
        let newCGImage = originImage.cgImage!.cropping(to: cropFrame)
        let newImage = UIImage(cgImage: newCGImage!)
        
        UIGraphicsBeginImageContext(CGSize(width: finalWidth, height: finalHeight));
        let context = UIGraphicsGetCurrentContext();
        //做CTM变换
        context?.translateBy(x: 0, y: 0)
        context?.rotate(by: CGFloat.pi * 0.5)
        context?.scaleBy(x: 1, y: -1)
        //绘制图片
        context?.draw(newImage.cgImage!, in: CGRect(x: 0, y: (finalWidth - newImage.size.width) * 0.5, width: finalHeight, height: finalHeight))
        let newPic = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        return newPic!
    }
    
    func showMessage(_ message: String) {
        let alertVc = UIAlertController(title: message, message: "", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "确定", style: .cancel) { (action) in
            // 开始捕获图像
            DispatchQueue.global().async {[weak self] in
                self?.session.startRunning()
            }
        }
        alertVc.addAction(alertAction)
        self.present(alertVc, animated: true, completion: nil)
    }
    
    func setSession() {
        session.sessionPreset = AVCaptureSessionPreset640x480
        if let deveces = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] {
            for device in deveces {
                if device.position == .front {
                    //更改闪关灯和对焦模式，更改设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
                    try! device.lockForConfiguration()
                    //                    device.flashMode = .off
                    //                    device.focusMode = .continuousAutoFocus
                    device.unlockForConfiguration()
                    // 初始化输入
                    try? input = AVCaptureDeviceInput(device: device)
                    // 添加输入
                    if session.canAddInput(input){
                        session.addInput(input)
                    }
                }
                
            }
        }
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
        // 初始化输出
        let videoDataOutPut = AVCaptureVideoDataOutput()
        videoDataOutPut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable:kCVPixelFormatType_32BGRA]
//        videoDataOutPut.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue.global())
        // 添加输出
        if session.canAddOutput(videoDataOutPut){
            session.addOutput(videoDataOutPut)
        }
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        // 初始化预览层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = CGRect(x: 0, y: 64, width: screenWidth, height: screenHeight - 64 - 100)
        view.layer.addSublayer(previewLayer!)
        //添加边框
        maskView = UIImageView(frame: CGRect(x: 0, y: 0, width: 240, height: 240))
        maskView?.image = #imageLiteral(resourceName: "faceno")
        maskView?.center = CGPoint(x: screenWidth / 2, y: 300.0)
        view.addSubview(maskView!)
        //添加拍照按钮
        let photoBtn = UIButton(type: .custom)
        photoBtn.frame = CGRect(x: (screenWidth - 50) / 2, y: screenHeight - 100 + 25, width: 50, height: 50)
        photoBtn.setTitleColor(UIColor.black, for: .normal)
        photoBtn.setTitle("拍照", for: .normal)
        photoBtn.addTarget(self, action: #selector(photoAction), for: .touchUpInside)
        view.addSubview(photoBtn)
        // 开始捕获图像
        DispatchQueue.global().async {[weak self] in
            self?.session.startRunning()
        }
    }
    
}
