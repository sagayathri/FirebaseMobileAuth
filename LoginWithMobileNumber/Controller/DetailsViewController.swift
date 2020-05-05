//
//  DetailsViewController.swift
//  LoginWithMobileNumber
//

import UIKit
import Photos
import FirebaseAuth
import FirebaseDatabase
import CryptoKit

class DetailsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var mobileNumberTF: UITextField!
    @IBOutlet weak var telNumberTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var locationTF: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var allTextFields: [UITextField]!
    
    var dbReference: DatabaseReference!
    
    var key: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Initialise database reference
        dbReference = Database.database().reference()
        
        self.activityIndicator.isHidden = true
        
        //MARK: Hides the back button
        self.navigationItem.hidesBackButton = true
        
        firstNameTF.delegate = self
        lastNameTF.delegate = self
        telNumberTF.delegate = self
        emailTF.delegate = self
        locationTF.delegate = self
        
        //MARK: Makes rounded corner image view
        profileImageView.makeRounded()
       
        //MARK: Updates mobile number from previous view
        mobileNumberTF.text = UserDefaultsClass.mobileNumber
        
        //MARK: Fetch if alredy exists
        fetchIfExists()
    }

    private func fetchIfExists() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        //MARK: Gets the current userID
        let userID = Auth.auth().currentUser?.uid
        
        //MARK: Looks for the exitance of userID in database
        self.dbReference.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                
                //MARK: If user exists then populate the UI
                 self.populateUI(value: value)
            }
            //MARK: Hides activity indicator
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
        })
    }
    
    private func populateUI(value: [String: Any]) {
        //MARK: Fetch a distionary from database
        let user = User(firstName: value["firstName"] as! String,
        lastName:  value["lastName"] as! String,
        mobileNumber:  value["mobileNumber"] as! String,
        telNumber:  value["telNumber"] as? String,
        email:  value["email"] as! String,
        location:  value["location"] as! String,
        profilePicture:  value["profilePicture"] as! String)
        
        //MARK: Decrypt the data from database and populates UI
        self.firstNameTF.text = self.decrypt(encryptedString: user.firstName)
        self.lastNameTF.text = self.decrypt(encryptedString: user.lastName)
        self.mobileNumberTF.text = self.decrypt(encryptedString: user.mobileNumber)
        self.emailTF.text = self.decrypt(encryptedString: user.email)
        self.locationTF.text = self.decrypt(encryptedString: user.location)
        
        if let telNumber = user.telNumber {
            self.telNumberTF.text = self.decrypt(encryptedString: telNumber)
        }
        
        //MARK: Converts base64Encoded string to an image and populates UI
        if let decodedData = Data(base64Encoded: user.profilePicture, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: decodedData)
            self.profileImageView.image = image
        }
    }
    
    @IBAction func browseClicked(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        //MARK: Source type to open on photo gallery
        picker.sourceType = .photoLibrary
        
        //MARK: Opens up the camare app if physical camera is present
        self.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func saveClicked(_ sender: UIButton) {
        self.resignResponsers()
        
        //MARK: Checks all mandatory fields aren't empty
        let isEmpty = checksForEmpty()
        if isEmpty {
            showAlert(title: "ALERT", message: "All fields are required")
        }
        else {
            //MARK: Updates to database
            uploadDetailsToDatabase()
        }
    }
    
    @IBAction func logOutClicked(_ sender: UIButton) {
        do {
            //MARK: Logs out the current user
            try Auth.auth().signOut()
            
            //MARK: Pops back to login screen
            self.navigationController?.popViewController(animated: true)
        }
        catch let err {
            print("Log out error : \(err)")
        }
    }
    
    private func uploadImage(image: UIImage) {
        
        //MARK: Selected image from photo library will be populated
        profileImageView.image = image
    }
    
    //MARK: Updates the database
    private func uploadDetailsToDatabase() {
        
        guard let image = profileImageView.image else {
            return
        }
        //MARK: Compress profile image to data
        guard let imageData = image.jpeg(.lowest) else {
            return
        }
        
        //MARK: Convert compressed imageData to base64String
        let imageBase64String = imageData.base64EncodedString()
        
        //MARK: Encrypts the data using UserID
        let user = User(firstName: self.encrypt(message: firstNameTF.text!),
        lastName: self.encrypt(message: lastNameTF.text!),
        mobileNumber: self.encrypt(message: mobileNumberTF.text!),
        telNumber: self.encrypt(message: telNumberTF.text!),
        email: self.encrypt(message: emailTF.text!),
        location: self.encrypt(message: locationTF.text!),
        profilePicture: imageBase64String)
        
        //MARK: Gets the current user ID
        let userID = (Auth.auth().currentUser?.uid)!
        
        //MARK: Creates a new entry
        self.dbReference.child("users").child(userID).setValue(user.representation)
        self.showAlert(title: "Saved", message: "Profile updated")
    }
    
    private func checksForEmpty() -> Bool {
        var isEmpty = false
        for textField in allTextFields {
            if textField.text!.isEmpty {
                isEmpty = true
            }
        }
        return isEmpty
    }
    
    private func resignResponsers() {
        firstNameTF.resignFirstResponder()
        lastNameTF.resignFirstResponder()
        telNumberTF.resignFirstResponder()
        emailTF.resignFirstResponder()
        locationTF.resignFirstResponder()
    }
    
    private func encrypt(message: String) -> String {
        //MARK: Gets the current user ID
        let userID = (Auth.auth().currentUser?.uid)!
        
        //MARK: Converts message to encrpted data
        //Convert message & UserID to ASCII data and joins
        let encryptedData = message.data(using: .ascii)!+userID.data(using: .ascii)!
        
        //MARK: Converts encryptedData to base64Encoded String
        let encryptedString = encryptedData.base64EncodedString()
        return encryptedString
    }
    
    private func decrypt(encryptedString: String) -> String {
        //MARK: Gets the current user ID
        let userID = (Auth.auth().currentUser?.uid)!
        
        //MARK: Converts encryptedString to base64Encoded Data
        let decryptData = Data(base64Encoded: encryptedString)
        
        //MARK: Decode base64Encoded ASCII data to a readable string
        let decryptString = String(data: decryptData!, encoding: .ascii)
        
        //MARK: Extracts original string from decrypted string
        let originalString = decryptString!.replacingOccurrences(of: userID, with: "")
        return originalString
    }
    
    //MARK: Shows an alert
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(ac, animated: true, completion: nil)
    }
}

//MARK: UIImagePickerControllerDelegate
extension DetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //MARK: Dismiss picker
        picker.dismiss(animated: true, completion: nil)

        //MARK: Fetches the image with original size
        if let image = info[.originalImage] as? UIImage {
            self.uploadImage(image: image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //MARK: Dismiss picker
        picker.dismiss(animated: true, completion: nil)
    }
}
