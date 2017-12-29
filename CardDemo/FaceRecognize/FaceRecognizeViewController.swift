//
//  FaceRecognizeViewController.swift
//  CardDemo
//
//  Created by rayootech on 2017/7/6.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit
import AVFoundation
import MBProgressHUD

public let ScreenWidth = UIScreen.main.bounds.width
public let ScreenHeight = UIScreen.main.bounds.height

class FaceRecognizeViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, H264HwEncoderImplDelegate {

    var id: String = ""
    private let kSaveSessionIdKey = "kSaveSessionIdKey"
    private var infoModel: FaceRecognizeModel?
    /// 控制输入和输出设备之间的数据传递
    private var session = AVCaptureSession()
    /// 调用所有的输入硬件。例如摄像头和麦克风
    private var videoIput: AVCaptureDeviceInput?
    /// 镜头捕捉到得预览图层
    private var previewLayer: AVCaptureVideoPreviewLayer?
    /// 遮罩view
    private var maskView: UIImageView?
    /// 朗读文本label
    private var scriptTextLabel: UILabel?
    /// 注册还是识别
    private var isRegister: Bool = false
    /// 是否是第一次进入
    private var isFirst = true
    ///H264编码
    private let h264Encoder = H264HwEncoderImpl()
    /// udp
    private let udpManager = UDPManager()
    
    //MARK: - 录音相关
    
    private var audioSession: AVAudioSession?
    private var recorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordFileUrl: URL?
    private var filePath: String?
    
    //MARK: - life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = "人脸识别"
        configComponents()
        setCaramer()
        
