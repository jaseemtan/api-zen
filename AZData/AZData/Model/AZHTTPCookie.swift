//
//  AZHTTPCookie.swift
//  APIZen
//
//  Created by Jaseem V V on 27/05/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation

public struct AZHTTPCookie: Codable, CustomStringConvertible {
    public var name: String
    public var value: String
    public var expires: Date?
    public var session: Bool
    public var domain: String
    public var path: String
    public var secure: Bool
    public var httpOnly: Bool
    public var sameSite: String = ""
    
    public enum SameSite: String {
        case lax = "Lax"
        case strict = "Strict"
    }
    
    public init(with cookie: HTTPCookie) {
        self.name = cookie.name
        self.value = cookie.value
        self.expires = cookie.expiresDate
        self.session = cookie.isSessionOnly
        self.domain = cookie.domain
        self.path = cookie.path
        self.secure = cookie.isSecure
        self.httpOnly = cookie.isHTTPOnly
        if #available(iOS 13.0, *) {
            if let policy = cookie.sameSitePolicy { self.sameSite = SameSite(rawValue: policy.rawValue)?.rawValue ?? "" }
        }
    }
    
    public static func from(headers: [String: String], for url: URL) -> [AZHTTPCookie] {
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        return cookies.map { cookie in AZHTTPCookie(with: cookie) }
    }
    
    public func toHTTPCookie() -> HTTPCookie? {
        let hm: [HTTPCookiePropertyKey: Any] = [
            .name: self.name,
            .value: self.value,
            .expires: self.expires as Any,
            .discard: self.session,
            .domain: self.domain,
            .path: self.path,
            .secure: self.secure
        ]
        return HTTPCookie(properties: hm)
    }
    
    public var description: String {
        return """
               \(type(of: self)):
               name: \(self.name)
               value: \(self.value)
               expires: \(String(describing: self.expires))
               session: \(self.session)
               domain: \(self.domain)
               path: \(self.path)
               secure: \(self.secure)
               httpOnly: \(self.httpOnly)
               """
    }
}
