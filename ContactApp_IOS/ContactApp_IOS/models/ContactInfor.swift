class ContactInfor {
    var contactID: String
    var displayName: String
    var phoneNumber: String?

    init(contactID: String, displayName: String, phoneNumber: String?) {
        self.contactID = contactID
        self.displayName = displayName
        self.phoneNumber = phoneNumber
    }
    
    // Convert ContactInfor object to a dictionary
    func toDictionary() -> [String: Any] {
        return [
            "contactID": contactID,
            "displayName": displayName,
            "phoneNumber": phoneNumber ?? ""
        ]
    }
}
