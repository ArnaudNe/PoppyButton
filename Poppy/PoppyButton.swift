//
//  PoppyButton.swift
//  Poppy
//
//  Created by Arnaud Nelissen on 02/04/2016.
//  Copyright © 2016 Arnaud Nelissen. All rights reserved.
//

import UIKit

public protocol PoppyDataSource {
    func numberOfPickForPoppyButton(button: PoppyButton) -> Int
    
    func pickViewForPoppyButton(button: PoppyButton, atIndex index: Int) -> UIView
    func pickTitleForPoppyButton(button: PoppyButton, atIndex index: Int) -> String?
}

public protocol PoppyDelegate {
    func poppyButton(button: PoppyButton, selectedPickAtIndex index: Int) -> Void
    func poppyButton(button: PoppyButton, highlightedPickAtIndex index: Int) -> Void
    func poppyButtonUnhighlightedPick(button: PoppyButton) -> Void
    func poppyButtonBeganSelection(button: PoppyButton) -> Void
    func poppyButtonEndedSelection(button: PoppyButton) -> Void
}

public class PoppyButton: UIButton {
    public var animationDuration: Double = 0.125
    public var appearanceDuration: Double = 0.15
    public var margin: (side: CGFloat, selector: CGFloat) = (side: 20, selector: 20)
    public var spacing: CGFloat = 6
    
    public var pickDiameter: CGFloat = 50.0
    public var focusRatio: CGFloat = 1.25
    public var minimizeFocusRatio: CGFloat = 0.95
    
    public var selectorBgView: UIView!
    
    public var selectorBgViewHeight: CGFloat {
        get {
            return CGFloat(pickDiameter + 2 * spacing)
        }
    }
    
    public var delegate: PoppyDelegate?
    public var dataSource: PoppyDataSource? {
        didSet {
            reloadData()
        }
    }
    
    public var selecting: Bool = false
    public var highlighting: Bool = false
    
    private var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    private var picks = [PoppyPick]() {
        didSet {
            for pick in picks {
                pick.configureView()
            }
        }
    }
    
