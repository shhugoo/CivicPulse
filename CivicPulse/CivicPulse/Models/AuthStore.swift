import Foundation
import Combine
import SwiftUI

@MainActor
final class AuthStore: ObservableObject {
    private struct Account {
        let identifier: String
        let password: String
    }

    @Published private var account: Account?

    func register(identifier: String, password: String) -> String? {
        guard account == nil else {
            return "Ya hay una cuenta registrada en esta sesión."
        }

        account = Account(identifier: Self.normalized(identifier), password: password)
        return nil
    }

    func signIn(identifier: String, password: String) -> Bool {
        guard let account else { return false }
        return account.identifier == Self.normalized(identifier) && account.password == password
    }

    private static func normalized(_ identifier: String) -> String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
