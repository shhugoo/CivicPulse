import SwiftUI

struct ProfileDetailsView: View {
    let profile: CivicPulseProfile

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.31, green: 0.91, blue: 0.94), Color(red: 0.19, green: 0.78, blue: 0.87)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 13) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 43))
                            .foregroundStyle(.black.opacity(0.78))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Datos personales")
                                .font(.system(size: 23, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                            Text("Tu perfil de CivicPulse")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.black.opacity(0.6))
                        }
                    }
                    .padding(.top, 28)

                    VStack(spacing: 0) {
                        profileRow("Nombre", value: profile.firstName, symbol: "person.fill")
                        profileRow("Apellidos", value: profile.lastName, symbol: "person.2.fill")
                        if let nickname = profile.nickname, !nickname.isEmpty {
                            profileRow("Nickname", value: nickname, symbol: "at")
                        }
                        profileRow(
                            "Correo o teléfono",
                            value: profile.identifier,
                            symbol: profile.identifier.contains("@") ? "envelope.fill" : "phone.fill"
                        )
                        if let birthDate = profile.birthDate {
                            profileRow("Fecha de nacimiento", value: birthDate.formatted(date: .long, time: .omitted), symbol: "calendar")
                        }
                        if let city = profile.city {
                            profileRow("Ubicación", value: city, symbol: "mappin.and.ellipse", isLast: true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.light)
    }

    private func profileRow(_ title: String, value: String, symbol: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.68))
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(.black.opacity(0.48))
                    Text(value)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 13)

            if !isLast {
                Rectangle()
                    .fill(.black.opacity(0.07))
                    .frame(height: 1)
            }
        }
    }
}
