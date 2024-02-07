//
//  ViewController.swift
//  handsOnAi
//
//  Created by Florian Kainberger on 13.12.23.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        logoImageView.layer.cornerRadius = 20
        startButton.layer.cornerRadius = 20
        startButton.layer.masksToBounds = true
//        startButton.isUserInteractionEnabled = false
        startButton.isEnabled = false
        
        self.updateButtonColor(with: 0)
        
        ModelManager.shared.setupModel(progressHandler: { [weak self] progress in
            guard let self = self else {return}
            
            self.updateButtonColor(with: progress)
            self.progressView.setProgress(progress, animated: true)
            self.progressView.isHidden = progress == 1
            self.startButton.isEnabled = progress == 1
        })
    }

    @IBAction func didTapStart(_ sender: Any) {
        self.performSegue(withIdentifier: "goToASL", sender: self)
    }
    
    
    func updateButtonColor(with progress: Float) {
            // Interpolate between two colors based on the progress value
        let startColor = UIColor.designGroupedBackground
        let endColor = UIColor.designPrimary
        
        let interpolatedColor = interpolateColor(startColor: startColor, endColor: endColor, progress: CGFloat(progress))
        
            // Set the button's background color
        startButton.backgroundColor = interpolatedColor
    }
    
    func interpolateColor(startColor: UIColor, endColor: UIColor, progress: CGFloat) -> UIColor {
        var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
        var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0
        
        startColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        endColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)
        
        let interpolatedRed = startRed + (endRed - startRed) * progress
        let interpolatedGreen = startGreen + (endGreen - startGreen) * progress
        let interpolatedBlue = startBlue + (endBlue - startBlue) * progress
        let interpolatedAlpha = startAlpha + (endAlpha - startAlpha) * progress
        
        return UIColor(red: interpolatedRed, green: interpolatedGreen, blue: interpolatedBlue, alpha: interpolatedAlpha)
    }
    
}

