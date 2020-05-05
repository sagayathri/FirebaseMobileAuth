//
//  UserDefaultsClass.swift
//  LoginWithMobileNumber
//

import Foundation
import UIKit

final class UserDefaultsClass {
  
  private enum SettingKey: String {
    case mobileNumber
  }
  
  static var mobileNumber: String! {
    get {
      return UserDefaults.standard.string(forKey: SettingKey.mobileNumber.rawValue)
    }
    set {
      let defaults = UserDefaults.standard
      let key = SettingKey.mobileNumber.rawValue
      
      if let name = newValue {
        defaults.set(name, forKey: key)
      } else {
        defaults.removeObject(forKey: key)
      }
    }
  }
}

//MARK: Extensions
extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    //MARK: Returns the data for the specified image in JPEG format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}

extension UIImageView {
    func makeRounded() {
        self.layer.borderWidth = 0
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = self.frame.height / 2.5
        self.clipsToBounds = true
    }
}