    private var selectedPick: PoppyPick? {
        didSet {
            guard selectedPick != oldValue else { return }
            
            oldValue?.unselect(animationDuration)
            selectedPick?.select(animationDuration)

            guard let selectedPick = selectedPick, index = picks.indexOf(selectedPick) else {
                print("UNSELECT")
                
                highlighting = false
                if self.selecting {
                    self.delegate?.poppyButtonUnhighlightedPick(self)
                }
                
                // Go back to normal appearance
                UIView.animateWithDuration(animationDuration, delay: 0, options: [.AllowUserInteraction, .CurveEaseInOut], animations: {
                    for pick in self.picks {
                        let actualPickIndex = self.picks.indexOf(pick)!
                        pick.frame = self.getNormalFrameForPickAtIndex(actualPickIndex)
                        self.animateCornerRadius(pick.icon.layer, to: CGRectGetWidth(pick.frame)/2, duration: self.animationDuration, timing: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
                    }
                    
                    self.selectorBgView.frame = self.getNormalFrameForSelectorBGView()
                    self.animateCornerRadius(self.selectorBgView.layer, to: CGRectGetHeight(self.selectorBgView.frame)/2, duration: self.animationDuration, timing: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
                    
                }, completion: nil)
                
                return
            }

            print("SELECTED PICK AT INDEX : \(picks.indexOf(selectedPick)!)")
            
            highlighting = true
            delegate?.poppyButton(self, highlightedPickAtIndex: index)

            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(animationDuration)
            UIView.setAnimationCurve(UIViewAnimationCurve.EaseInOut)
            UIView.setAnimationBeginsFromCurrentState(true)

            selectedPick.frame = getNormalFrameForPickAtIndex(index)
            let inset = pickDiameter * (focusRatio - 1)
            selectedPick.frame.insetInPlace(dx: -inset, dy: -inset)
            selectedPick.frame.offsetInPlace(dx: 0, dy: -(CGRectGetWidth(selectedPick.frame)-pickDiameter)/2 - spacing/2)
            
            
            if index <= (picks.count/2 - 1) {
                // Selected pick on left side
                
                selectedPick.frame.offsetInPlace(dx: minimizeFocusRatio * spacing * CGFloat(picks.count - index - 1) / 2, dy: 0)
//                let indexDifference = CGFloat(index - picks.count/2 - 1)
//                selectedPick.frame.offsetInPlace(dx: -inset / (2*indexDifference), dy: 0)
                
//                let totalLeft = CGFloat(index)
//                let leftCount = CGFloat(actualPickIndex)
//                selectedPick.frame.offsetInPlace(dx: inset, dy: 0)
            } else if index >= (picks.count/2 + picks.count%2) {
                // Selected pick on right side
                
                selectedPick.frame.offsetInPlace(dx: -minimizeFocusRatio * spacing * CGFloat(index) / 2, dy: 0)
//                let indexDifference = CGFloat(index - (picks.count/2 + picks.count%2))
//                selectedPick.frame.offsetInPlace(dx: inset / (2*indexDifference), dy: 0)
                
//                let rightCount = CGFloat(picks.count - actualPickIndex - 1)
//                let totalRight = CGFloat(picks.count - index - 1)
//                selectedPick.frame.offsetInPlace(dx: -inset/2, dy: 0)

            }
            
            // Animate selected pick corner radius
            self.animateCornerRadius(selectedPick.icon.layer, to: CGRectGetWidth(selectedPick.frame)/2, duration: animationDuration, timing: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))

            
            // Animate all other picks
            for pick in picks where pick != selectedPick {
                let actualPickIndex = picks.indexOf(pick)!
                pick.frame = getNormalFrameForPickAtIndex(actualPickIndex)
                
                // Inset
                pick.frame.insetInPlace(dx: pickDiameter * (1-minimizeFocusRatio), dy: pickDiameter * (1-minimizeFocusRatio))
                self.animateCornerRadius(pick.icon.layer, to: CGRectGetWidth(pick.frame)/2, duration: animationDuration, timing: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))

                // Shift left or right depending on selected pick index
                if actualPickIndex < index {
                    // Left pick
                    pick.frame.offsetInPlace(dx: -focusRatio * spacing * CGFloat(actualPickIndex), dy: 0)
//                    let totalLeft = CGFloat(index)
//                    let leftCount = CGFloat(actualPickIndex)
//                    pick.frame.offsetInPlace(dx: -inset * leftCount / (totalLeft), dy: 0)
                } else {
                    // Right pick
                    pick.frame.offsetInPlace(dx: focusRatio * spacing * CGFloat(picks.count - actualPickIndex - 1), dy: 0)
//                    let rightCount = CGFloat(picks.count - actualPickIndex - 1)
//                    let totalRight = CGFloat(picks.count - index - 1)
//
//                    pick.frame.offsetInPlace(dx: inset * rightCount / (totalRight), dy: 0)
                }
            }
            
            // Animate selector background view
            selectorBgView.frame = getNormalFrameForSelectorBGView()
            selectorBgView.frame.insetInPlace(dx: spacing, dy: spacing)
            self.animateCornerRadius(selectorBgView.layer, to: CGRectGetHeight(selectorBgView.frame)/2, duration: animationDuration, timing: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
            
            UIView.commitAnimations()
        }
    }
    
    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        selectorBgView = UIView(frame: frame)
        self.layer.masksToBounds = false
        self.clipsToBounds = false
        
        configure()
        reloadData()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        selectorBgView = UIView(coder: aDecoder)
        self.layer.masksToBounds = false
        self.clipsToBounds = false
        
        configure()
        reloadData()
    }
    
    
    // MARK: Public methods
    public func reloadData() -> Void {
        // Remove from superview and clear array
        selectorBgView.removeFromSuperview()
        for pick in picks {
            pick.removeFromSuperview()
        }
        
        picks.removeAll()
        
        guard let dataSource = self.dataSource else {
            return
        }
        
        let picksCount = dataSource.numberOfPickForPoppyButton(self)
        
        for index in 0...picksCount-1 {
            let view = dataSource.pickViewForPoppyButton(self, atIndex: index)
            let title = dataSource.pickTitleForPoppyButton(self, atIndex: index)
            let pick = PoppyPick(diameter: pickDiameter, title: title)
            view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            //            pick.icon.autoresizesSubviews = true
            pick.icon.addSubview(view)
            picks.append(pick)
        }
        
        configureView()
    }
    
    public func beginSelection() -> Void {
        
        self.selectorBgView.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(selectorBgView.frame)/2)
        self.selectorBgView.alpha = 0
        
