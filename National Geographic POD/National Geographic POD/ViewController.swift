//
//  ViewController.swift
//  National Geographic POD
//
//  Created by Kenrick Vaz on 10/10/20.
//

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher
import Agrume

class ViewController: UIViewController {
    @IBOutlet weak var ai: UIActivityIndicatorView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var podTitle: UILabel!
    @IBOutlet weak var podDescription: UILabel!
    @IBOutlet weak var podCredit: UILabel!
    
    let userdefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(loadImage))
        self.image.isUserInteractionEnabled = true
        self.image.addGestureRecognizer(singleTap)
        
        self.image.kf.indicatorType = .activity
        
        isLoading(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchPOD()
    }

    
    func isLoading(_ state: Bool) {
        if(state) {
            podTitle.isHidden = true
            podDescription.isHidden = true
            podCredit.isHidden = true
            image.isHidden = true
            
            ai.startAnimating()
        } else {
            podTitle.isHidden = false
            podDescription.isHidden = false
            podCredit.isHidden = false
            image.isHidden = false
            
            ai.stopAnimating()
        }
    }
    
    @objc func loadImage() {
        if (image.isHidden == false) {
            let agrume = Agrume(image: image.image!)
            agrume.show(from: self)
        }
        
    }
    
    func fetchPOD() {
        
        isLoading(true)
        
        let currentDate = getCurrentDate()
        
        //check cache first
        if(self.getCacheValue("currentDate") == currentDate) {
            self.setData(
                self.getCacheValue("ngpodTitle"),
                description: self.getCacheValue("ngpodDescription"),
                credit: self.getCacheValue("ngpodCredit"),
                image: self.getCacheValue("ngpodImage")
            )
        }
        
        AF.request("https://ngpod-api.herokuapp.com/api/photo")
            .responseJSON { (response) in
                
                let pod = JSON(response.data)
          
                if(pod["title"].string == "") {
                    print("SOMETHING IS NOT RIGHT!")
                    self.podTitle.text = "Error fetching National Geographic Photo of the Day"
                    self.podTitle.isHidden = false
                    self.ai.stopAnimating()
                } else {
                    
                    self.setData(
                        pod["title"].string!,
                        description: pod["description"].string!,
                        credit: pod["credit"].string!,
                        image: pod["image"].string!
                    )
                }
            }
    }
    
    func setData(_ title: String, description: String, credit: String, image: String) {
        
        self.podTitle.text          = title
        self.podDescription.text    = description
        self.podCredit.text         = credit
        
        let url = URL(string: image)
        self.image.kf.setImage(with: url)
        
        self.isLoading(false)
        
        //set cache
        self.setCacheValue("currentDate", value: getCurrentDate())
        self.setCacheValue("ngpodTitle", value: title)
        self.setCacheValue("ngpodDescription", value: description)
        self.setCacheValue("ngpodCredit", value: credit)
        self.setCacheValue("ngpodImage", value: image)
    }
    
    func getCacheValue(_ key: String) -> String {
       return userdefaults.string(forKey: key) ?? ""
    }

    func setCacheValue(_ key: String, value: String) {
        
        userdefaults.set(value, forKey: key)
    }
    
    func getCurrentDate() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}

