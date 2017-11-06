//
//  AnimateTabView.swift
//
//  Created by ckjdev on 2016. 6. 27..
//  Copyright © 2016년 Yes24. All rights reserved.
//

import Foundation
import UIKit


@objc protocol AnimateTabViewDelegate : NSObjectProtocol {
    @objc optional func tabView(_ tabView:AnimateTabView, didSelectTabIndex index:Int)
}

@objcMembers
class AnimateTabView : UIView {
    fileprivate var _titles : NSArray!
    var titles : NSArray! {
        set {
            _titles = NSArray(array: newValue)
            
            if buttons != nil && buttons.count > 0 {
                for i in 0...buttons.count-1 {
                    let button = buttons.object(at: i) as! UIButton
                    button.removeFromSuperview()
                }
            }
            
            buttons = NSMutableArray()
            
            for i in 0..._titles.count-1 {
                let title = _titles.object(at: i) as! String
                let button = UIButton(type: UIButtonType.custom)
                button.backgroundColor = UIColor.clear
                button.titleLabel?.font = font
                button.tag = i
                button.setTitle(title, for: UIControlState())
                button.setTitleColor(titleColor, for: UIControlState())
                button.setTitleColor(tabTitleColor, for: UIControlState.selected)
                button.addTarget(self, action: #selector(AnimateTabView.onTab(_:)), for: .touchUpInside)
                scrollView.addSubview(button)
                buttons.add(button)
                
                button.isSelected = (i == currentIndex) ? true : false
            }
            
            layoutSubviews()
        }
        
        get {
            return _titles
        }
    }
    fileprivate var _tabColor = UIColor.blue
    var tabColor:UIColor! {
        set {
            _tabColor = newValue
            tabBackgroundView.backgroundColor = _tabColor;
        }
        
        get {
            return _tabColor
        }
    }
    var titleColor = UIColor.white
    var tabTitleColor = UIColor.black
    var tabBackgroundView : UIView!
    var currentIndex:Int = 0
    var font:UIFont = UIFont.systemFont(ofSize: 14)
    var tabed:Bool = false;
    var division:Bool = false
    var animate:Bool = true;
    var count:Int {
        get {
            return _titles.count
        }
    }
    weak var delegate:AnimateTabViewDelegate?
    
    fileprivate var buttons : NSMutableArray!
    fileprivate var scrollView : UIScrollView = UIScrollView()
    
    deinit {
        tabBackgroundView.removeObserver(self, forKeyPath: "frame")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var frame = self.frame;
        frame.origin.x = 0
        frame.origin.y = 0
        scrollView.frame = frame;
        
        if (self.titles.count > 0) {
            frame = CGRect.zero
            frame.size.height = scrollView.frame.size.height
            for i in 0..<buttons.count {
                let button = buttons[i] as! UIButton
                if division == true {
                    frame.size.width = self.frame.size.width / CGFloat(self.titles.count);
                }
                else {
                    if let label = button.titleLabel {
                        frame.size.width = label.text!.boundingRect(with: self.frame.size, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font:label.font], context: nil).size.width
                    }
                }
                
                button.frame = frame;
                
                // 프레임 바뀔때 탭프레임도 같이 선택된 프레임에 맞추어준다.
                if (i == currentIndex) {
                    var tabFrame = tabBackgroundView.frame;
                    tabFrame.origin.x = frame.origin.x;
                    tabFrame.size.width = frame.size.width;
                    tabBackgroundView.frame = tabFrame;
                }
                
                frame.origin.x += frame.size.width;
            }
            
            if (frame.origin.x > scrollView.frame.size.width) {
                scrollView.contentSize = CGSize(width: frame.origin.x, height: scrollView.frame.size.height)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath != nil else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
        if keyPath?.compare("frame") == .orderedSame && buttons != nil{
            if buttons == nil || buttons.count == 0 {
                currentIndex = 0;
                return;
            }
            
            let width = tabBackgroundView.frame.size.width
            let index = Int(floor((tabBackgroundView.frame.origin.x - width / 2) / width) + 1)
            if (index != currentIndex) {
                currentIndex = index
            
                for i in 0..<buttons.count {
                    let button = buttons.object(at: i) as! UIButton
                    if (currentIndex == button.tag) {
                        button.isSelected = true
                    }
                    else {
                        button.isSelected = false
                    }
                }
            }
        }
    }
    
    func initialize() {
        scrollView.isScrollEnabled = true;
        scrollView.bounces = true;
        scrollView.backgroundColor = UIColor.clear;
        scrollView.isUserInteractionEnabled = true;
        scrollView.showsHorizontalScrollIndicator = false;
        
        tabBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: self.frame.size.height))
        
        scrollView.addSubview(tabBackgroundView)
        addSubview(scrollView)
        
        tabBackgroundView.addObserver(self, forKeyPath: "frame", options:NSKeyValueObservingOptions.new, context: nil)
    }
    
    
    func moveTab(_ index:Int, force:Bool){
        selectIndex(index, force: force)
    }
    
    private func selectIndex(_ index:Int, force:Bool) {
        if (currentIndex == index && force == false) || index >= _titles.count {
            return;
        }
        
        self.tabed = true;
        
        let duration = (force || animate == false) ? 0.0 : 0.3
        
        UIView.animate(withDuration: Double(duration), animations: {
            let button = self.buttons.object(at: index) as! UIButton
            let maxOffsetX = button.frame.origin.x + button.frame.size.width
            var frame = button.frame
            frame.origin.y = self.tabBackgroundView.frame.origin.y
            frame.size.height = self.tabBackgroundView.frame.size.height
            self.tabBackgroundView.frame = frame
            
            if maxOffsetX > self.frame.size.width {
                self.scrollView.contentOffset = CGPoint(x: maxOffsetX - self.frame.size.width, y: 0)
            }
            else if self.tabBackgroundView.frame.origin.x < self.scrollView.contentOffset.x {
                self.scrollView.contentOffset = CGPoint(x: self.tabBackgroundView.frame.origin.x, y: 0)
            }
            
            if self.delegate != nil && (self.delegate?.responds(to: #selector(AnimateTabViewDelegate.tabView(_:didSelectTabIndex:)))) == true {
                self.delegate!.tabView!(self, didSelectTabIndex: index)
            }
            
            }, completion: {
                (value: Bool) in 
                self.tabed = false
        })
    }
    
    @objc private func onTab(_ button:UIButton) {
        self.selectIndex(button.tag, force: false)
    }
}
