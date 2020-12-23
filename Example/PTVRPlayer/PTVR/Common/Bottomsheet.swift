//
//  Bottomsheet.swift
//  Pods
//
//  Created by hiroyuki yoshida on 2015/10/17.
//
//

import UIKit
import Foundation

public typealias BottomsheetController = Bottomsheet.Controller
typealias BottomsheetTransitionAnimator = Bottomsheet.TransitionAnimator

open class Bottomsheet {
    open class Controller: UIViewController {
        public enum OverlayViewActionType {
            case swipe
            case tappedPresent
            case tappedDismiss
        }
        
        fileprivate enum State {
            case hide
            case show
            case showAll
        }
        
        // MARK: - Open property
        open var initializeHeight: CGFloat = 300 {
            didSet {
                containerViewHeightConstraint?.constant = initializeHeight
            }
        }
        
        open var viewActionType: BottomsheetController.OverlayViewActionType = .tappedDismiss
        open var duration: (hide: TimeInterval, show: TimeInterval, showAll: TimeInterval) = (0.3, 0.3, 0.3)
        open var overlayBackgroundColor: UIColor? {
            set { overlayView.backgroundColor = newValue }
            get { return overlayView.backgroundColor }
        }
        open var containerViewBackgroundColor = UIColor(white: 1, alpha: 1)
        public let overlayView = UIView()
        public let containerView = UIView()
        
        // MARK: - Private property
        fileprivate let overlayViewPanGestureRecognizer: UIPanGestureRecognizer = {
            let gestureRecognizer = UIPanGestureRecognizer()
            return gestureRecognizer
        }()
        fileprivate let overlayViewTapGestureRecognizer: UITapGestureRecognizer = {
            let gestureRecognizer = UITapGestureRecognizer()
            return gestureRecognizer
        }()
        fileprivate let panGestureRecognizer: UIPanGestureRecognizer = {
            let gestureRecognizer = UIPanGestureRecognizer()
            return gestureRecognizer
        }()
        fileprivate let barGestureRecognizer: UIPanGestureRecognizer = {
            let gestureRecognizer = UIPanGestureRecognizer()
            return gestureRecognizer
        }()
        fileprivate var containerViewHeightConstraint: NSLayoutConstraint?
        fileprivate var state: State = .hide {
            didSet { newState(state) }
        }
        fileprivate var isNeedLayout = true
        fileprivate var bar: UIView?
        fileprivate var contentView: UIView?
        fileprivate var scrollView: UIScrollView?
        fileprivate var isScrollEnabledInSheet: Bool = true
        fileprivate var hasBar: Bool {
            if let _ = bar {
                return true
            }
            return false
        }
        fileprivate var hasView: Bool {
            if let _ = contentView {
                return true
            } else if let _ = scrollView {
                return true
            }
            return false
        }
        fileprivate var maxHeight: CGFloat {
            return view.frame.height
        }
        fileprivate var moveRange: (down: CGFloat, up: CGFloat) {
            return (initializeHeight / 3, initializeHeight / 3)
        }
        private var statusBarHeight: CGFloat {
            if #available(iOS 13.0, *) {
                return self.view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
            } else {
                return 0
            }
        }
        fileprivate lazy var navigationBarHeight: CGFloat = {
            return UINavigationBar().intrinsicContentSize.height
        }()
        
        // MARK: - Initialize
        public convenience init() {
            self.init(nibName: nil, bundle: nil)
            configure()
            configureConstraints()
        }
        
        // MARK: - Open method
        