        //如果本地有id，说明已经注册过，可以直接识别，否则自动注册
        if let id = UserDefaults.standard.string(forKey: kSaveSessionIdKey) {
            self.id = id
            isRegister = false
        }else {
            isRegister = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global().async {[weak self] in
            self?.session.stopRunning()
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    //捕获取样buffer里的内容，创建一个图片
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {

        //视频流h264编码
        let finalImage = image(from: sampleBuffer)
        h264Encoder.encode(finalImage)
        
        //如果不是第一次进入直接返回
        if !isFirst {
            return
        }
        //如果是第一次进入，根据结果注册还是识别
        isFirst = false
        if isRegister {
            sendRegisterRequest()
        }else {
            sendRecognizeRequest()
        }
    }
    
    // MARK: - H264HwEncoderImplDelegate
    
    func gotSpsPps(_ sps: Data!, pps: Data!) {
        let naluStart:[UInt8] = [0x00, 0x00, 0x00, 0x01]
        let header = Data(bytes: naluStart, count: 4)
        //发sps
        var h264Data = Data()
        h264Data.append(header)
        h264Data.append(sps)
        udpManager.send(data: h264Data)
        //发pps
        h264Data.resetBytes(in: h264Data.startIndex..<h264Data.endIndex)
        h264Data.count = 0
        h264Data.append(header)
        h264Data.append(pps)
        udpManager.send(data: h264Data)
    }
    
    func gotEncodedData(_ data: Data!, isKeyFrame: Bool) {
        let naluStart:[UInt8] = [0x00, 0x00, 0x00, 0x01]
        let header = Data(bytes: naluStart, count: 4)
        //发sps
        var h264Data = Data()
        h264Data.append(header)
        h264Data.append(data)
        udpManager.send(data: h264Data)
    }
    
    // MARK: - 截图
    
    ///  捕获取样buffer里的内容，创建一个图片
    func image(from sampleBuffer:CMSampleBuffer) -> UIImage{
        
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
        let finalImage = cutImage(originImage: image, maskView: maskView!)
        return finalImage
        
    }
    
    /// 裁剪图片，剪成640*480分辨率的(两侧补白)
    func cutImage(originImage: UIImage, maskView: UIView) -> UIImage{
        let cutCGImage = originImage.cgImage?.cropping(to: CGRect(x: 0, y: 80, width: 480, height: 480))
        
        UIGraphicsBeginImageContext(CGSize(width: 640, height: 480))
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 640, y: 480)
        context?.rotate(by: CGFloat.pi)
        context?.draw(cutCGImage!, in: CGRect(x: 80, y: 0, width: 480, height: 480))
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return finalImage
        
    }
    
    //MARK: - events
    
    /// 注册按钮事件
    @objc private func registerAction() {
        sendRegisterRequest()
    }
    
    /// 登出按钮事件
    @objc private func logoutAction() {
        //发送重置请求
        ServerManager.shared.faceRecognize(id: id,reset: true, success: nil, failure: nil)
        //清除本地sessionId
        UserDefaults.standard.set(nil, forKey: kSaveSessionIdKey)
    }
    
    //MARK: - private methods
    
    /// 配置各组件
    private func configComponents() {
        h264Encoder.initWithConfiguration()
        h264Encoder.initEncode(640, height: 480)
        h264Encoder.delegate = self
    }
    
    /// 对相机进行初始化
    func setCaramer(){
        session.sessionPreset = AVCaptureSessionPreset640x480
        if let deveces = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] {
            for device in deveces {
                if device.position == .front {
                    // 初始化输入
                    try? videoIput = AVCaptureDeviceInput(device: device)
                    // 添加输入
                    if session.canAddInput(videoIput){
                        session.addInput(videoIput)
                    }
                }
                
            }
        }
        // 初始化输出
        let videoDataOutPut = AVCaptureVideoDataOutput()
        videoDataOutPut.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable:kCVPixelFormatType_32BGRA]
        videoDataOutPut.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue.global())
        // 添加输出
        if session.canAddOutput(videoDataOutPut){
            session.addOutput(videoDataOutPut)
        }

        //防止获取的图片是反的
        let connection = videoDataOutPut.connection(withMediaType: AVMediaTypeVideo)
        connection?.videoOrientation = .portrait
        connection?.isVideoMirrored = true
        
        //添加顶部label
        let label = UILabel(frame: CGRect(x: 100, y: 64, width: ScreenWidth - 200, height: 36))
        label.text = "读出下面的文字"
        label.textAlignment = .center
        label.textColor = UIColor.orange
        label.backgroundColor = UIColor.clear
        label.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(label)
        //右上角注册按钮
        let registerBtn = UIButton(type: .system)
        registerBtn.frame = CGRect(x: ScreenWidth - 100, y: 64, width: 50, height: 36)
        registerBtn.setTitle("注册", for: .normal)
        registerBtn.setTitleColor(UIColor.blue, for: .normal)
        registerBtn.addTarget(self, action: #selector(registerAction), for: .touchUpInside)
        view.addSubview(registerBtn)
        //右上角注销按钮
        let logoutBtn = UIButton(type: .system)
        logoutBtn.frame = CGRect(x: ScreenWidth - 50, y: 64, width: 50, height: 36)
        logoutBtn.setTitle("注销", for: .normal)
        logoutBtn.setTitleColor(UIColor.blue, for: .normal)
        logoutBtn.addTarget(self, action: #selector(logoutAction), for: .touchUpInside)
        view.addSubview(logoutBtn)
        // 初始化预览层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        let previewHeight = ScreenHeight - 150
        previewLayer?.frame = CGRect(x: 0, y: 100, width: ScreenWidth, height: previewHeight)
        view.layer.addSublayer(previewLayer!)
        //添加边框
        let finalHeight = previewHeight * 3 / 4
        let finalCenterY = previewLayer!.frame.midY - 50 * finalHeight / 480
        maskView = UIImageView(frame: CGRect(x: 0, y: 0, width: finalHeight / 2, height: finalHeight / 2))
        maskView?.image = #imageLiteral(resourceName: "faceno")
        maskView?.center = CGPoint(x: ScreenWidth / 2, y: finalCenterY)
        view.addSubview(maskView!)
        //添加label
        scriptTextLabel = UILabel(frame: CGRect(x: (ScreenWidth - 320) / 2, y: ScreenHeight - 50, width: 320, height: 50))
        scriptTextLabel?.textColor = UIColor.black
        scriptTextLabel?.textAlignment = .center
        scriptTextLabel?.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(scriptTextLabel!)
        scriptTextLabel?.text = "注册中..."
        // 开始捕获图像
        session.startRunning()
    }
    
    /// 停止扫描
    func stopScaning() {
        DispatchQueue.global().async {[weak self] in
            self?.session.stopRunning()
        }
    }
    
    // MARK: - 网络处理
    
    /// 发送注册请求
    private func sendRegisterRequest() {
        ServerManager.shared.faceRegister(success: {[weak self] (response) in
            print("-----注册:\(response)")
            self?.handleRegisterResult(response)
            }, failure: {[weak self] (error) in
                print("-----注册超时:\(error)")
                self?.sendRegisterRequest()
        })
    }
    
    /// 处理注册请求结果
    private func handleRegisterResult(_ obj: Any?) {
        guard let dict = obj as? [String : Any] else {
            sendRegisterRequest()
            return
        }
        let result = FaceRegisterModel(JSON: dict)!
        let id = result.id
        if result.err == "0" {
            if result.status != "9" && id != nil && id! != "" {
                registerSucceed(id: result.id!)
            }else {
                self.id = id!
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.03, execute: {[weak self] in
                    self?.sendRecognizeRequest()
                })
            }
        }else {
            sendRegisterRequest()
        }
    }
    
    /// 发送识别请求
    func sendRecognizeRequest(audio: String? = nil){
        ServerManager.shared.faceRecognize(id: id, audio: audio, reset: false, success: {[weak self] (response) in
            print("-----识别:\(response)")
            self?.handleRecognizeResult(response)
        }) {[weak self] (error) in
            print("-----识别超时:\(error)")
            self?.sendRecognizeRequest()
        }
    }
    
    /// 处理识别请求结果
    func handleRecognizeResult(_ obj: Any?){
        guard let object = obj, let dict = object as? [String : Any] else {
            sendRecognizeRequest()
            return
        }
        self.infoModel = FaceRecognizeModel(JSON: dict)
        let error = infoModel?.err
        let status = infoModel?.status
        
        //如果status为9说明是轮询注册状态
        if status == "9" {
            sendRecognizeRequest()
            return
        }
        
        if !(error == "0" && status == "3") {
            if error == "0" && status == "1" {
                if scriptTextLabel?.text != infoModel?.sceneScript {
                    //朗读文字改变，则重新录音
                    restarRecord()
                }
                scriptTextLabel?.text = infoModel?.sceneScript
            }
            if error == "0" && status == "4" {
                print("------------------------上传录音")
                if recorder?.isRecording == true {
                    scriptTextLabel?.text = "识别 录音中..."
                    sendRecognizeRequest(audio: getRecordDataString())
                    recorder?.stop()
                }else {
                    sendRecognizeRequest()
                }
            }else {
                sendRecognizeRequest()
            }
        }else {
            recognizeSucceed()
        }
    }
    
    /// 注册成功
    private func registerSucceed(id: String) {
        print("注册成功:\(CACurrentMediaTime()), id:\(id)")
        scriptTextLabel?.text = "获取文字中..."
        self.id = id
        UserDefaults.standard.set(id, forKey: kSaveSessionIdKey)
        //注册成功调用识别接口
        sendRecognizeRequest()
    }
    
    /// 识别成功
    private func recognizeSucceed(){
        print("识别成功:\(CACurrentMediaTime())")
        //跳转到识别成功界面
        let vc = PersonViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - 录音相关
    
    func startRecord() {
        print("----------------开始录音")
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession?.setActive(true)
        } catch let error {
            print("------------------创建录音失败:\(error.localizedDescription)")
        }
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last as NSString?
        filePath = path?.appendingPathComponent("RRecord.wav")
        if let realPath = filePath {
            if FileManager().fileExists(atPath: realPath) {
                try? FileManager().removeItem(atPath: realPath)
            }
        }
        recordFileUrl = URL(fileURLWithPath: filePath ?? "")
        
        let recordSetting: [String: Any] = [AVSampleRateKey: NSNumber(value: 8000.0), AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM), AVLinearPCMBitDepthKey: NSNumber(value: 16), AVNumberOfChannelsKey: NSNumber(value: 1), AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.high.rawValue)]
        
        if recordFileUrl != nil {
            do {
                recorder = try AVAudioRecorder(url: recordFileUrl!, settings: recordSetting)
            } catch let error {
                print("--------------------开始录音失败:\(error.localizedDescription)")
            }
        }
        
        recorder?.isMeteringEnabled = true
        recorder?.prepareToRecord()
        recorder?.record()
    }
    
    func stopRecord() {
        if recorder?.isRecording == true {
            recorder?.stop()
        }
    }
    
    func restarRecord() {
        if recorder?.isRecording == true {
            recorder?.stop()
        }
        startRecord()
    }
    
    func getRecordDataString() -> String {
        print("-----------------获取录音")
        if recorder?.isRecording == true {
            recorder?.stop()
        }
        if recordFileUrl == nil {
            return ""
        }
        let data = try? Data(contentsOf: recordFileUrl!)
        return data?.base64EncodedString() ?? ""
    }
    
}
