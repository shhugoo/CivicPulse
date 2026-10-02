import MapKit
import SwiftUI

struct DashboardView: View {
    @ObservedObject var authStore: AuthStore
    @State private var showProfileDetails = false
    @State private var showSimulationLoading = false
    @State private var simulationGeneration = 0
    @State private var cityMapData = CityMapData.salamanca
    @State private var isLoadingCity = false
    @State private var cityLoadError: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.31, green: 0.91, blue: 0.94), Color(red: 0.19, green: 0.78, blue: 0.87)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CivicPulse")
                                .font(.system(size: 31, weight: .black, design: .rounded))
                                .tracking(-1.5)
                                .foregroundStyle(.black)
                            Text("Centro de operaciones · \(selectedCity)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.black.opacity(0.62))
                        }
                        Spacer()
                        Button {
                            showProfileDetails = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.7), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Ajustes y datos personales")
                    }
                    .padding(.top, 14)

                    profileCard

                    HStack(alignment: .center) {
                        Label("Incidentes", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                        Spacer()
                        Text("\(cityMapData.incidents.count) activos")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.68))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.65), in: Capsule())
                    }
                    .padding(.top, 4)

                    Button {
                        showSimulationLoading = true
                    } label: {
                        Label("Simular datos", systemImage: "sparkles")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(red: 0.05, green: 0.20, blue: 0.37), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if isLoadingCity {
                        ProgressView("Cargando mapa de \(selectedCity)…")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .tint(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 36)
                    } else if let cityLoadError {
                        VStack(spacing: 10) {
                            Text(cityLoadError)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.black.opacity(0.7))
                                .multilineTextAlignment(.center)
                            Button("Reintentar") {
                                Task { await loadCityMap() }
                            }
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    } else {
                        VStack(spacing: 13) {
                            ForEach(cityMapData.incidents) { incident in
                                NavigationLink {
                                    IncidentMapView(
                                        incident: incident,
                                        cityMapData: cityMapData,
                                        startingTrafficStep: simulationGeneration
                                    )
                                } label: {
                                    incidentCard(incident)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Text("Datos de tráfico e incidentes simulados para \(cityMapData.cityName)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 3)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 22)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.light)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $showProfileDetails) {
            if let profile = authStore.currentProfile {
                ProfileDetailsView(profile: profile)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .fullScreenCover(isPresented: $showSimulationLoading) {
            SimulationLoadingView(cityName: selectedCity) {
                simulationGeneration += 1
                showSimulationLoading = false
            }
            .interactiveDismissDisabled()
        }
        .task(id: selectedCity) {
            await loadCityMap()
        }
    }

    private var selectedCity: String {
        let savedCity = authStore.currentProfile?.city?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let savedCity, !savedCity.isEmpty { return savedCity }
        return "Salamanca"
    }

    @MainActor
    private func loadCityMap() async {
        let city = selectedCity
        cityLoadError = nil
        guard city.caseInsensitiveCompare("Salamanca") != .orderedSame else {
            cityMapData = .salamanca
            isLoadingCity = false
            return
        }

        isLoadingCity = true
        defer { isLoadingCity = false }

        let request = MKLocalSearch.Request(naturalLanguageQuery: "\(city), Spain")
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.0, longitude: -3.5),
            span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 18)
        )

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }
            guard let coordinate = response.mapItems.first?.placemark.coordinate else {
                cityLoadError = "No se pudo encontrar el mapa de \(city). Comprueba la conexión e inténtalo de nuevo."
                return
            }
            cityMapData = .centered(city: city, at: coordinate)
        } catch {
            guard !Task.isCancelled else { return }
            cityLoadError = "No se pudo cargar el mapa de \(city). Comprueba la conexión e inténtalo de nuevo."
        }
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.black.opacity(0.78))

            VStack(alignment: .leading, spacing: 5) {
                Text(authStore.currentProfile?.displayName ?? "Perfil")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                if let profile = authStore.currentProfile {
                    if profile.nickname?.isEmpty == false {
                        Text("\(profile.firstName) \(profile.lastName)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.62))
                    }
                    Label(profile.identifier, systemImage: profile.identifier.contains("@") ? "envelope.fill" : "phone.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.62))
                        .lineLimit(1)
                    if let city = profile.city {
                        Label(city, systemImage: "mappin.and.ellipse")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.62))
                    }
                    if let birthDate = profile.birthDate {
                        Label(birthDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.black.opacity(0.62))
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func incidentCard(_ incident: CivicIncident) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: incident.service.symbol)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 50, height: 50)
                .background(Color(red: 0.31, green: 0.91, blue: 0.94), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text(incident.address)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 2)
                    Text(incident.priority.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(incident.priority.color)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(incident.priority.color.opacity(0.11), in: Capsule())
                }

                Text(incident.description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.black.opacity(0.68))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 5) {
                    Text(incident.service.rawValue.uppercased())
                    Text("·")
                    Text("Ver ruta")
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.black.opacity(0.55))
                .padding(.top, 2)
            }
        }
        .padding(15)
        .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        }
    }
}
