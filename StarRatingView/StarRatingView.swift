//
//  StarRatingView.swift
//  StarRatingView
//
//  Created by Cory Wilhite on 7/25/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func tinted(by color: UIColor) -> UIImage {
        let scale = UIScreen.mainScreen().scale
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextTranslateCTM(context, 0, size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        CGContextSetBlendMode(context, .Normal)
        CGContextDrawImage(context, rect, CGImage)
        CGContextClipToMask(context, rect, CGImage)
        
        CGContextSetBlendMode(context, .Multiply)
        
        color.setFill()
        
        CGContextFillRect(context, rect)
        
        let tinted = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return tinted
    }
}

func createSplitImage(leftImage leftImage: UIImage?, rightImage: UIImage?, fillPercentage: CGFloat = 0.50) -> UIImage? {
    guard (0...1).contains(fillPercentage) else { return nil }
    guard let leftImage = leftImage, rightImage = rightImage else { return nil }
    guard leftImage.size == rightImage.size else { return nil }
    
    let finalImageSize = leftImage.size
    let scale = leftImage.scale
    
    UIGraphicsBeginImageContextWithOptions(finalImageSize, false, scale)
    
    let context = UIGraphicsGetCurrentContext()
    
    leftImage.drawAtPoint(.zero)
    
    let rect = CGRect(
        x: finalImageSize.width * fillPercentage,
        y: 0,
        width: finalImageSize.width * 1 - fillPercentage,
        height: finalImageSize.height
    )
    
    CGContextClipToRect(context, rect)
    rightImage.drawAtPoint(.zero)
    
    let splitImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return splitImage
}

@IBDesignable
class StarRatingView: UIView {
    
    enum Count: Int {
        case three = 3, four, five
    }
    
    @IBInspectable var starImage: UIImage? = UIImage(named: "small-star") {
        didSet {
            generateStars(starCount: _starCount)
            update(rating: rating)
        }
    }
    
    @IBInspectable var starCount: Int = 5 {
        didSet {
            if (3...5).contains(starCount) {
                _starCount = Count(rawValue: starCount)!
            }
        }
    }
    
    private var _starCount: Count = .five {
        didSet {
            generateStars(starCount: _starCount)
            update(rating: rating)
        }
    }
    
    @IBInspectable var rating: Float = 0 {
        didSet {
            update(rating: rating)
        }
    }
    
    private(set) var starImageViews: [UIImageView] = [] {
        didSet {
            if starConstraints.isEmpty == false {
                NSLayoutConstraint.deactivateConstraints(starConstraints)
                starConstraints = []
                setNeedsUpdateConstraints()
            }
        }
    }
    
    @IBInspectable var highlightColor: UIColor = .redColor() {
        didSet {
            generateStars(starCount: _starCount)
            update(rating: rating)
        }
    }
    
    @IBInspectable var normalColor: UIColor = .lightGrayColor() {
        didSet {
            generateStars(starCount: _starCount)
            update(rating: rating)
        }
    }
    
    @IBInspectable var horizontalPadding: CGFloat = 8 {
        didSet {
            generateStars(starCount: _starCount)
            update(rating: rating)
        }
    }
    
    required init(stars: Count, highlightColor: UIColor, normalColor: UIColor) {
        super.init(frame: .zero)
        self.highlightColor = highlightColor
        self.normalColor = normalColor
        _starCount = stars
        generateStars(starCount: stars)
    }
    
    convenience init(stars: Count) {
        self.init(stars: stars, highlightColor: .redColor(), normalColor: .lightGrayColor())
    }
    
    convenience init(highlightColor: UIColor, normalColor: UIColor) {
        self.init(stars: .five, highlightColor: highlightColor, normalColor: normalColor)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        generateStars(starCount: _starCount)
        update(rating: 0)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        generateStars(starCount: _starCount)
        update(rating: 0)
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        generateStars(starCount: _starCount)
        update(rating: rating)
        setNeedsUpdateConstraints()
    }
    
    func generateStars(starCount starCount: Count) {
        
        if starImageViews.isEmpty == false {
            for star in starImageViews {
                NSLayoutConstraint.deactivateConstraints(star.constraints)
                star.removeFromSuperview()
            }
        }
        
        
        let stars: [UIImageView] = (0..<starCount.rawValue).map { index in
            
            let image = starImage?.tinted(by: normalColor)
            let imageView = UIImageView(image: image)
            imageView.contentMode = .Center
            self.addSubview(imageView)
            
            return imageView
        }
        
        starImageViews = stars
        
        
    }
    
