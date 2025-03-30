//
//  ResponseData.swift
//  APIZen
//
//  Created by Jaseem V V on 24/05/20.
//  Copyright © 2020 Jaseem V V. All rights reserved.
//

import Foundation
import AZCommon

public struct ResponseData: CustomDebugStringConvertible, Equatable {
    private lazy var localdb = { CoreDataService.shared }()
    private lazy var utils = { AZUtils.shared }()
    public var status: Bool = false
    public var mode: Mode = .memory
    public var statusCode: Int = 0
    public var url: String = ""
    public var method: String = ""
    public var request: ERequest?
    public var urlRequestString: String = ""
    public var requestId: String = ""
    public var wsId: String = ""
    public var urlRequest: URLRequest?
    public var history: EHistory?
    public var response: HTTPURLResponse?
    public var responseData: Data?
    public var metrics: URLSessionTaskMetrics?
    public var error: Error?
    public var cookiesData: Data?
    public var cookies: [AZHTTPCookie] = []
    public var isSecure = false
    private var responseHeaders: [String: String] = [:] {
        didSet { self.updateResponseHeaderKeys() }
    }
    private var responseHeaderKeys: [String] = []
    public var connectionInfo: ConnectionInfo = ConnectionInfo()
    public var created: Date = Date()
    private var metricsMap: [String: String] = [:]
    private var metricsKeys: [String] = []
    private var detailsMap: [String: String] = [:]
    private var detailsKeys: [String] = []
    public var hasRequestBody = false
    public var sessionName = "Default"
    
    public enum ErrorCode: Int {
        case error = -1
        case sslCert = -2
        case offline = -3
        
        public func toString() -> String {
            switch self {
            case .error: return "Error"
            case .sslCert: return "SSL certificate error"
            case .offline: return "Offline"
            }
        }
    }
    
    public struct ConnectionInfo {
        public var elapsed: Int64 = 0  // Total response time
        public var dnsTime: Double = 0  // DNS Resolution Time
        public var connectionTime: Double = 0  // Connection Time
        public var secureConnectionTime: Double = 0  // SSL Handshake Time
        public var fetchStart: Int64 = 0  // Date ts
        public var requestTime: Double = 0 // Request start, request end
        public var responseTime: Double = 0
        public var networkProtocolName: String = ""
        public var isProxyConnection: Bool = false
        public var isReusedConnection: Bool = false
        public var requestHeaderBytesSent: Int64 = 0
        public var requestBodyBytesSent: Int64 = 0
        public var responseHeaderBytesReceived: Int64 = 0
        public var responseBodyBytesReceived: Int64 = 0
        public var localAddress: String = ""
        public var localPort: Int64 = 0
        public var remoteAddress: String = ""
        public var remotePort: Int64 = 0
        public var isCellular: Bool = false
        public var isMultipath: Bool = false
        public var negotiatedTLSCipherSuite: String = ""  // TLS Cipher Suite
        public var negotiatedTLSProtocolVersion: String = ""  // TLS Protocol
        public var connection: String = AZReachability.Connection.cellular.description
    }
    
    /// Indicates if the response object is created from a live response or from history.
    public enum Mode {
        case memory
        case history
    }
    
    public init(error: Error, elapsed: Int64, request: ERequest, metrics: URLSessionTaskMetrics?) {
        self.created = Date()
        self.error = error
        self.mode = .memory
        self.status = false
        self.connectionInfo.elapsed = elapsed
        self.statusCode = ErrorCode.error.rawValue
        self.request = request
        self.url = request.url ?? ""
        self.isSecure = self.isHTTPS(url: self.url)
        self.wsId = request.getWsId()
        self.requestId = request.getId()
        self.hasRequestBody = request.body != nil
        self.method = request.method?.name ?? ""
        if let x = metrics { self.updateFromMetrics(x) }
        if error.code == -1202 {  // Bad SSL certificate
            self.statusCode = ErrorCode.sslCert.rawValue
        } else if error.code == -1009 { // Offline
            self.statusCode = ErrorCode.offline.rawValue
        }
        self.updateDetailsMap()
    }
        
    public init(history: EHistory) {
        self.created = history.created!
        self.mode = .history
        self.history = history
        self.urlRequestString = history.urlRequest ?? ""
        self.method = history.method ?? ""
        self.url = history.url ?? ""
        self.isSecure = self.isHTTPS(url: self.url)
        self.request = history.request
        self.requestId = history.request?.getId() ?? ""
        self.wsId = history.wsId ?? ""
        self.hasRequestBody = history.hasRequestBody
        self.responseData = history.responseData
        self.statusCode = history.statusCode.toInt()
        self.status = (200..<299) ~= self.statusCode
        self.connectionInfo.elapsed = history.elapsed
        self.sessionName = history.sessionName ?? "Default"
        self.updateResponseHeadersMap()
        self.updateCookies()
        self.updateMetricsDetails(history)
        self.updateDetailsMap()
    }
    
