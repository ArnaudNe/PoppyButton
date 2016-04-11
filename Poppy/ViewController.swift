//
//  ViewController.swift
//  Poppy
//
//  Created by Arnaud Nelissen on 02/04/2016.
//  Copyright © 2016 Arnaud Nelissen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var poppyButtonLabel: UILabel!
    @IBOutlet weak var poppyButton: PoppyButton!
    
    @IBOutlet weak var highlightPickButton: UIButton!
    @IBOutlet weak var beginSelectionButton: UIButton!
    @IBOutlet weak var endSelectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        highlightPickButton.enabled = false
        beginSelectionButton.enabled = true
        endSelectionButton.enabled = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        poppyButton.delegate = self
        poppyButton.dataSource = self
        
        //poppyButton.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func highlightPickButtonTouchUpInside(sender: UIButton) {
        guard poppyButton.selecting && poppyButton.indexOfHighlightedPick() == nil else {
            return
        }
        
        poppyButton.highlightPickAtIndex(2)
    }
    
    @IBAction func beginSelectionButtonTouchUpInside(sender: UIButton) {
        poppyButton.beginSelection()
    }
    
    @IBAction func endSelectionButtonTouchUpInside(sender: UIButton) {
        poppyButton.endSelection()
    }

}

extension ViewController: PoppyDataSource {
    func numberOfPickForPoppyButton(button: PoppyButton) -> Int {
        return 5
    }
    
    func pickViewForPoppyButton(button: PoppyButton, atIndex index: Int) -> UIView {
        let view = UIView(frame: CGRectMake(0, 0, button.pickDiameter, button.pickDiameter))
        let square = UIView(frame: CGRectMake(button.pickDiameter/2 - button.pickDiameter/4, button.pickDiameter/2 - button.pickDiameter/4, button.pickDiameter/2, button.pickDiameter/2))
        
        square.backgroundColor = UIColor(hue: CGFloat(index)/5.0, saturation: 0.8, brightness: 0.6, alpha: 0.8)
        square.layer.cornerRadius = button.pickDiameter/(2.0 + CGFloat(index))
        square.layer.masksToBounds = true
        square.autoresizingMask = [.FlexibleWidth, .FlexibleHeight, .FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]

        view.addSubview(square)
        view.backgroundColor = UIColor(white: 0, alpha: 0.2)
        
        return view
    }
    
    func pickTitleForPoppyButton(button: PoppyButton, atIndex index: Int) -> String? {
        return "Pick \(index)"
    }
}


extension ViewController: PoppyDelegate {
    func poppyButton(button: PoppyButton, selectedPickAtIndex index: Int) {
        print("Poppy Button Selected pick at index \(index)")
        poppyButtonLabel.text = "Selected pick \(index)"
    }
    
    func poppyButton(button: PoppyButton, highlightedPickAtIndex index: Int) {
        print("Poppy Button Highlighted pick at index \(index)")
        poppyButtonLabel.text = "Highlighted pick \(index)"
        
        highlightPickButton.enabled = false
    }
    
    func poppyButtonUnhighlightedPick(button: PoppyButton) {
        print("Poppy Button Unhighlighted pick")
        poppyButtonLabel.text = "Unhighlighted pick"
        
        highlightPickButton.enabled = true
    }
    
    func poppyButtonBeganSelection(button: PoppyButton) {
        print("Poppy Button Began selection")
        
        highlightPickButton.enabled = true
        beginSelectionButton.enabled = false
        endSelectionButton.enabled = true
    }
    
    func poppyButtonEndedSelection(button: PoppyButton) {
        print("Poppy Button Ended selection")
        
        highlightPickButton.enabled = false
        beginSelectionButton.enabled = true
        endSelectionButton.enabled = false
    }
}