    func update(rating rating: Float) -> Void {
        
        for index in 1...starImageViews.count {
            let star = starImageViews[index - 1]
            
            let normalStar = starImage?.tinted(by: normalColor)
            let highlightStar = starImage?.tinted(by: highlightColor)
            
            let floatIndex = Float(index)
            
            if floatIndex <= fabs(rating) {
                star.image = highlightStar
            } else {
                if floatIndex - rating > 0 && floatIndex - rating < 1 {
                    let fillPercentage = 1 - CGFloat(floatIndex - rating)
                    star.image = createSplitImage(leftImage: highlightStar, rightImage: normalStar, fillPercentage: fillPercentage)
                } else {
                    star.image = normalStar
                }
            }
        }
        
    }
    
    private(set) var starConstraints: [NSLayoutConstraint] = []
    
    override func updateConstraints() {
        
        if starConstraints.isEmpty == true {
            
            for index in 0..<starImageViews.count {
                
                let currentStar: UIImageView
                let previousStar: UIImageView
                
                if index == 0 {
                    
                    currentStar = starImageViews[index]
                    currentStar.translatesAutoresizingMaskIntoConstraints = false
                    
                    let leading = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Leading,
                        relatedBy: .GreaterThanOrEqual,
                        toItem: self,
                        attribute: .Leading,
                        multiplier: 1,
                        constant: 0
                    )
                    
                    let top = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Top,
                        relatedBy: .Equal,
                        toItem: self,
                        attribute: .Top,
                        multiplier: 1,
                        constant: 0
                    )
                    
                    let bottom = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Bottom,
                        relatedBy: .Equal,
                        toItem: self,
                        attribute: .Bottom,
                        multiplier: 1,
                        constant: 0
                    )
                    let constraints = [leading, top, bottom]
                    addConstraints(constraints)
                    starConstraints.appendContentsOf(constraints)
                    
                } else if index == starImageViews.count - 1 {
                    
                    currentStar = starImageViews[index]
                    currentStar.translatesAutoresizingMaskIntoConstraints = false
                    
                    previousStar = starImageViews[index - 1]
                    previousStar.translatesAutoresizingMaskIntoConstraints = false
                    
                    let leading = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Leading,
                        relatedBy: .Equal,
                        toItem: previousStar,
                        attribute: .Trailing,
                        multiplier: 1,
                        constant: horizontalPadding
                    )
                    
                    let top = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Top,
                        relatedBy: .Equal,
                        toItem: self,
                        attribute: .Top,
                        multiplier: 1,
                        constant: 0
                    )
                    
                    let bottom = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Bottom,
                        relatedBy: .Equal,
                        toItem: self,
                        attribute: .Bottom,
                        multiplier: 1,
                        constant: 0
                    )
                    
                    let trailing = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Trailing,
                        relatedBy: .GreaterThanOrEqual,
                        toItem: self,
                        attribute: .Trailing,
                        multiplier: 1,
                        constant: 0
                    )
                    
                    let constraints = [leading, top, bottom, trailing]
                    addConstraints(constraints)
                    starConstraints.appendContentsOf(constraints)
                    
                } else {
                    currentStar = starImageViews[index]
                    currentStar.translatesAutoresizingMaskIntoConstraints = false
                    
                    previousStar = starImageViews[index - 1]
                    previousStar.translatesAutoresizingMaskIntoConstraints = false
                    
                    let leading = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Leading,
                        relatedBy: .Equal,
                        toItem: previousStar,
                        attribute: .Trailing,
                        multiplier: 1,
                        constant: horizontalPadding
                    )
                    
                    let top = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Top,
                        relatedBy: .Equal,
                        toItem: self,
                        attribute: .Top,
                        multiplier: 1,
                        constant: 0
                    )
                    
                    let bottom = NSLayoutConstraint(
                        item: currentStar,
                        attribute: .Bottom,
                        relatedBy: .Equal,
                        toItem: self,
                        attribute: .Bottom,
                        multiplier: 1,
                        constant: 0
                    )
                    
                    let constraints = [leading, top, bottom]
                    addConstraints(constraints)
                    starConstraints.appendContentsOf(constraints)
                }
            }
            
        }
        
        super.updateConstraints()
    }
    
    
    override func intrinsicContentSize() -> CGSize {
        let count = CGFloat(starImageViews.count)
        guard count != 0, let firstStar = starImageViews.first else { return .zero }
        
        let firstStarIntrinsicSize = firstStar.intrinsicContentSize()
        
        let padding = horizontalPadding * (count - 1)
        
        let contentSize = CGSize(width: (firstStarIntrinsicSize.width * count) + padding, height: firstStarIntrinsicSize.height)
        
        return contentSize
    }
}