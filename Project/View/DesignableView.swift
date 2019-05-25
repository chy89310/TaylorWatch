//
//  DesignableView.swift
//  Taylor
//
//  Created by Kevin Sum on 18/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class DesignableView: UIView {
    
    var view: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        if (nib.instantiate(withOwner: self, options: nil).count > 0) {
            let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
            return view
        } else {
            return UIView(frame: .zero)
        }
    }
    
    func setup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth,
                                 UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)
    }
    
}