        // Adds ContentViewController
        open func addContentsViewController(_ viewController: UIViewController) {
            if let contentView = viewController.view {
                containerView.addSubview(contentView)
                contentView.translatesAutoresizingMaskIntoConstraints = false
                let topConstraint = NSLayoutConstraint(item: contentView,
                                                       attribute: .top,
                                                       relatedBy: .equal,
                                                       toItem: containerView,
                                                       attribute: .top,
                                                       multiplier: 1,
                                                       constant: 0)
                let rightConstraint = NSLayoutConstraint(item: contentView,
                                                         attribute: .right,
                                                         relatedBy: .equal,
                                                         toItem: containerView,
                                                         attribute: .right,
                                                         multiplier: 1,
                                                         constant: 0)
                let leftConstraint = NSLayoutConstraint(item: contentView,
                                                        attribute: .left,
                                                        relatedBy: .equal,
                                                        toItem: containerView,
                                                        attribute: .left,
                                                        multiplier: 1,
                                                        constant: 0)
                let bottomConstraint = NSLayoutConstraint(item: contentView,
                                                          attribute: .bottom,
                                                          relatedBy: .equal,
                                                          toItem: containerView,
                                                          attribute: .bottom,
                                                          multiplier: 1,
                                                          constant: 0)
                containerView.addConstraints([topConstraint, leftConstraint, rightConstraint, bottomConstraint])
                self.contentView = contentView
                self.addChild(viewController)
            }
        }
        
        // Adds ContentsView
        open func addContentsView(_ contentView: UIView) {
            guard !hasView else { fatalError("ContainerView can only have one") }
            containerView.addSubview(contentView)
            contentView.translatesAutoresizingMaskIntoConstraints = false
            let topConstraint = NSLayoutConstraint(item: contentView,
                                                   attribute: .top,
                                                   relatedBy: .equal,
                                                   toItem: containerView,
                                                   attribute: .top,
                                                   multiplier: 1,
                                                   constant: 0)
            let rightConstraint = NSLayoutConstraint(item: contentView,
                                                     attribute: .right,
                                                     relatedBy: .equal,
                                                     toItem: containerView,
                                                     attribute: .right,
                                                     multiplier: 1,
                                                     constant: 0)
            let leftConstraint = NSLayoutConstraint(item: contentView,
                                                    attribute: .left,
                                                    relatedBy: .equal,
                                                    toItem: containerView,
                                                    attribute: .left,
                                                    multiplier: 1,
                                                    constant: 0)
            let bottomConstraint = NSLayoutConstraint(item: contentView,
                                                      attribute: .bottom,
                                                      relatedBy: .equal,
                                                      toItem: containerView,
                                                      attribute: .bottom,
                                                      multiplier: 1,
                                                      constant: 0)
            containerView.addConstraints([topConstraint, leftConstraint, rightConstraint, bottomConstraint])
            self.contentView = contentView
        }
        
        // Life cycle
        
        open override func viewDidLoad() {
            super.viewDidLoad()
            overlayView.backgroundColor = overlayBackgroundColor
            containerView.backgroundColor = containerViewBackgroundColor
            state = .hide
        }
        
