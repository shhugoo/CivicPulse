import MapKit
import SwiftUI

struct IncidentMapView: View {
    let incident: CivicIncident
    let cityMapData: CityMapData
    @State private var cameraPosition: MapCameraPosition
    @State private var visibleRegion: MKCoordinateRegion
    @State private var trafficStep = 0
    @State private var responderProgress = 0.0
    @State private var incidentSelected = false
    @State private var showNavigation = false
    @State private var plannedRoute: PlannedRoute?
    @State private var isLoadingRoutes = false
    @State private var routeLoadingError: String?
    @State private var rankedRoutes: [PlannedRoute] = []
    @State private var selectedRouteID: String?

    init(incident: CivicIncident, cityMapData: CityMapData, startingTrafficStep: Int = 0) {
        self.incident = incident
        self.cityMapData = cityMapData
        let origin = incident.vehicleRoute.first ?? incident.coordinate
        let center = CLLocationCoordinate2D(
            latitude: (origin.latitude + incident.coordinate.latitude) / 2,
            longitude: (origin.longitude + incident.coordinate.longitude) / 2
        )
        let initialRegion = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.027, longitudeDelta: 0.032)
        )
        _cameraPosition = State(initialValue: .region(initialRegion))
        _visibleRegion = State(initialValue: initialRegion)
        _trafficStep = State(initialValue: startingTrafficStep % 4)
    }

    var body: some View {
        Map(position: $cameraPosition) {
            trafficHeatmap

            Annotation("Calle cortada por obras", coordinate: cityMapData.closureCoordinate, anchor: .bottom) {
                Label("Obras", systemImage: "cone.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color(red: 0.72, green: 0.23, blue: 0.12), in: Capsule())
                    .overlay(Capsule().stroke(.white, lineWidth: 1.5))
            }

            ForEach(cityMapData.incidents.filter { $0.id != incident.id }) { otherIncident in
                Annotation("Incidente: \(otherIncident.address)", coordinate: otherIncident.coordinate, anchor: .bottom) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 29, height: 29)
                        .background(otherIncident.priority.color, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }

                Annotation(
                    "Unidad de \(otherIncident.service.rawValue.lowercased()) en movimiento",
                    coordinate: coordinate(otherIncident.vehicleRoute, progress: responderProgress),
                    anchor: .center
                ) {
                    Image(systemName: otherIncident.service.symbol)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 23, height: 23)
                        .background(Color(red: 0.08, green: 0.35, blue: 0.83), in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                }
            }

            Annotation("Unidad de \(incident.service.rawValue.lowercased()) en movimiento", coordinate: responderCoordinate, anchor: .center) {
                HStack(spacing: 6) {
                    Image(systemName: incident.service.symbol)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color(red: 0.08, green: 0.35, blue: 0.83), in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                    Text(incident.service.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.96), in: Capsule())
                }
            }

            Annotation("Incidente: \(incident.address)", coordinate: incident.coordinate, anchor: .bottom) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        incidentSelected = true
                    }
                    Task { await loadRoutes() }
                } label: {
                    VStack(spacing: 5) {
                        Text("INCIDENTE · TOCA AQUÍ")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.5)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(incident.priority.color, in: Capsule())
                        Image(systemName: incident.service.symbol)
                            .font(.system(size: 23, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(incident.priority.color, in: Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                            .shadow(color: .black.opacity(0.25), radius: 7, y: 3)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .flat))
        .onMapCameraChange(frequency: .continuous) { context in
            visibleRegion = context.region
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Image(systemName: "location.fill")
                Text("\(cityMapData.cityName.uppercased()) · TRÁFICO SIMULADO")
                        .tracking(0.6)
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white.opacity(0.94), in: Capsule())

                HStack(spacing: 7) {
                    ForEach(TrafficCondition.allCases, id: \.rawValue) { condition in
                        HStack(spacing: 3) {
                            Circle().fill(condition.color).frame(width: 7, height: 7)
                            Text(condition.rawValue)
                                .foregroundStyle(.black.opacity(0.72))
                        }
                    }
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(.white.opacity(0.9), in: Capsule())
            }
            .padding(.leading, 14)
            .padding(.top, 12)
        }
        .overlay(alignment: .trailing) {
            VStack(spacing: 9) {
                mapZoomButton(symbol: "plus", label: "Ampliar mapa") { zoom(by: 0.62) }
                mapZoomButton(symbol: "minus", label: "Alejar mapa") { zoom(by: 1.6) }
            }
            .padding(.trailing, 14)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if incidentSelected {
                routeAnalysisPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                mapHint
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle("Mapa del incidente")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showNavigation) {
            if let plannedRoute {
                IncidentNavigationView(
                    incident: incident,
                    cityMapData: cityMapData,
                    route: plannedRoute,
                    startingProgress: 0
                )
            }
        }
        .task {
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(4)) } catch { break }
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.8)) {
                    trafficStep = (trafficStep + 1) % 4
                }
            }
        }
        .task {
            while !Task.isCancelled && responderProgress < 1 && !incidentSelected {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                guard !Task.isCancelled else { break }
                withAnimation(.linear(duration: 0.9)) {
                    responderProgress = min(responderProgress + 0.025, 1)
                }
            }
        }
    }

    @MapContentBuilder
    private var trafficHeatmap: some MapContent {
        ForEach(cityMapData.trafficHotspots) { hotspot in
            let color = hotspot.condition(at: trafficStep).color
            MapCircle(center: hotspot.coordinate, radius: hotspot.radiusMeters)
                .foregroundStyle(color.opacity(0.10))
            MapCircle(center: hotspot.coordinate, radius: hotspot.radiusMeters * 0.68)
                .foregroundStyle(color.opacity(0.15))
            MapCircle(center: hotspot.coordinate, radius: hotspot.radiusMeters * 0.35)
                .foregroundStyle(color.opacity(0.23))
        }
    }

    private var responderCoordinate: CLLocationCoordinate2D {
        coordinate(incident.vehicleRoute, progress: responderProgress)
    }

    private func coordinate(_ route: [CLLocationCoordinate2D], progress: Double) -> CLLocationCoordinate2D {
        guard route.count > 1 else { return route.first ?? incident.coordinate }
        let scaledProgress = min(max(progress, 0), 1) * Double(route.count - 1)
        let startIndex = min(Int(scaledProgress), route.count - 2)
        let fraction = scaledProgress - Double(startIndex)
        let start = route[startIndex]
        let end = route[startIndex + 1]
        return CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * fraction,
            longitude: start.longitude + (end.longitude - start.longitude) * fraction
        )
    }

    private var mapHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(red: 0.08, green: 0.35, blue: 0.83))
            VStack(alignment: .leading, spacing: 3) {
                Text(responderProgress >= 1 ? "Unidad en el incidente" : "Unidad en movimiento · ubicación simulada")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                Text(responderProgress >= 1 ? "Pulsa el marcador grande para analizar el incidente." : "Pulsa el marcador grande del incidente para analizarlo.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.62))
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var routeAnalysisPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Route Analysis")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                    Text(incident.address)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.62))
                        .lineLimit(1)
                }
                Spacer()
                Text(rankedRoutes.isEmpty ? "ORS" : "\(rankedRoutes.count) RUTAS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(.black.opacity(0.7))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.06), in: Capsule())
            }

            if isLoadingRoutes {
                HStack(spacing: 10) {
                    ProgressView().tint(.blue)
                    Text("Calculando rutas con OpenRouteService…")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let routeLoadingError {
                VStack(alignment: .leading, spacing: 9) {
                    Text(routeLoadingError)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.red)
                    Button("Reintentar cálculo") { Task { await loadRoutes() } }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                }
            }

            if let selectedRoute, !selectedRoute.disturbances.isEmpty {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(selectedRoute.disturbances) { disturbance in
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: disturbance.symbol)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(disturbance.blocked ? Color.red : Color.orange)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(disturbance.title)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(.black)
                                    Text(disturbance.detail)
                                        .font(.system(size: 10, weight: .regular, design: .rounded))
                                        .foregroundStyle(.black.opacity(0.62))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                .frame(maxHeight: 100)
                .scrollIndicators(.hidden)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Comparativa de rutas")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.7))
                ForEach(rankedRoutes, id: \.option.id) { route in
                    Button {
                        selectedRouteID = route.option.id
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: route.isBlocked ? "xmark.circle.fill" : "point.topleft.down.to.point.bottomright.curvepath")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(route.isBlocked ? Color.red : Color.blue)
                            Text(route.option.name)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.black.opacity(0.8))
                            Spacer()
                            Text(route.isBlocked ? "Cerrada" : "~\(route.estimatedMinutes) min · \(route.option.distanceKilometers.formatted(.number.precision(.fractionLength(1)))) km")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(route.isBlocked ? Color.red : Color.black)
                            if route.option.id == selectedRouteID && !route.isBlocked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(route.isBlocked)
                    .padding(.vertical, 3)
                }
            }

            if !rankedRoutes.isEmpty {
                Link("© OpenStreetMap contributors · OpenRouteService", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
            }

            Button(action: startNavigation) {
                HStack(spacing: 8) {
                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    Text("Iniciar navegación")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 0.05, green: 0.20, blue: 0.37), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(selectedRoute == nil || isLoadingRoutes)
            .opacity(selectedRoute == nil || isLoadingRoutes ? 0.55 : 1)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 7)
    }

    private func loadRoutes() async {
        guard !isLoadingRoutes else { return }
        isLoadingRoutes = true
        routeLoadingError = nil
        defer { isLoadingRoutes = false }

        do {
            let alternatives = try await OpenRouteService().calculateDrivingRoutes(
                from: responderCoordinate,
                to: incident.coordinate,
                alternativeCount: 3
            )
            guard !Task.isCancelled else { return }
            rankedRoutes = RoutePlanner.rank(
                alternatives,
                trafficStep: trafficStep,
                hotspots: cityMapData.trafficHotspots,
                closureCoordinate: cityMapData.closureCoordinate
            )
            selectedRouteID = rankedRoutes.first(where: { !$0.isBlocked })?.option.id
            if selectedRouteID == nil { routeLoadingError = "Todas las alternativas atraviesan una calle cortada." }
        } catch {
            routeLoadingError = error.localizedDescription
        }
    }

    private var selectedRoute: PlannedRoute? {
        rankedRoutes.first(where: { $0.option.id == selectedRouteID && !$0.isBlocked })
    }

    private func startNavigation() {
        guard let selectedRoute else { return }
        plannedRoute = selectedRoute
        showNavigation = true
    }

    private func mapZoomButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 46, height: 46)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func zoom(by factor: Double) {
        let span = MKCoordinateSpan(
            latitudeDelta: min(max(visibleRegion.span.latitudeDelta * factor, 0.003), 0.08),
            longitudeDelta: min(max(visibleRegion.span.longitudeDelta * factor, 0.003), 0.08)
        )
        let region = MKCoordinateRegion(center: visibleRegion.center, span: span)
        withAnimation(.easeInOut(duration: 0.25)) {
            visibleRegion = region
            cameraPosition = .region(region)
        }
    }
}
