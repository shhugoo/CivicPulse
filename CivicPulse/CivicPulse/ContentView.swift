import SwiftUI

struct ContentView: View {
    @State private var showLogin = false
    @StateObject private var authStore = AuthStore()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                LinearGradient(
                    colors: [Color(red: 0.31, green: 0.91, blue: 0.94), Color(red: 0.19, green: 0.78, blue: 0.87)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Soft concentric rings hint at a city-wide pulse without competing with the name.
                Circle()
                    .stroke(.black.opacity(0.055), lineWidth: 1)
                    .frame(width: min(geometry.size.width * 1.15, 520))
                    .overlay {
                        Circle()
                            .stroke(.black.opacity(0.045), lineWidth: 1)
                            .frame(width: min(geometry.size.width * 0.82, 370))
                    }
                    .position(x: geometry.size.width * 0.82, y: geometry.size.height * 0.22)

                    if showLogin {
                        loginScreen(width: geometry.size.width, height: geometry.size.height)
                            .transition(.opacity)
                    } else {
                        VStack(spacing: 18) {
                            brand(width: geometry.size.width)
                            PulseLine()
                                .frame(height: 72)
                                .padding(.horizontal, 34)
                        }
                        .padding(.horizontal, 24)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .preferredColorScheme(.light)
            .task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.55)) {
                    showLogin = true
                }
            }
        }
    }

    private func brand(width: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text("smart cities")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(2.6)
                .foregroundStyle(.black.opacity(0.58))

            Text("CivicPulse")
                .font(.system(size: min(width * 0.145, 66), weight: .black, design: .rounded))
                .tracking(-2.8)
                .foregroundStyle(.black)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
        }
    }

    private func loginScreen(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            brand(width: width)
                .padding(.horizontal, 24)
                .padding(.top, max(height * 0.11, 48))

            PulseLine()
                .frame(height: 72)
                .padding(.horizontal, 36)
                .padding(.top, 24)

            Spacer()

            VStack(spacing: 14) {
                NavigationLink {
                    RegistrationView(authStore: authStore)
                } label: {
                    accessButtonLabel("Registrarse")
                }
                .buttonStyle(.plain)
                NavigationLink {
                    LoginView(authStore: authStore)
                } label: {
                    accessButtonLabel("Iniciar sesión")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, max(height * 0.14, 56))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func accessButtonLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct PulseLine: View {
    @State private var progress: CGFloat = 0

    private let trace: [CGPoint] = [
        CGPoint(x: 0, y: 0.5), CGPoint(x: 0.25, y: 0.5), CGPoint(x: 0.32, y: 0.5),
        CGPoint(x: 0.37, y: 0.18), CGPoint(x: 0.42, y: 0.84), CGPoint(x: 0.47, y: 0.08),
        CGPoint(x: 0.53, y: 0.5), CGPoint(x: 0.72, y: 0.5), CGPoint(x: 1, y: 0.5)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                pulsePath(in: geometry.size)
                .stroke(.black.opacity(0.13), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                pulsePath(in: geometry.size)
                .trimmedPath(from: 0, to: progress)
                .stroke(.black, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.65).repeatForever(autoreverses: false)) {
                progress = 1
            }
        }
    }

    private func pulsePath(in size: CGSize) -> Path {
        Path { path in
            for (index, point) in trace.enumerated() {
                let mapped = CGPoint(x: point.x * size.width, y: point.y * size.height)
                if index == 0 { path.move(to: mapped) } else { path.addLine(to: mapped) }
            }
        }
    }
}

#Preview {
    ContentView()
}
