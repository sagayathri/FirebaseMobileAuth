//
//  User.swift
//  LoginWithMobileNumber
//

import FirebaseDatabase

struct User {
    var firstName: String
    var lastName: String
    var mobileNumber: String
    var telNumber: String?
    var email: String
    var location: String
    var profilePicture: String
    
    //MARK: Returns a dictionary
    var representation: [String : Any] {
        let rep: [String : Any] = [ "firstName": firstName,
                                    "lastName": lastName,
                                    "mobileNumber": mobileNumber,
                                    "telNumber": telNumber as Any,
                                    "email": email,
                                    "location": location,
                                    "profilePicture": profilePicture]
        return rep
    }
}
