//
//  AttachmentInfo.swift
//  AZPhone
//
//  Created by Jaseem V V on 30/03/25.
//

import Foundation
import UIKit
import AZCommon

public struct DocumentPickerState {
    /// List of URLs for document attachment type
    public static var docs: [URL] = []
    /// Photo or camera attachment
    public static var image: UIImage?
    /// The image name with extension
    public static var imageName: String = ""
    /// kUTTypeImage
    public static var imageType: String = "png"
    /// If camera is chosen
    public static var isCameraMode: Bool = false
    /// The index of data in the model
    public static var modelIndex: Int = 0
    /// The body form field model `RequestData` id.
    public static var reqDataId = ""
    
    public static func clear() {
        DocumentPickerState.docs = []
        DocumentPickerState.image = nil
        DocumentPickerState.imageType = "png"
        DocumentPickerState.isCameraMode = false
        DocumentPickerState.modelIndex = 0
        DocumentPickerState.reqDataId = ""
    }

    public static var debugDescription: String {
        return
            """
            DocumentPickerState
            docs: \(DocumentPickerState.docs)
            image: \(String(describing: DocumentPickerState.image))
            imageName: \(DocumentPickerState.imageName)
            imageType: \(DocumentPickerState.imageType)
            isCameraMode: \(DocumentPickerState.isCameraMode)
            modelIndex: \(DocumentPickerState.modelIndex)
            reqDataId: \(DocumentPickerState.reqDataId)
            """
    }
}

/// Used to hold the current attachment details being processed to avoid duplicates
public struct AttachmentInfo {
    /// List of URLs for document attachment type
    public var docs: [URL] = []
    /// Contains the file name for comparison. Cannot compare URL as the path gets auto generated each time.
    public var docNames: [String] = []
    /// Photo or camera attachment
    public var image: UIImage?
    /// kUTTypeImage
    public var imageType: String = "png"
    /// If camera is chosen
    public var isCameraMode: Bool = false
    /// The index of data in the model
    public var modelIndex: Int = 0
    /// The body form field model `RequestData` id.
    public var reqDataId = ""
    
    public init() {}
    
    public mutating func copyFromState() {
        self.docs = DocumentPickerState.docs
        self.docNames = self.docs.map({ url -> String in AZUtils.shared.getFileName(url) })
        self.image = DocumentPickerState.image
        self.imageType = DocumentPickerState.imageType
        self.isCameraMode = DocumentPickerState.isCameraMode
        self.modelIndex = DocumentPickerState.modelIndex
        self.reqDataId = DocumentPickerState.reqDataId
    }
    
    /// Checks if the current state is same as the picker state
    public func isSame() -> Bool {
        if DocumentPickerState.image != nil {
            return self.image == DocumentPickerState.image
        } else {
            if self.image == nil && DocumentPickerState.docs.isEmpty { return true }
        }
        let len = DocumentPickerState.docs.count
        if self.docs.count != len { return false }
        for i in 0..<len {
            if self.docNames[i] != AZUtils.shared.getFileName(DocumentPickerState.docs[i]) { return false }
        }
        return true
    }
    
    public mutating func clear() {
        self.docs = []
        self.docNames = []
        self.image = nil
        self.imageType = "png"
        self.isCameraMode = false
        self.modelIndex = 0
        self.reqDataId = ""
    }
}
