//
//  Utils.swift
//  wechat
//
//  Created by Martin Mungai on 19/03/2018.
//  Copyright © 2018 Martin Mungai. All rights reserved.
//

import Foundation


// Determines whether we are running on a simulator or device

struct PlatformUtils {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

struct TokenUtils {
    static func fetchToken(url : String) throws -> String {
        var token: String = "TWILIO_ACCESS_TOKEN"
        let requestURL: URL = URL(string: url)!
        do {
            let data = try Data(contentsOf: requestURL)
            if let tokenReponse = String.init(data: data, encoding: String.Encoding.utf8) {
                token = tokenReponse
                print(token)
            }
        } catch let error as NSError {
            print ("Invalid token url, error = \(error)")
            throw error
        }
        return token
    }
}

