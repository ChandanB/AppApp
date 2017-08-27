//
//  Extensions.swift
//  Match
//
//  Created by Chandan Brown on 1/30/17.
//  Copyright © 2017 Chandan B. All rights reserved.
//

import UIKit

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum stateOfVC {
    case minimized
    case fullScreen
    case hidden
}
enum Direction {
    case up
    case left
    case none
}


extension UIColor {
    static func rgb(_ red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
    
    static func rgbLessAlpha(_ red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 0.5)
    }
    
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(red: r/255, green: g/255, blue: b/255, alpha: 1)
    }
    
    func lighter(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage:CGFloat=30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func adjust(by percentage:CGFloat=30.0) -> UIColor? {
        var r:CGFloat=0, g:CGFloat=0, b:CGFloat=0, a:CGFloat=0;
        if(self.getRed(&r, green: &g, blue: &b, alpha: &a)){
            return UIColor(red: min(r + percentage/100, 1.0),
                           green: min(g + percentage/100, 1.0),
                           blue: min(b + percentage/100, 1.0),
                           alpha: a)
        }else{
            return nil
        }
    }
}


extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func addBlurEffect() {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        self.addSubview(blurEffectView)
    }
    
    func addLightBlurEffect() {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        self.addSubview(blurEffectView)
    }
    
    func addDarkBlurEffect() {
        // screen width and height:
        let blurEffect = UIBlurEffect(style: .prominent)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // for supporting device rotation
        self.addSubview(blurEffectView)
    }
}


public extension UIView {
    func moveDown(count : Float? = nil,for duration : TimeInterval? = nil,withTranslation translation : Float? = nil) {
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        
        animation.duration = (duration ?? 0.2)/TimeInterval(animation.repeatCount)
        animation.byValue = translation ?? 50
        animation.repeatCount = count ?? 1
        animation.autoreverses = false
        layer.add(animation, forKey: "moveDown")
    }
}


let imageCache = NSCache<NSString, UIImage>()
extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(_ urlString: String) {
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }
        
        //otherwise fire off a new download
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            //download hit an error so lets return out
            if error != nil {
                print(error as Any)
                return
            }
            
            DispatchQueue.main.async(execute: {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = downloadedImage
                    print("image downloaded")
                }
            })
            
        }).resume()
    }
}


public struct Constants {
    public static var Orientation: UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }
    public static var ScreenWidth: CGFloat {
        if UIInterfaceOrientationIsPortrait(Orientation) {
            return UIScreen.main.bounds.width
        } else {
            return UIScreen.main.bounds.height - 5
        }
    }
    public static var ScreenHeight: CGFloat {
        if UIInterfaceOrientationIsPortrait(Orientation) {
            return UIScreen.main.bounds.height
        } else {
            return UIScreen.main.bounds.width
        }
    }
    public static var StatusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
    public static var ScreenHeightWithoutStatusBar: CGFloat {
        if UIInterfaceOrientationIsPortrait(Orientation) {
            return UIScreen.main.bounds.height
        } else {
            return UIScreen.main.bounds.width
        }
    }
    public static let navigationBarHeight: CGFloat = 44
    public static let lightGrayColor = UIColor(red: 248, green: 248, blue: 248, alpha: 1)
}


func addConstraintsWithFormat(_ format: String, views: UIView...) {
    var viewsDictionary = [String: UIView]()
    for (index, view) in views.enumerated() {
        let key = "v\(index)"
        view.translatesAutoresizingMaskIntoConstraints = false
        viewsDictionary[key] = view
    }
    
    class CustomImageView: UIImageView {
        
        var imageUrlString: String?
        
        func loadImageUsingUrlString(_ urlString: String) {
            
            imageUrlString = urlString
            let url = URL(string: urlString)
            image = nil
            
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, respones, error) in
                
                if error != nil {
                    print(error as Any)
                    return
                }
                
                DispatchQueue.main.async(execute: {
                    
                    let imageToCache = UIImage(data: data!)
                    if self.imageUrlString == urlString {
                        self.image = imageToCache
                    }
                    
                })
                
            }).resume()
        }
        
    }
    
}