    public init(response: HTTPURLResponse, request: ERequest, urlRequest: URLRequest, responseData: Data?, metrics: URLSessionTaskMetrics? = nil) {
        self.init(response: response, request: request, urlRequest: urlRequest, responseData: responseData, elapsed: 0, metrics: metrics)
    }
    
    public init(response: HTTPURLResponse, request: ERequest, urlRequest: URLRequest, responseData: Data?, elapsed: Int64, metrics: URLSessionTaskMetrics? = nil) {
        self.created = Date()
        self.mode = .memory
        self.response = response
        self.request = request
        self.urlRequest = urlRequest
        self.urlRequestString = urlRequest.toString()
        self.method = urlRequest.httpMethod ?? ""
        self.url = urlRequest.url?.absoluteString ?? ""
        self.isSecure = self.isHTTPS(url: self.url)
        self.requestId = request.getId()
        self.wsId = request.getWsId()
        self.hasRequestBody = request.body != nil
        self.responseData = responseData
        self.statusCode = response.statusCode
        self.status = (200..<299) ~= self.statusCode
        self.connectionInfo.elapsed = elapsed
        self.updateResponseHeadersMap()
        self.updateCookies()
        if let x = metrics { self.updateFromMetrics(x) }
        self.updateDetailsMap()
    }
    
    public func isHTTPS(url: String?) -> Bool {
        return url?.starts(with: "https") ?? false
    }
    
    /// Updates metrics, details from the given history object.
    public mutating func updateMetricsDetails(_ history: EHistory) {
        var cinfo = self.connectionInfo
        cinfo.connectionTime = history.connectionTime
        cinfo.dnsTime = history.dnsResolutionTime
        cinfo.elapsed = history.elapsed
        cinfo.fetchStart = history.fetchStartTime
        cinfo.requestTime = history.requestTime
        cinfo.responseTime = history.responseTime
        cinfo.secureConnectionTime = history.secureConnectionTime
        cinfo.networkProtocolName = history.networkProtocolName ?? ""
        cinfo.isProxyConnection = history.isProxyConnection
        cinfo.isReusedConnection = history.isReusedConnection
        cinfo.requestHeaderBytesSent = history.requestHeaderBytes
        cinfo.requestBodyBytesSent = history.requestBodyBytes
        cinfo.responseHeaderBytesReceived = history.responseHeaderBytes
        cinfo.responseBodyBytesReceived = history.responseBodyBytes
        cinfo.localAddress = history.localAddress ?? ""
        cinfo.localPort = history.localPort
        cinfo.remoteAddress = history.remoteAddress ?? ""
        cinfo.remotePort = history.remotePort
        cinfo.isCellular = history.isCellular
        cinfo.connection = history.connection ?? ""
        cinfo.isMultipath = history.isMultipath
        cinfo.negotiatedTLSCipherSuite = history.tlsCipherSuite ?? ""
        cinfo.negotiatedTLSProtocolVersion = history.tlsProtocolVersion ?? ""
        self.connectionInfo = cinfo
        self.updateMetricsMap()
    }
    
    public mutating func updateFromMetrics() {
        guard let metrics = self.metrics else { return }
        self.updateFromMetrics(metrics)
    }
    
