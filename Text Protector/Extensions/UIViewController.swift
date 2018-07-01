//
//  UIViewController.swift
//  Text Protector
//
//  Created by Eric Lewis on 6/26/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import UIKit

extension UIViewController {
    func findShadowImage(under view: UIView) -> UIImageView? {
        if view is UIImageView && view.bounds.size.height <= 1 {
            return (view as! UIImageView)
        }
        
        for subview in view.subviews {
            if let imageView = findShadowImage(under: subview) {
                return imageView
            }
        }
        return nil
    }
}
