//
//  EHistory.swift
//  APIZen
//
//  Created by Jaseem V V on 20/05/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import CoreData

public class EHistory: NSManagedObject, Entity {
    static var db: CoreDataService = { CoreDataService.shared }()
    public var recordType: String { return "History" }
    
    public static func initFromResponseData(_ respData: ResponseData, ctx: NSManagedObjectContext) -> EHistory {
        let history = EHistory(context: ctx)
        let date = Date()
        history.created = date
        history.modified = date
        history.connection = respData.connectionInfo.connection
        history.connectionTime = respData.connectionInfo.connectionTime
        history.cookies = respData.cookiesData
        history.dnsResolutionTime = respData.connectionInfo.dnsTime
        history.elapsed = respData.connectionInfo.elapsed
        history.fetchStartTime = respData.connectionInfo.fetchStart
        history.hasRequestBody = respData.hasRequestBody
        history.id = self.db.historyId()
        history.isCellular = respData.connectionInfo.isCellular
        history.isMultipath = respData.connectionInfo.isMultipath
        history.isProxyConnection = respData.connectionInfo.isProxyConnection
        history.isReusedConnection = respData.connectionInfo.isReusedConnection
        history.isSecure = respData.isSecure
        history.localAddress = respData.connectionInfo.localAddress
        history.localPort = respData.connectionInfo.localPort
        history.method = respData.method
        history.networkProtocolName = respData.connectionInfo.networkProtocolName
        history.remoteAddress = respData.connectionInfo.remoteAddress
        history.remotePort = respData.connectionInfo.remotePort
        history.request = respData.request
        history.requestBodyBytes = respData.connectionInfo.requestBodyBytesSent
        history.requestHeaderBytes = respData.connectionInfo.requestHeaderBytesSent
        history.requestTime = respData.connectionInfo.requestTime
        history.responseBodyBytes = respData.connectionInfo.responseBodyBytesReceived
        history.responseData = respData.responseData
        history.responseHeaderBytes = respData.connectionInfo.responseHeaderBytesReceived
        history.responseHeaders = URLRequest.headersToData(respData.getResponseHeaders())
        history.responseTime = respData.connectionInfo.responseTime
        history.secureConnectionTime = respData.connectionInfo.secureConnectionTime
        history.sessionName = respData.sessionName
        history.statusCode = respData.statusCode.toInt64()
        history.tlsCipherSuite = respData.connectionInfo.negotiatedTLSCipherSuite
        history.tlsProtocolVersion = respData.connectionInfo.negotiatedTLSProtocolVersion
        history.url = respData.url
        history.urlRequest = respData.urlRequest?.toString() ?? ""
        history.version = 0
        history.wsId = respData.wsId
        return history
    }
    
    public func getId() -> String {
        return self.id ?? ""
    }
    
    public func getWsId() -> String {
        return self.wsId ?? ""
    }
    
    public func setWsId(_ id: String) {
        self.wsId = id
    }
    
    public func getName() -> String {
        return ""
    }
    
    public func getCreated() -> Date {
        return self.created!.toLocalDate()
    }
    
    public func getCreatedUTC() -> Date {
        return self.created!
    }
    
    public func getModified() -> Date {
        return self.modified!.toLocalDate()
    }
    
    public func getModitiedUTC() -> Date {
        return self.modified!
    }
    
    public func setModified(_ date: Date) {
        self.modified = date.toUTC()
    }
    
    public func setModifiedUTC(_ date: Date) {
        self.modified = date
    }
    
    public func getVersion() -> Int64 {
        return self.version
    }
    
    public func setMarkedForDelete(_ status: Bool) {
        self.markForDelete = status
    }
    
    public override func willSave() {
        
    }
}