        // Make all picks appear to normal position
        self.selectorBgView.hidden = false
        for pick in picks {
            pick.transform = CGAffineTransformMakeTranslation(0, CGRectGetWidth(pick.frame))
            pick.transform = CGAffineTransformScale(pick.transform, 1/3, 1/3)
            pick.alpha = 0
            pick.hidden = false
            
            let delay = (Double(picks.indexOf(pick)!) / Double(picks.count - 1)) * (appearanceDuration) * 1.5
            UIView.animateWithDuration(appearanceDuration, delay: delay, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                pick.alpha = 1
                pick.transform = CGAffineTransformIdentity
            }) { (_) in
                
            }
        }
        
        // Make selector background view appear
        UIView.animateWithDuration(appearanceDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.selectorBgView.alpha = 1
            self.selectorBgView.transform = CGAffineTransformIdentity
        }) { (_) in
            
        }
        
        selecting = true
        delegate?.poppyButtonBeganSelection(self)
    }
    
    public func endSelection() -> Void {
        
        // If selected pick exist, launch special animation for selected pick
        if let selectedPick = selectedPick, index = picks.indexOf(selectedPick) {
            selectedPick.unselect(animationDuration)
            
            delegate?.poppyButton(self, selectedPickAtIndex: index)
            
            selectedPick.transform = CGAffineTransformIdentity
            selectedPick.alpha = 1
            
            
            // old style: layer.renderInContext(UIGraphicsGetCurrentContext())
            
            
            let delay: Double = appearanceDuration * 2
            UIView.animateWithDuration(appearanceDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.imageView?.alpha = 0
                self.titleLabel?.alpha = 0
            }) { (_) in
            }
            
            UIView.animateWithDuration(appearanceDuration, delay: delay, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                //selectedPick.alpha = 0
//                selectedPick.transform = CGAffineTransformMakeTranslation(0, CGRectGetWidth(selectedPick.frame))
//                selectedPick.transform = CGAffineTransformScale(selectedPick.transform, 1/3, 1/3)
//                let size = image.size
                let size = CGSize(width: self.pickDiameter, height: self.pickDiameter)
                
                selectedPick.frame = CGRectMake(self.bounds.midX - size.width/2, self.bounds.midY - size.height/2, size.width, size.height)
                self.animateCornerRadius(selectedPick.icon.layer, to: self.pickDiameter/2, duration: self.appearanceDuration, delay: delay, timing: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
                
            }) { (_) in
                
                UIGraphicsBeginImageContextWithOptions(selectedPick.bounds.size, false, UIScreen.mainScreen().scale)
                selectedPick.drawViewHierarchyInRect(selectedPick.bounds, afterScreenUpdates: true)
                
                let image = UIGraphicsGetImageFromCurrentImageContext().imageWithRenderingMode(.AlwaysOriginal)
                UIGraphicsEndImageContext()
                self.setImage(image, forState: .Normal)
                self.setTitle(nil, forState: .Normal)
                self.titleLabel?.alpha = 1
                self.imageView?.alpha = 1
                
                selectedPick.hidden = true
                selectedPick.transform = CGAffineTransformIdentity
                self.selectedPick = nil
            }
            
        }
        
        self.selectorBgView.transform = CGAffineTransformIdentity
        self.selectorBgView.alpha = 1
        
        self.selectorBgView.hidden = false
        
        // Make all other picks and selector background view disappear
        for pick in picks where pick != selectedPick {
            pick.transform = CGAffineTransformIdentity
            pick.alpha = 1
            
            let delay: Double = (Double(picks.indexOf(pick)!) / Double(picks.count - 1)) * (appearanceDuration) * 1.5
            UIView.animateWithDuration(appearanceDuration/2, delay: delay, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                pick.alpha = 0
                pick.transform = CGAffineTransformMakeTranslation(0, CGRectGetWidth(pick.frame))
                pick.transform = CGAffineTransformScale(pick.transform, 1/3, 1/3)
            }) { (_) in
                pick.hidden = true
                pick.transform = CGAffineTransformIdentity
            }
        }
        
        UIView.animateWithDuration(appearanceDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.selectorBgView.alpha = 0
            self.selectorBgView.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.selectorBgView.frame)/2)
        }) { (_) in
            self.selectorBgView.hidden = true
            self.selectorBgView.transform = CGAffineTransformIdentity
        }
        
        selecting = false
        delegate?.poppyButtonEndedSelection(self)
    }
    
    public func highlightPickAtIndex(index: Int) -> Void {
        guard index < picks.count else {
            selectedPick = nil
            return
        }
        
        selectedPick = picks[index]
    }
    
    public func indexOfHighlightedPick() -> Int? {
        guard let selectedPick = selectedPick else { return nil }
        
        return picks.indexOf(selectedPick)
    }
    
    
    // MARK: Private methods
    
    // MARK: Animations
    private func animateCornerRadius(layer: CALayer, to: CGFloat, duration: Double, delay: Double, timing: CAMediaTimingFunction) {
        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.timingFunction = timing
        animation.fromValue = NSNumber(float: Float(layer.cornerRadius))
        animation.toValue = NSNumber(float: Float(to))
        animation.removedOnCompletion = false
        animation.duration = duration
        animation.fillMode = kCAFillModeBackwards
        if (delay > 0) {
            animation.beginTime = CACurrentMediaTime() + delay
        }
        layer.addAnimation(animation, forKey: "cornerRadius")
        
        layer.cornerRadius = to
    }
    
    private func animateCornerRadius(layer: CALayer, to: CGFloat, duration: Double, timing: CAMediaTimingFunction) {
        animateCornerRadius(layer, to: to, duration: duration, delay: 0, timing: timing)
    }
    
    // MARK: Touches and gestures
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        print("Touch began")
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        
        if selecting {
            // Compute which pick are we under
            guard let location = touches.first?.locationInView(self) else { return }
            
            if location.y < self.bounds.midY {
                for pick in picks {
                    if location.x > pick.frame.minX - spacing/2 && location.x <= pick.frame.maxX + spacing/2 {
                        selectedPick = pick
                    }
                }
                
            } else {
                // User is under button -> unselect
                selectedPick = nil
            }
        }
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        print("Touch ended")
        
        if selecting {
            endSelection()
        }
    }
    
    override public func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        
        print("Touch cancelled")
        
        if selecting {
            endSelection()
        }
    }
    
    @objc private func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .Began:
            print("Long Press")
            beginSelection()
            
        default:
            break
        }
    }
    
    // MARK: Configuration
    private func configure() -> Void {
        // Bring the button to front
        self.layer.zPosition = 1
        
        // Initialize long press gesture recognizer`
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        longPressGestureRecognizer.cancelsTouchesInView = false
        self.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    private func configureView() -> Void {
        // Configure views smartly
        selectorBgView.frame = getNormalFrameForSelectorBGView()
        selectorBgView.layer.cornerRadius = selectorBgView.frame.height/2
        selectorBgView.layer.masksToBounds = true
        
        selectorBgView.backgroundColor = UIColor(white: 1, alpha: 0.85)
        
        selectorBgView.hidden = true
        self.addSubview(selectorBgView)
        self.bringSubviewToFront(selectorBgView)
        
        var oldX = selectorBgView.frame.origin.x + spacing
        for pick in picks {
            pick.frame = getNormalFrameForPickAtIndex(picks.indexOf(pick)!)
            
            pick.icon.layer.cornerRadius = CGRectGetWidth(pick.icon.frame)/2
            
            pick.hidden = true
            pick.configureView()
            
            self.addSubview(pick)
            self.bringSubviewToFront(pick)
            
            oldX += (pickDiameter + spacing)
        }
    }
    
    private func getNormalFrameForPickAtIndex(index: Int) -> CGRect {
        let selectorFrame = getNormalFrameForSelectorBGView()
        
        return CGRectMake(selectorFrame.origin.x + spacing + (pickDiameter + spacing) * CGFloat(index), selectorFrame.origin.y + spacing, pickDiameter, pickDiameter)
    }
    
    private func getNormalFrameForSelectorBGView() -> CGRect {
        let rawWidth: CGFloat = (pickDiameter + spacing) * CGFloat(picks.count) + spacing
        let rawHeight = pickDiameter + 2 * spacing
        let xOffset = self.frame.width/2
        
        return CGRectMake(xOffset-rawWidth/2, self.bounds.origin.y - rawHeight - margin.selector, rawWidth, rawHeight)
    }
    
    
}



