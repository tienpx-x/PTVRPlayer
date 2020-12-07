//
//  UIViewController+.swift
//  Runner
//
//  Created by Phạm Xuân Tiến on 11/19/20.
//

extension UIViewController {
    func showAlert(title: String = "", message: String?, buttonTitle: String? = nil, completion: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title,
                                   message: message,
                                   preferredStyle: .alert)
        let titleButton = buttonTitle != nil ? buttonTitle : "完了"
        let okAction = UIAlertAction(title: titleButton, style: .cancel) { _ in
            completion?()
            ac.dismiss(animated: true, completion: nil)
        }
        okAction.setValue(UIColor.black, forKey: "titleTextColor")
        ac.addAction(okAction)
        present(ac, animated: true, completion: nil)
    }
}