    public mutating func updateFromMetrics(_ metrics: URLSessionTaskMetrics) {
        var cInfo = self.connectionInfo
        Log.debug("elapsed: \(self.connectionInfo.elapsed) - duration: \(metrics.taskInterval.duration)")
        let elapsed = self.connectionInfo.elapsed
        if metrics.transactionMetrics.isEmpty { return }
        //let hasMany = metrics.transactionMetrics.count > 1
        //if hasMany {
            // TODO: handle multiple metrices
        //} else {  // only one transaction metrics
            guard let tmetrics = metrics.transactionMetrics.first else { return }
            if let d1 = tmetrics.connectStartDate, let d2 = tmetrics.connectEndDate {
                cInfo.connectionTime = Date.msDiff(start: d1, end: d2)
            }
            if let d1 = tmetrics.domainLookupStartDate, let d2 = tmetrics.domainLookupEndDate {
                cInfo.dnsTime = Date.msDiff(start: d1, end: d2)
            }
            if let x = tmetrics.fetchStartDate {
                cInfo.fetchStart = x.currentTimeNanos()
            }
            if let d1 = tmetrics.requestStartDate, let d2 = tmetrics.requestEndDate {
                cInfo.requestTime = Date.msDiff(start: d1, end: d2)
            }
            if let d1 = tmetrics.responseStartDate, let d2 = tmetrics.responseEndDate {
                cInfo.responseTime = Date.msDiff(start: d1, end: d2)
            }
            if let d1 = tmetrics.secureConnectionStartDate, let d2 = tmetrics.secureConnectionEndDate {
                cInfo.secureConnectionTime = Date.msDiff(start: d1, end: d2)
            }
            if let d1 = tmetrics.fetchStartDate, let d2 = tmetrics.responseEndDate {
                cInfo.elapsed = Date.msDiff(start: d1, end: d2).toInt64()
            }
            if cInfo.elapsed == 0 && elapsed > 0 { cInfo.elapsed = elapsed }
            cInfo.networkProtocolName = tmetrics.networkProtocolName ?? ""
            cInfo.isProxyConnection = tmetrics.isProxyConnection
            cInfo.isReusedConnection = tmetrics.isReusedConnection
            if #available(iOS 13.0, *) {
                cInfo.requestHeaderBytesSent = tmetrics.countOfRequestHeaderBytesSent
                cInfo.requestBodyBytesSent = tmetrics.countOfRequestBodyBytesSent
                cInfo.responseHeaderBytesReceived = tmetrics.countOfResponseHeaderBytesReceived
                cInfo.responseBodyBytesReceived = tmetrics.countOfResponseBodyBytesReceived
                cInfo.localAddress = tmetrics.localAddress ?? ""
                cInfo.remoteAddress = tmetrics.remoteAddress ?? ""
                cInfo.localPort = (tmetrics.localPort ?? 0).toInt64()
                cInfo.remotePort = (tmetrics.remotePort ?? 0).toInt64()
                cInfo.isCellular = (tmetrics.isCellular || tmetrics.isExpensive || tmetrics.isConstrained)
                cInfo.connection = (tmetrics.isCellular || tmetrics.isExpensive || tmetrics.isConstrained) ? AZReachability.Connection.cellular.description
                    : AZReachability.Connection.wifi.description
                cInfo.isMultipath = tmetrics.isMultipath
                if let x = tmetrics.negotiatedTLSCipherSuite?.rawValue {
                    cInfo.negotiatedTLSCipherSuite = AZTLSCipherSuite(x)?.toString() ?? ""
                }
                if let x = tmetrics.negotiatedTLSProtocolVersion {
                    cInfo.negotiatedTLSProtocolVersion = AZTLSProtocolVersion(x.rawValue)?.toString() ?? ""
                }
            } else {
                self.updateResponseBodySizeFromHeaders()
            }
        //}
        self.connectionInfo = cInfo
    }
    
    public mutating func updateResponseBodySizeFromHeaders() {
        if !self.responseHeaders.isEmpty {
            if let sizeMap = self.responseHeaders.first(where: { (key: AnyHashable, value: Any) -> Bool in
                if let key = key as? String { return key.lowercased() == "content-length" }
                return false
            }) {
                self.connectionInfo.responseBodyBytesReceived = Int64(sizeMap.value) ?? 0
            }
        }
    }
    
    public func getResponseHeaders() -> [String: String] {
        return self.responseHeaders
    }
    
    public func getResponseHeaderKeys() -> [String] {
        return self.responseHeaderKeys
    }
    
    public mutating func updateResponseHeadersMap() {
        if self.mode == .memory {
            self.responseHeaders = self.response?.allHeaderFields as? [String : String] ?? [:]
        } else if self.mode == .history {
            if let data = self.history?.responseHeaders, let hm = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: String] {
                self.responseHeaders = hm
            }
        }
        self.updateResponseHeaderKeys()
    }
    
    public mutating func updateResponseHeaderKeys() {
        self.responseHeaderKeys = self.responseHeaders.allKeys()
        self.responseHeaderKeys.sort { (a, b) in a.lowercased() <= b.lowercased() }
    }
    
    public mutating func updateCookies() {
        if self.mode == .memory {
            if let url = self.urlRequest?.url {
                self.cookies = AZHTTPCookie.from(headers: self.responseHeaders, for: url)
                self.cookiesData = try? JSONEncoder().encode(self.cookies)
            }
        } else if self.mode == .history {
            if let cookies = self.history?.cookies as? Data { self.cookiesData = cookies }
            if let data = self.cookiesData, let xs = try? JSONDecoder().decode([AZHTTPCookie].self, from: data) {
                self.cookies = xs
            }
        }
        self.cookies.sort { (a, b) in a.name.lowercased() <= b.name.lowercased() }
    }
    
    public mutating func updateMetricsMap() {
        let cinfo = self.connectionInfo
        var res = ""
        if cinfo.elapsed > 0 {
            res = self.utils.millisToReadable(cinfo.elapsed.toDouble())
            if !res.isEmpty { self.metricsMap["Elapsed"] = res }
        }
        res = self.utils.millisToReadable(cinfo.dnsTime)
        if !res.isEmpty { self.metricsMap["DNS Resolution Time"] = res }
        res = self.utils.millisToReadable(cinfo.connectionTime)
        if !res.isEmpty { self.metricsMap["Connection Time"] = res }
        res = self.utils.millisToReadable(cinfo.requestTime)
        if !res.isEmpty { self.metricsMap["Request Time"] = res }
        res = self.utils.millisToReadable(cinfo.responseTime)
        if !res.isEmpty { self.metricsMap["Response Time"] = res }
        if self.isSecure {
            res = self.utils.millisToReadable(cinfo.secureConnectionTime)
            if !res.isEmpty { self.metricsMap["SSL Handshake Time"] = res }
        }
        if #available(iOS 13.0, *) {
            res = self.utils.bytesToReadable(cinfo.requestHeaderBytesSent)
            if !res.isEmpty && !res.starts(with: "Zero") { self.metricsMap["Request Header Size"] = res }
            if self.hasRequestBody {
                res = self.utils.bytesToReadable(cinfo.requestBodyBytesSent)
                if !res.isEmpty && !res.starts(with: "Zero") { self.metricsMap["Request Body Size"] = res }
            }
            res = self.utils.bytesToReadable(cinfo.responseHeaderBytesReceived)
            if !res.isEmpty && !res.starts(with: "Zero") { self.metricsMap["Response Header Size"] = res }
            res = self.utils.bytesToReadable(cinfo.responseBodyBytesReceived)
            if !res.isEmpty && !res.starts(with: "Zero") { self.metricsMap["Response Body Size"] = res }
        }
        self.metricsKeys = self.metricsMap.allKeys().sorted()
    }
    
    public func getMetricsMap() -> [String: String] {
        return self.metricsMap
    }
    
    public func getMetricsKeys() -> [String] {
        return self.metricsKeys
    }
    
    public mutating func updateDetailsMap() {
        let cinfo = self.connectionInfo
        self.detailsMap["Date"] = self.created.toLocale()
        var x = cinfo.localAddress
        if !x.isEmpty { self.detailsMap["Local Address"] = x }
        x = "\(cinfo.localPort)"
        if !x.isEmpty && x != "0" { self.detailsMap["Local Port"] = x }
        x = cinfo.remoteAddress
        if !x.isEmpty { self.detailsMap["Remote Address"] = x }
        x = "\(cinfo.remotePort)"
        if !x.isEmpty && x != "0" { self.detailsMap["Remote Port"] = x }
        if !cinfo.connection.isEmpty { self.detailsMap["Connection"] = "\(cinfo.connection)" }
        if cinfo.isMultipath { self.detailsMap["Routing"] = "Multipath" }
        if self.isSecure {
            x = cinfo.negotiatedTLSCipherSuite
            if !x.isEmpty { self.detailsMap["SSL Cipher Suite"] = x }
            x = cinfo.negotiatedTLSProtocolVersion
            if !x.isEmpty { self.detailsMap["TLS"] = x }
        }
        self.detailsKeys = self.detailsMap.allKeys().sorted()
    }
    
    public func getDetailsMap() -> [String: String] {
        return self.detailsMap
    }
    
    public func getDetailsKeys() -> [String] {
        return self.detailsKeys
    }
    
    public var debugDescription: String {
        return
            """
            \(type(of: self)))
            status: \(self.status)
            statusCode: \(self.statusCode)
            request: \(String(describing: self.request))
            urlRequest: \(String(describing: self.urlRequest))
            response: \(String(describing: self.response))
            cookies: \(String(describing: self.cookies))
            error: \(String(describing: self.error))
            elapsed: \(self.connectionInfo.elapsed)
            size: \(self.connectionInfo.responseBodyBytesReceived)
            mode: \(self.mode)
            sessionName: \(self.sessionName)
            connectionInfo: \(self.connectionInfo)
            """
    }
    
    public static func == (lhs: ResponseData, rhs: ResponseData) -> Bool {
        return lhs.requestId == rhs.requestId && lhs.statusCode == rhs.statusCode && lhs.created == rhs.created
    }
}
