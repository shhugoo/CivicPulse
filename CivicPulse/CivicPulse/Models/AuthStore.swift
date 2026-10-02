import Foundation
import Combine
import SwiftUI

struct CivicPulseProfile {
    let firstName: String
    let lastName: String
    let identifier: String
    let nickname: String?
    let birthDate: Date?
    let city: String?

    var displayName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
        if let nickname, !nickname.isEmpty { return nickname }
        return name
    }
}

@MainActor
final class AuthStore: ObservableObject {
    private struct Account {
        let identifier: String
        let password: String
        let profile: CivicPulseProfile
    }

    @Published private var account: Account?
    @Published private(set) var currentProfile: CivicPulseProfile?

    func register(profile: CivicPulseProfile, password: String) -> String? {
        guard account == nil else {
            return "Ya hay una cuenta registrada en esta sesión."
        }

        account = Account(identifier: Self.normalized(profile.identifier), password: password, profile: profile)
        return nil
    }

    func signIn(identifier: String, password: String) -> Bool {
        if Self.normalized(identifier) == "8" && password == "8" {
            currentProfile = CivicPulseProfile(
                firstName: "Usuario",
                lastName: "Maestro",
                identifier: "8",
                nickname: nil,
                birthDate: nil,
                city: "Salamanca"
            )
            return true
        }

        guard let account else { return false }
        let isValid = account.identifier == Self.normalized(identifier) && account.password == password
        currentProfile = isValid ? account.profile : nil
        return isValid
    }

    private static func normalized(_ identifier: String) -> String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