private class PoppyPick: UIView {
    var label: UILabel?
    var labelBackgroundView: UIView?
    var icon: UIView
    
    var selected = false
    let labelHeight: CGFloat = 15
    var title: String? {
        didSet {
            label?.text = title
            label?.adjustsFontSizeToFitWidth = true
            label?.textColor = UIColor(white: 1, alpha: 0.95)
            label?.font = UIFont(name: "AvenirNext-Regular", size: 15.0)
        }
    }
    
    private var labelSpacing: CGFloat = 5
    private var labelWidth: CGFloat = 100
    
    override var frame: CGRect {
        didSet {
            let labelFrame = CGRectMake(icon.bounds.midX - labelWidth/2, icon.frame.origin.y - labelHeight - labelSpacing, labelWidth, labelHeight)
            
            label?.bounds = labelFrame
            
            if let label = label {
                let labelTextHeight = label.intrinsicContentSize().height
                let labelTextWidth = label.intrinsicContentSize().width + labelTextHeight/2

                let labelBackgroundFrame = CGRectMake(label.bounds.midX - labelTextWidth/2, label.frame.origin.y, labelTextWidth, labelTextHeight)
                
                labelBackgroundView?.bounds = labelBackgroundFrame
                labelBackgroundView?.center = label.center
                labelBackgroundView?.layer.cornerRadius = labelBackgroundFrame.height/2
            }
            
            icon.frame = bounds
        }
    }
    