        open override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            adjustLayout()
        }
        
        // MARK: - Action
        
        @objc open func present(_ sender: AnyObject? = nil) {
            state = .showAll
        }
        @objc open func dismiss(_ sender: AnyObject? = nil) {
            state = .hide
        }
        
        // MARK: - Gestures
        
        @objc dynamic func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            switch viewActionType {
            case .tappedPresent:
                present()
            case .tappedDismiss:
                dismiss()
            default:
                break
            }
        }
        @objc dynamic func handleGestureDragging(_ gestureRecognizer: UIPanGestureRecognizer) {
            let gestureView = gestureRecognizer.view
            let point = gestureRecognizer.translation(in: gestureView)
            let originY = maxHeight - initializeHeight
            switch state {
            case .show:
                switch gestureRecognizer.state {
                case .began:
                    scrollView?.isScrollEnabled = false
                case .changed:
                    containerView.frame.origin.y = max(0, containerView.frame.origin.y + point.y)
                    containerViewHeightConstraint?.constant = max(initializeHeight, maxHeight - containerView.frame.origin.y)
                    gestureRecognizer.setTranslation(.zero, in: gestureView)
                case .ended, .cancelled:
                    scrollView?.isScrollEnabled = true
                    if containerView.frame.origin.y - originY > moveRange.down {
                        dismiss()
                    } else if (containerViewHeightConstraint?.constant ?? 0) - initializeHeight > moveRange.up {
                        present()
                    } else {
                        let animations = {
                            self.containerView.frame.origin.y = originY
                        }
                        UIView.perform(.delete, on: [], options: [], animations: animations, completion: nil)
                    }
                default:
                    break
                }
                let rate = (containerView.frame.origin.y - (originY))  / (containerView.frame.height)
                overlayView.alpha = max(0, min(1, (1 - rate)))
            case .showAll:
                switch gestureRecognizer.state {
                case .began:
                    scrollView?.isScrollEnabled = false
                case .changed:
                    let currentTransformY = containerView.transform.ty
                    containerView.transform = CGAffineTransform(translationX: 0, y: currentTransformY + point.y)
                    gestureRecognizer.setTranslation(.zero, in: gestureView)
                case .ended, .cancelled:
                    scrollView?.isScrollEnabled = true
                    if containerView.transform.ty > moveRange.down {
                        dismiss()
                    } else {
                        let animations = {
                            self.containerView.transform = CGAffineTransform.identity
                        }
                        UIView.perform(.delete, on: [], options: [], animations: animations, completion: nil)
                    }
                default:
                    break
                }
            default:
                break
            }
        }
    }
}

// MARK: - private
private extension BottomsheetController {
    func configure() {
        view.frame.size = UIScreen.main.bounds.size
        transitioningDelegate = self
        modalPresentationStyle = .overCurrentContext
        modalPresentationCapturesStatusBarAppearance = true
        overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        overlayView.frame = UIScreen.main.bounds
        view.addSubview(overlayView)
        containerView.transform = CGAffineTransform(translationX: 0, y: initializeHeight)
        view.addSubview(containerView)
    }
    
