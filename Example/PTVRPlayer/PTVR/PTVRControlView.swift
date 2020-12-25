//
//  PTVRControlView.swift
//  PTVRPlayer
//
//  Created by Phạm Xuân Tiến on 11/5/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import PTVRPlayer
import QRCodeReader
import AVFoundation

class PTVRControlView: UIView, NibOwnerLoadable, PTControlView, QRCodeReaderViewControllerDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var settingButton: UIButton!
    
    // MARK: - Properties
    
    weak var playerController: PTPlayerControler?
    var controller: Bottomsheet.Controller?
    var currentViewer: ViewerParameters?
    
    // MARK: - QR
    
    lazy var reader: QRCodeReader = QRCodeReader()
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            $0.showTorchButton = false
            $0.startScanningAtLoad = true
            $0.showSwitchCameraButton = false
            $0.preferredStatusBarStyle = .lightContent
            $0.handleOrientationChange = true
            $0.showOverlayView = true
            $0.rectOfInterest = CGRect(x: 0.35, y: 0.2, width: 0.3, height: 0.6)
            $0.reader.stopScanningWhenCodeIsFound = false
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    var isPlaying: Bool = false
    
    var isLoading: Bool = false
    
    var isSeeking: Bool = false
    
    var isEnded: Bool = false
    
    var duration: TimeInterval = 0 {
        didSet {
            
        }
    }
    
    var process: TimeInterval = 0 {
        didSet {
            
        }
    }
    
    var canStepFoward: Bool = false
    var canStepBackward: Bool = false
    
    // MARK: - Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
        self.binding()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadNibContent()
        self.commonInit()
        self.binding()
    }
    
    // MARK: - Methods
    
    func commonInit() {
        settingButton.setImage(UIImage.fontAwesomeIcon(name: .cog,
                                                       style: .solid,
                                                       textColor: .white,
                                                       size: CGSize(width: 26, height: 26)),
                               for: .normal)
        // TODO: Hide at the moment
        settingButton.isHidden = true
    }
    
    func binding() {
        closeButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                self.playerController?.endVRMode()
            })
            .disposed(by: rx.disposeBag)
        
        // TODO: Hide at the moment
//        settingButton.rx.tap.asDriver()
//            .throttle(.milliseconds(500))
//            .drive(onNext: { [unowned self] in
//                self.openSettingSheet()
//            })
//            .disposed(by: rx.disposeBag)
    }
    
    @objc func showControlView() {
        
    }
    
    @objc func hideControlView() {
        
    }
    
    func openSettingSheet() {
        controller = Bottomsheet.Controller()
        let view = PTVRSettings()
        guard let controller = controller else { return }
        controller.addContentsView(view)
        controller.viewActionType = .tappedDismiss
        controller.initializeHeight = 80 * UIScreen.main.bounds.height / 375
        playerController?.present(controller, animated: true, completion: nil)
        
        if let viewer = currentViewer {
            view.viewerLabel.text = "ビューア切り替え： \(viewer.name)"
        } else {
            view.viewerLabel.text = "ビューア切り替え： Cardboard"
        }
        
        view.viewerButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                controller.dismiss(animated: false, completion: { [unowned self] in
                    self.scanQRCode()
                })
            })
            .disposed(by: rx.disposeBag)
        
        view.subButton.rx.tap.asDriver()
            .throttle(.milliseconds(500))
            .drive(onNext: { [unowned self] in
                controller.dismiss(animated: false, completion: { [unowned self] in
                    self.playerController?.changeModel(PTViewerModel.cardboardMay2015)
                })
            })
            .disposed(by: rx.disposeBag)
    }
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        let url = result.value
        PTCardboard.getViewerParam(url: "https://\(url)", onCompleted: { [weak self] cardboard in
            self?.playerController?.changeModel(cardboard)
            let alert = UIAlertController(
                title: "ペアリングが正常に行われました。",
                message: " 端末に\(cardboard.name)ビューアがセットアップされました。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            DispatchQueue.main.async {
                self?.currentViewer = cardboard
                self?.playerController?.present(alert, animated: true, completion: nil)
            }
        })
        readerVC.dismiss(animated: true)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        readerVC.dismiss(animated: true, completion: nil)
    }
}

// MARK: - QR
extension PTVRControlView {
    private func scanQRCode() {
        guard checkScanPermissions() else { return }
        readerVC.modalPresentationStyle = .fullScreen
        readerVC.delegate = self
        playerController?.present(readerVC, animated: true, completion: nil)
    }
    
    private func checkScanPermissions() -> Bool {
        do {
            return try QRCodeReader.supportsMetadataObjectTypes()
        } catch let error as NSError {
            let alert: UIAlertController
            
            switch error.code {
            case -11852:
                alert = UIAlertController(title: "Error", message: "This app is not authorized to use Back Camera.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Setting", style: .default, handler: { (_) in
                    DispatchQueue.main.async {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.openURL(settingsURL)
                        }
                    }
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            default:
                alert = UIAlertController(title: "Error", message: "Reader not supported by the current device", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            }
            
            playerController?.present(alert, animated: true, completion: nil)
            
            return false
        }
    }
}
