//
//  HomeViewController.swift
//  Myoko
//
//  Created by Subomi Popoola on 10/3/21.
//

import UIKit
import Parse

class HomeViewController: UIViewController {

    let name = "martin"
    let contestant = "subomi"
    var filename = "car.scn"
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        // Do any additional setup after loading the view.
//        let user = PFUser()
//      user.username = contestant
//        user.password = contestant
//
//      user.signUpInBackground()
        login()
    }
    
    func login() {
        PFUser.logInWithUsername(inBackground: "martin", password: "martin") {
          (user: PFUser?, error: Error?) -> Void in
          if user != nil {
            print("success")
          } else {
            // The login failed. Check error to see why.
          }
        }
    }
    
    @IBAction func tapEngineeringSection(_ sender: Any) {
        filename = "car.scn"
        self.performSegue(withIdentifier: "move", sender: nil)
    }
    
    
    @IBAction func nursingLabSection(_ sender: Any) {
        filename = "skeleton.scn"
        self.performSegue(withIdentifier: "move", sender: nil)
    }
   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        let vc = segue.destination as? ViewController
        vc?.fileName = filename
        vc?.name = name
        vc?.opponent = contestant
    }
    

}
