import SwiftUI
import UIKit

struct RegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authStore: AuthStore
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var contact = ""
    @State private var password = ""
    @State private var repeatedPassword = ""
    @State private var nickname = ""
    @State private var hasBirthDate = false
    @State private var birthDate = Date()
    @State private var selectedCity: String?
    @State private var validationErrors: [String] = []
    @State private var showRegistrationSuccess = false

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
                    VStack(alignment: .leading, spacing: 22) {
                        header(width: geometry.size.width)

                        VStack(alignment: .leading, spacing: 18) {
                            Text("Tus datos")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)

                            inputField("Nombre", text: $firstName, required: true, contentType: .givenName)
                            inputField("Apellidos", text: $lastName, required: true, contentType: .familyName)
                            inputField(
                                "Teléfono o correo electrónico",
                                text: $contact,
                                required: true,
                                capitalization: .never
                            )
                            secureInputField("Contraseña", text: $password, required: true)
                            secureInputField("Repite la contraseña", text: $repeatedPassword, required: true)

                            Divider().overlay(.black.opacity(0.08))

                            Text("Datos opcionales")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.black.opacity(0.72))

                            inputField("Nickname", text: $nickname)
                            birthDateField
                            cityMenu
                        }
                        .padding(22)
                        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 26, style: .continuous))

                        Text("Los campos con * son obligatorios.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.58))
                            .padding(.horizontal, 4)

                        if !validationErrors.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(validationErrors, id: \.self) { error in
                                    Text("• \(error)")
                                }
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(red: 0.64, green: 0.12, blue: 0.12))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityElement(children: .combine)
                        }

                        Button(action: register) {
                            Text("Registrarse")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.light)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .alert("Registro completado", isPresented: $showRegistrationSuccess) {
            Button("Ir a iniciar sesión") { dismiss() }
        } message: {
            Text("Ya puedes iniciar sesión con tus datos de acceso.")
        }
    }

    private func header(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CivicPulse")
                .font(.system(size: min(width * 0.105, 42), weight: .black, design: .rounded))
                .tracking(-1.8)
                .foregroundStyle(.black)
            Text("Crea tu cuenta")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
            Text("Cuéntanos un poco sobre ti para empezar.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
        }
        .padding(.top, 4)
    }

    private func inputField(
        _ title: String,
        text: Binding<String>,
        required: Bool = false,
        contentType: UITextContentType? = nil,
        capitalization: TextInputAutocapitalization = .words
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 4) {
                Text(title)
                if required { Text("*").foregroundStyle(.black.opacity(0.65)) }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.black.opacity(0.7))

            TextField(title, text: text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .textContentType(contentType)
                .textInputAutocapitalization(capitalization)
                .keyboardType(.default)
                .padding(.horizontal, 15)
                .frame(height: 52)
                .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private func secureInputField(_ title: String, text: Binding<String>, required: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 4) {
                Text(title)
                if required { Text("*").foregroundStyle(.black.opacity(0.65)) }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.black.opacity(0.7))

            SecureField(title, text: text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 15)
                .frame(height: 52)
                .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private func register() {
        var errors: [String] = []

        if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Escribe tu nombre.")
        } else if !containsOnlyLettersAndSpaces(firstName) {
            errors.append("El nombre solo puede contener letras y espacios.")
        }

        if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Escribe tus apellidos.")
        } else if !containsOnlyLettersAndSpaces(lastName) {
            errors.append("Los apellidos solo pueden contener letras y espacios.")
        }

        if contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Escribe un teléfono o correo electrónico.")
        }
        if password.isEmpty { errors.append("Crea una contraseña.") }
        if repeatedPassword.isEmpty {
            errors.append("Repite la contraseña.")
        } else if password != repeatedPassword {
            errors.append("Las contraseñas no coinciden.")
        }

        if errors.isEmpty, let accountError = authStore.register(identifier: contact, password: password) {
            errors.append(accountError)
        }

        validationErrors = errors
        if errors.isEmpty { showRegistrationSuccess = true }
    }

    private func containsOnlyLettersAndSpaces(_ value: String) -> Bool {
        let allowedCharacters = CharacterSet.letters.union(.whitespaces)
        return !value.isEmpty && value.unicodeScalars.allSatisfy(allowedCharacters.contains)
    }

    private var birthDateField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Fecha de nacimiento")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.7))

            Toggle(isOn: $hasBirthDate.animation(.easeInOut(duration: 0.2))) {
                Text(hasBirthDate ? birthDate.formatted(date: .abbreviated, time: .omitted) : "Añadir fecha (opcional)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.black)
            }
            .tint(Color(red: 0.12, green: 0.65, blue: 0.72))
            .padding(.horizontal, 15)
            .frame(minHeight: 52)
            .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.black.opacity(0.08), lineWidth: 1)
            }

            if hasBirthDate {
                DatePicker("Fecha de nacimiento", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(.black)
            }
        }
    }

    private var cityMenu: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Ubicación")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.7))

            Menu {
                ForEach(SpanishCities.capitals, id: \.self) { city in
                    Button(city) { selectedCity = city }
                }
            } label: {
                HStack {
                    Text(selectedCity ?? "Selecciona una ciudad")
                        .foregroundStyle(selectedCity == nil ? .black.opacity(0.42) : .black)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black.opacity(0.55))
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .padding(.horizontal, 15)
                .frame(height: 52)
                .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                }
            }
            .accessibilityLabel("Ubicación opcional. Selecciona una ciudad de España")
        }
    }
}
