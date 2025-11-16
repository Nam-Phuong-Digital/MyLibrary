//
//  PopoverNavigationController.swift
//  
//
//  Created by Dai Pham on 18/02/2024.
//

import UIKit

public class PopoverNavigationController: UINavigationController {

    private var root: UIViewController!
    private var sourceView:Any?
    
    public init(root: UIViewController, sourceView:Any?) {
        self.root = root
        self.sourceView = sourceView
        super.init(nibName: "PopoverNavigationController", bundle: .module)
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            pop.delegate = self
            if let sourceView = sourceView as? UIView {
                pop.sourceRect = sourceView.bounds
                pop.sourceView = sourceView
            } else if let sourceView = sourceView as? UIBarButtonItem {
                if #available(iOS 16, *) {
                    pop.sourceItem = sourceView
                } else {
                    pop.barButtonItem = sourceView
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.viewControllers = [root]
        
        if #unavailable(iOS 26) {
            if #available(iOS 13.0, *) {
                self.navigationBar.scrollEdgeAppearance = .standard
            } else {
                self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
                self.navigationBar.backgroundColor = Resource.Color.tertiary
                navigationController?.navigationBar.setBackgroundImage(Resource.Color.tertiary?.imageRepresentation, for: .default)
                navigationController?.navigationBar.shadowImage = UIImage()
                navigationController?.view.backgroundColor = Resource.Color.tertiary
                self.navigationController?.navigationBar.isTranslucent = false
            }
            
            self.navigationController?.navigationBar.barTintColor = Resource.Color.tertiary
            self.navigationController?.view.backgroundColor = Resource.Color.tertiary
            self.navigationController?.navigationBar.tintColor = Resource.Color.onTertiary
        }
    }
}

extension PopoverNavigationController: UIPopoverPresentationControllerDelegate {
    public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        if let sourceView = sourceView as? UIView {
            popoverPresentationController.sourceView = sourceView
        } else if let sourceView = sourceView as? UIBarButtonItem {
            if #available(iOS 16, *) {
                popoverPresentationController.sourceItem = sourceView
            } else {
                popoverPresentationController.barButtonItem = sourceView
            }
        }
    }
    
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        true
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            return .none
        }
}

@available(iOS 13,*)
fileprivate extension UINavigationBarAppearance {
    static var standard:UINavigationBarAppearance {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : Resource.Color.onTertiary ?? .white]
        if #available(iOS 14, *) {
            if #available(iOS 15, *) {
                navBarAppearance.backgroundColor = Resource.Color.tertiary
            } else {
                navBarAppearance.configureWithTransparentBackground()
                navBarAppearance.backgroundColor = Resource.Color.tertiary
            }
        } else {
            navBarAppearance.backgroundColor = Resource.Color.tertiary
        }
        return navBarAppearance
    }
}