    init(diameter: CGFloat, title: String?) {
        let iconFrame = CGRectMake(0, 0, diameter, diameter)
        icon = UIView(frame: iconFrame)
        
        super.init(frame: iconFrame)
        
        let labelFrame = CGRectMake(icon.frame.origin.x, icon.frame.origin.y, icon.frame.width, 20)
        self.label = UILabel(frame: labelFrame)
        labelBackgroundView = UIView(frame: labelFrame)
        
        self.addSubview(icon)
        self.addSubview(labelBackgroundView!)
        self.addSubview(label!)
        
        configureView()
        
        setTitle(title)
    }
    
    func setTitle(title: String?) {
        self.title = title
    }
    
    
    override init(frame: CGRect) {
        icon = UIView(frame: frame)
        
        super.init(frame: frame)
        
        self.label = UILabel(frame: frame)
        self.icon = UIView(frame: frame)
        labelBackgroundView = UIView(frame: frame)
        
        self.addSubview(icon)
        self.addSubview(labelBackgroundView!)
        self.addSubview(label!)
        
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        icon = UIView(coder: aDecoder)!
        
        super.init(coder: aDecoder)
        
        label = UILabel(coder: aDecoder)
        labelBackgroundView = UIView(coder: aDecoder)!
        
        self.addSubview(icon)
        self.addSubview(labelBackgroundView!)
        self.addSubview(label!)
        
        configureView()
    }
    
    private func configureView() -> Void {
        let labelFrame = CGRectMake(icon.frame.origin.x, icon.frame.origin.y - labelHeight - labelSpacing, icon.frame.width, labelHeight)
        
        label?.frame = labelFrame
        labelBackgroundView?.frame = labelFrame
        labelBackgroundView?.backgroundColor = UIColor(white: 0, alpha: 0.5)
        label?.textAlignment = .Center
        icon.frame = bounds
        
        icon.layer.cornerRadius = CGRectGetWidth(icon.frame)/2
        icon.layer.masksToBounds = true
        
        self.clipsToBounds = false
        self.layer.masksToBounds = false
        
        self.autoresizesSubviews = true
        label?.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        label?.hidden = true
        labelBackgroundView?.hidden = true
        
        print(labelFrame)
    }
    
    func select(animationDuration: Double) {
        guard selected == false else { return }
        selected = true
        
        guard let label = self.label, labelBackgroundView = labelBackgroundView else { return }
        
        print(label.frame)
        
//        let labelFrame = CGRectMake(icon.frame.origin.x, icon.frame.origin.y - labelHeight - labelSpacing, icon.frame.width, labelHeight)
//        label.bounds = labelFrame
        
//        label.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(label.frame))
//        label.transform = CGAffineTransformMakeScale(1/3, 1/3)
        
        label.alpha = 0
        label.hidden = false
        labelBackgroundView.alpha = 0
        labelBackgroundView.hidden = false
        
        label.layer.removeAllAnimations()
        labelBackgroundView.layer.removeAllAnimations()

        UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            
            label.alpha = 1
            label.hidden = false
            label.transform = CGAffineTransformIdentity
            labelBackgroundView.alpha = 1
            labelBackgroundView.hidden = false
            labelBackgroundView.transform = CGAffineTransformIdentity
        }) { (_) in
            label.hidden = false
            labelBackgroundView.hidden = false
        }
    }
    
    func unselect(animationDuration: Double) {
        guard selected == true else { return }
        selected = false
        
        guard let label = self.label, labelBackgroundView = labelBackgroundView else { return }
        
        print(label.frame)
        
        label.alpha = 1
        label.hidden = false
        labelBackgroundView.alpha = 1
        labelBackgroundView.hidden = false
        
        label.layer.removeAllAnimations()

        UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
//            label.transform = CGAffineTransformMakeTranslation(0, CGRectGetHeight(label.frame))
//            label.transform = CGAffineTransformMakeScale(1/3, 1/3)

            label.alpha = 0
            labelBackgroundView.alpha = 0
        }) { (_) in
            label.hidden = true
            labelBackgroundView.hidden = false
            
            label.transform = CGAffineTransformIdentity
            labelBackgroundView.transform = CGAffineTransformIdentity
        }
    }
}
