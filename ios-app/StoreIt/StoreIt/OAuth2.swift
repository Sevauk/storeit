//
//  Oauth2.swift
//  StoreIt
//
//  Created by Romain Gjura on 06/05/2016.
//  Copyright © 2016 Romain Gjura. All rights reserved.
//

import Foundation

protocol OAuth2 {
    func authorize(context: AnyObject)
    func handleRedirectUrl(url: NSURL)
    func forgetTokens()
    func onFailureOrAuthorizeAddEvents()
    func accessToken() -> String?
}