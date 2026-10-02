import SwiftUI

struct LoginView: View {
    @ObservedObject var authStore: AuthStore
    @State private var identifier = ""
    @State private var password = ""
    @State private var message: String?
    @State private var signInSucceeded = false
    @State private var showDashboard = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.31, green: 0.91, blue: 0.94), Color(red: 0.19, green: 0.78, blue: 0.87)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 9) {
                            Text("smart cities")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(2.6)
                                .foregroundStyle(.black.opacity(0.58))
                            Text("CivicPulse")
                                .font(.system(size: min(geometry.size.width * 0.13, 56), weight: .black, design: .rounded))
                                .tracking(-2.5)
                                .foregroundStyle(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                        }
                        .padding(.top, 28)

                        VStack(alignment: .leading, spacing: 18) {
                            Text("Iniciar sesión")
                                .font(.system(size: 27, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)

                            VStack(alignment: .leading, spacing: 7) {
                                Text("Correo electrónico o teléfono")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.7))
                                TextField("Correo electrónico o teléfono", text: $identifier)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.black)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.default)
                                    .textContentType(.username)
                                    .padding(.horizontal, 15)
                                    .frame(height: 52)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                                            .stroke(.black.opacity(0.08), lineWidth: 1)
                                    }
                            }

                            VStack(alignment: .leading, spacing: 7) {
                                Text("Contraseña")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.7))
                                SecureField("Contraseña", text: $password)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.black)
                                    .textContentType(.password)
                                    .textInputAutocapitalization(.never)
                                    .padding(.horizontal, 15)
                                    .frame(height: 52)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                                            .stroke(.black.opacity(0.08), lineWidth: 1)
                                    }
                            }

                            HStack {
                                Spacer()
                                Button("Olvidé mi contraseña") { }
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.black.opacity(0.72))
                            }

                            if let message {
                                Text(message)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(signInSucceeded ? Color(red: 0.08, green: 0.43, blue: 0.25) : Color(red: 0.64, green: 0.12, blue: 0.12))
                            }
                        }
                        .padding(22)
                        .frame(maxWidth: 500, alignment: .leading)
                        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 26, style: .continuous))

                        Button(action: signIn) {
                            Text("Iniciar sesión")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: 500)
                                .frame(height: 58)
                                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 4) {
                            Text("¿No tienes cuenta?")
                                .foregroundStyle(.black.opacity(0.65))
                            NavigationLink {
                                RegistrationView(authStore: authStore)
                            } label: {
                                Text("Regístrate")
                                    .fontWeight(.bold)
                                    .underline()
                                    .foregroundStyle(.black)
                            }
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .padding(.bottom, 28)
                    }
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.light)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationDestination(isPresented: $showDashboard) {
            DashboardView(authStore: authStore)
        }
    }

    private func signIn() {
        signInSucceeded = authStore.signIn(identifier: identifier, password: password)
        if signInSucceeded {
            message = "Inicio de sesión correcto."
            showDashboard = true
        } else {
            message = "No se encontró una cuenta con esos datos. Comprueba tu teléfono o correo y contraseña."
        }
    }
}
