// NotificationService

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        defer {
            contentHandler(bestAttemptContent ?? request.content)
        }
        if let bestAttemptContent = bestAttemptContent {
            var isActionExist = false
            var isPageExist = false
            // Modify the notification content here...
            //bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            let userInfo = bestAttemptContent.userInfo
            if let actionArry = userInfo["actions"] as? [[String: String]],
                actionArry.count > 0,
                actionArry[0]["name"]?.lowercased() == "open app" {
                isActionExist = true
            }
            
            if let urlImageString = userInfo["page"] as? String, nil != URL(string: urlImageString) {
                /// Add the category so the "Open Board" action button is added.
                isPageExist = true
            }
            
            if isPageExist && isActionExist {
                bestAttemptContent.categoryIdentifier = "OPENPAGE_ACTION"
            } else if isPageExist {
                bestAttemptContent.categoryIdentifier = "OPENPAGE"
            } else if isActionExist {
                bestAttemptContent.categoryIdentifier = "ACTION"
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}
