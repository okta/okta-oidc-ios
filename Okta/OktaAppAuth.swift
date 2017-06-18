//
//  OktaLogin.swift
//  Pods
//
//  Created by Jordan Melberg on 6/17/17.
//
//

import Foundation
import AppAuth

public func login(username: String, password: String) -> Login {
    return Login(username: username, password:password)
}

public func login() -> Login {
    print("In default login")
}


public class Login {
    init(username: String, password: String){
        
    }
}
