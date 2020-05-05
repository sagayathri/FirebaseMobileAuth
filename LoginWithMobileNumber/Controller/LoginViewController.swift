//
//  LoginViewController.swift
//  LoginWithMobileNumber
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var numberTF: UITextField!
    @IBOutlet weak var OTPTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var OTPTextFeildHeight: NSLayoutConstraint!
    
    @IBOutlet weak var cancelButton: UIButton!
    var verificationID: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.numberTF.delegate = self
        self.OTPTextField.delegate = self
        
        self.OTPTextFeildHeight.constant = 0
        self.activityIndicator.isHidden = true
        
        self.cancelButton.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        //MARK: Sets the focus on number text field
        numberTF.becomeFirstResponder()
    }
    
    @IBAction func LogInClicked(_ sender: UIButton) {
        self.errorLabel.isHidden = true
        self.numberTF.isUserInteractionEnabled = false
        
        //MARK: Checks for textField is empty
        if let number = numberTF.text, !number.isEmpty {
            
            //MARK: Save mobile number locally
            UserDefaultsClass.mobileNumber = number
           
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            
            //MARK: Checks for OTPTextField
            if OTPTextField.isHidden {
                CreateUser(phoneNumber: number)
            }
            else {
                performLogin()
            }
        }
        else {
            showError(error: "Please enter a mobile number")
        }
    }
    
    @IBAction func cancelClicked(_ sender: UIButton) {
        resetAllViews()
    }
    
    
    private func CreateUser(phoneNumber: String) {
        //MARK: Verify user's phone number.
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            
            if let error = error {
                self.showError(error: error.localizedDescription)
                self.numberTF.isUserInteractionEnabled = true
                return
            }

            guard let verificationID = verificationID else { return }
            
            //MARK: Gets verificationID if creation of user is successful
            self.verificationID = verificationID
            
            self.OTPTextField.isHidden = false
            self.OTPTextFeildHeight.constant = 40
            
            self.cancelButton.isHidden = false
        }
    }
    
    func performLogin() {
        //MARK: User types in OTP sent as SMS
        if let verificationCode = OTPTextField.text {
            let credential = PhoneAuthProvider.provider().credential(withVerificationID: self.verificationID!, verificationCode: verificationCode)
        
            //MARK: Sign in using the verificationID and the code sent to the user
            Auth.auth().signIn(with: credential) { (user, error) in
                
                self.activityIndicator.isHidden = true
                self.activityIndicator.stopAnimating()
                
                if let error = error {
                    self.showError(error: error.localizedDescription)
                    print(error.localizedDescription)
                    return
                }
               
                self.resetAllViews()
                
                //MARK: Navigates to the Topics screen
                let vc = self.storyboard!.instantiateViewController(identifier: "DetailsViewController") as DetailsViewController
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func resetAllViews() {
        self.numberTF.text = ""
        self.numberTF.isUserInteractionEnabled = true
        self.OTPTextField.text = ""
        self.OTPTextField.isHidden = true
        self.OTPTextFeildHeight.constant = 0
        self.cancelButton.isHidden = true
        self.errorLabel.isHidden = true
    }
    
    //MARK: Shows an error message
    func showError(error: String) {
        self.numberTF.resignFirstResponder()
        self.OTPTextField.resignFirstResponder()
        self.errorLabel.isHidden = false
        
        let errors: [String] = error.components(separatedBy: ".")
        self.errorLabel.text = "ERROR: \(errors[0])"
    }
}