    func configureConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: initializeHeight)
        let rightConstraint = NSLayoutConstraint(item: containerView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        let leftConstraint = NSLayoutConstraint(item: containerView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0)
        let bottomLayoutConstraint = NSLayoutConstraint(item: containerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraints([heightConstraint, rightConstraint, leftConstraint, bottomLayoutConstraint])
        self.containerViewHeightConstraint = heightConstraint
    }
    
    func newState(_ state: State) {
        switch state {
        case .hide:
            removeGesture(state)
            addGesture(state)
        case .show:
            removeGesture(state)
            addGesture(state)
        case .showAll:
            removeGesture(state)
            addGesture(state)
        }
        transform(state)
    }
    
    func transform(_ state: State) {
        guard !isNeedLayout else { return }
        switch state {
        case .hide:
            guard let containerViewHeightConstraint = containerViewHeightConstraint else { return }
            let animations: (() -> Void) = {
                self.containerView.transform = CGAffineTransform(translationX: 0, y: containerViewHeightConstraint.constant)
            }
            let completion: ((Bool) -> Void) = { [weak self] in
                guard $0 else { return }
                self?.dismiss(animated: true, completion: nil)
            }
            UIView.animate(withDuration: duration.hide, delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
        case .show:
            let animations: (() -> Void) = {
                self.containerView.transform = CGAffineTransform.identity
            }
            UIView.animate(withDuration: duration.show, delay: 0, options: .curveEaseInOut, animations: animations, completion: nil)
        case .showAll:
            containerViewHeightConstraint?.constant = maxHeight
            let animations: (() -> Void) = {
                self.view.layoutIfNeeded()
            }
            UIView.animate(withDuration: duration.showAll, delay: 0, options: .curveEaseInOut, animations: animations, completion: nil)
        }
    }
    
    func adjustLayout() {
        guard isNeedLayout else { return }
        isNeedLayout = false
        if let bar = bar {
            containerView.bringSubviewToFront(bar)
        }
        configureGesture()
        state = .show
    }
    
    func configureGesture() {
        overlayViewTapGestureRecognizer.addTarget(self, action: #selector(BottomsheetController.handleTap(_:)))
    }
    
    func addGesture(_ state: State) {
        switch viewActionType {
        case .swipe:
            overlayView.addGestureRecognizer(overlayViewPanGestureRecognizer)
        case .tappedPresent, .tappedDismiss:
            overlayView.addGestureRecognizer(overlayViewTapGestureRecognizer)
        }
        switch state {
        case .hide:
            break
        case .show:
            bar?.addGestureRecognizer(barGestureRecognizer)
            guard scrollView == nil || !isScrollEnabledInSheet else { return }
            containerView.addGestureRecognizer(panGestureRecognizer)
        case .showAll:
            bar?.addGestureRecognizer(barGestureRecognizer)
            containerView.addGestureRecognizer(panGestureRecognizer)
        }
    }
    func removeGesture(_ state: State) {
        switch state {
        case .hide:
            overlayView.removeGestureRecognizer(overlayViewPanGestureRecognizer)
            overlayView.removeGestureRecognizer(overlayViewTapGestureRecognizer)
            containerView.removeGestureRecognizer(panGestureRecognizer)
            bar?.removeGestureRecognizer(barGestureRecognizer)
        case .show:
            bar?.removeGestureRecognizer(barGestureRecognizer)
            containerView.removeGestureRecognizer(panGestureRecognizer)
        case .showAll:
            overlayView.removeGestureRecognizer(overlayViewPanGestureRecognizer)
            overlayView.removeGestureRecognizer(overlayViewTapGestureRecognizer)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BottomsheetController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollView = scrollView, let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer , state == .showAll else {
            return true
        }
        let gestureView = gestureRecognizer.view
        let point = gestureRecognizer.translation(in: gestureView)
        let contentOffset = scrollView.contentOffset.y + scrollView.contentInset.top
        return contentOffset == 0 && point.y > 0
    }
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension BottomsheetController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomsheetTransitionAnimator(present: true)
    }
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomsheetTransitionAnimator(present: false)
    }
}

// MARK: - TransitionAnimator
extension Bottomsheet {
    class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
        fileprivate var presentDuration: TimeInterval = 0.0
        fileprivate var dismissDuration: TimeInterval = 0.0
        fileprivate var present: Bool?
        convenience init(present: Bool, presentDuration: TimeInterval = 0.3, dismissDuration: TimeInterval = 0.3) {
            self.init()
            self.present = present
            self.presentDuration = presentDuration
            self.dismissDuration = dismissDuration
        }
        open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            if present == true {
                return presentDuration
            } else {
                return dismissDuration
            }
        }
        open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
            if present == true {
                presentAnimation(transitionContext)
            } else {
                dismissAnimation(transitionContext)
            }
        }
        // private
        fileprivate func presentAnimation(_ transitionContext: UIViewControllerContextTransitioning) {
            guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? BottomsheetController else {
                transitionContext.completeTransition(false)
                return
            }
            let containerView = transitionContext.containerView
            containerView.backgroundColor = .clear
            containerView.addSubview(toVC.view)
            toVC.overlayView.alpha = 0
            let animations = {
                toVC.overlayView.alpha = 1
            }
            let completion: ((Bool) -> Void) = { finished in
                guard finished else { return }
                let cancelled = transitionContext.transitionWasCancelled
                if cancelled {
                    toVC.view.removeFromSuperview()
                }
                transitionContext.completeTransition(!cancelled)
            }
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
        }
        fileprivate func dismissAnimation(_ transitionContext: UIViewControllerContextTransitioning) {
            guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? BottomsheetController else {
                transitionContext.completeTransition(false)
                return
            }
            let animations = {
                fromVC.overlayView.alpha = 0
            }
            let completion: ((Bool) -> Void) = { finished in
                guard finished else { return }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: animations, completion: completion)
        }
    }
}
