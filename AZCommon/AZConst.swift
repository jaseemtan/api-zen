//
//  AZConst.swift
//  APIZen
//
//  Created by Jaseem V V on 09/12/19.
//  Copyright © 2019 Jaseem V V. All rights reserved.
//

import Foundation

public struct AZConst {
    public static let requestMethodNameKey = "requestMethodName"
    /// The data model index.
    public static let modelIndexKey = "modelIndexKey"
    /// A generic index key.
    public static let indexKey = "indexKey"
    /// Generic data key.
    public static let dataKey = "dataKey"
    /// The option selected item index.
    public static let optionSelectedIndexKey = "optionSelectedIndexKey"
    /// The option vc type.
    public static let optionTypeKey = "optionTypeKey"
    /// The option picker data [String].
    public static let optionDataKey = "optionDataKey"
    /// The option picker title key.
    public static let optionTitleKey = "optionTitleKey"
    /// The model data (eg: `ERequestBodyData`).
    public static let optionModelKey = "optionModelKey"
    /// The action for the data (add, delete, etc.).
    public static let optionDataActionKey = "optionDataActionKey"
    
    // User defaults keys
    public static let selectedWorkspaceIdKey = "selectedWorkspaceId"
    public static let selectedWorkspaceContainerKey = "selectedWorkspaceContainer"
    /// The selected segment index in response screen.
    public static let responseSegmentIndexKey = "responseSegmentIndex"
    
    /// The default number of methods added (`GET`, `POST`, `PUT`, `PATCH` and `DELETE`).
    public static let defaultRequestMethodsCount = 5
    public static let paginationOffset = 20
    public static let fetchLimit = 30
    public static let helpTextForAddNewRequestMethod = "The request method name will be available to all requests within the same project and should be unique."
    public static let appId = "6471152115"
    public static let feedbackEmail = "jaseemvv@icloud.com"
    public static let appURL = "https://apps.apple.com/app/id6471152115"
    public static let cloudKitContainerID = "iCloud.net.jsloop.APITesterPro"
    public static let appName = "API Zen"
    public static let shareText = "\(AZConst.appName) - Find the zen in API testing"
}

public extension Notification.Name {
    static let requestTableViewReload = Notification.Name("request-table-view-reload")
    static let requestViewClearEditing = Notification.Name("request-view-clear-editing")
    static let requestMethodDidChange = Notification.Name("request-method-did-change")
    static let requestBodyFormFieldTypeDidChange = Notification.Name("request-body-form-field-type-did-change")
    static let requestBodyTypeDidChange = Notification.Name("request-body-type-did-change")
    static let customRequestMethodDidAdd = Notification.Name("custom-request-method-did-add")
    static let customRequestMethodShouldDelete = Notification.Name("custom-request-method-should-delete")
    static let optionScreenShouldPresent = Notification.Name("option-screen-should-present")
    static let optionPickerShouldReload = Notification.Name("option-picker-should-reload")
    static let documentPickerMenuShouldPresent = Notification.Name("document-picker-menu-should-present")
    static let documentPickerShouldPresent = Notification.Name("document-picker-should-present")
    static let imagePickerShouldPresent = Notification.Name("image-picker-should-present")
    static let documentPickerImageIsAvailable = Notification.Name("document-picker-image-is-available")
    static let documentPickerFileIsAvailable = Notification.Name("document-picker-file-is-available")
    static let workspaceDidSync = Notification.Name("workspace-did-sync")
    static let projectDidSync = Notification.Name("project-did-sync")
    static let requestDidSync = Notification.Name("request-did-sync")
    static let requestDataDidSync = Notification.Name("request-data-did-sync")
    static let requestBodyDataDidSync = Notification.Name("request-body-data-did-sync")
    static let requestMethodDataDidSync = Notification.Name("request-method-data-did-sync")
    static let fileDataDidSync = Notification.Name("file-data-did-sync")
    static let imageDataDidSync = Notification.Name("image-data-did-sync")
    static let historyDidSync = Notification.Name("history-did-sync")
    static let envDidSync = Notification.Name("env-did-sync")
    static let envVarDidSync = Notification.Name("env-var-did-sync")
    static let databaseWillUpdate = Notification.Name("database-will-update")
    static let databaseDidUpdate = Notification.Name("database-did-update")
    static let clearCurrentWorkspace = Notification.Name("clear-current-workspace")
}
