import MapKit
import SwiftUI

struct IncidentNavigationView: View {
    let incident: CivicIncident
    let cityMapData: CityMapData
    let route: PlannedRoute
    @State private var cameraPosition: MapCameraPosition
    @State private var visibleRegion: MKCoordinateRegion
    @State private var trafficStep = 0
    @State private var responderProgress: Double

    init(incident: CivicIncident, cityMapData: CityMapData, route: PlannedRoute, startingProgress: Double) {
        self.incident = incident
        self.cityMapData = cityMapData
        self.route = route
        _responderProgress = State(initialValue: startingProgress)
        let origin = route.option.coordinates.first ?? incident.coordinate
        let center = CLLocationCoordinate2D(
            latitude: (origin.latitude + incident.coordinate.latitude) / 2,
            longitude: (origin.longitude + incident.coordinate.longitude) / 2
        )
        let initialRegion = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.023, longitudeDelta: 0.027)
        )
        _cameraPosition = State(initialValue: .region(initialRegion))
        _visibleRegion = State(initialValue: initialRegion)
    }

    var body: some View {
        Map(position: $cameraPosition) {
            trafficHeatmap

            MapPolyline(coordinates: route.option.coordinates)
                .stroke(Color(red: 0.05, green: 0.31, blue: 0.83), lineWidth: 7)

            if let origin = route.option.coordinates.first {
                Annotation("Base de respuesta", coordinate: origin, anchor: .bottom) {
                    mapMarker(symbol: "building.2.fill", color: .black)
                }
            }

            Annotation("Unidad de \(incident.service.rawValue.lowercased())", coordinate: responderCoordinate, anchor: .center) {
                HStack(spacing: 6) {
                    Image(systemName: incident.service.symbol)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color(red: 0.05, green: 0.31, blue: 0.83), in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                    Text(incident.service.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.96), in: Capsule())
                }
            }

            Annotation("Destino: \(incident.address)", coordinate: incident.coordinate, anchor: .bottom) {
                VStack(spacing: 4) {
                    Text("DESTINO")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(incident.priority.color, in: Capsule())
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 25, weight: .black))
                        .foregroundStyle(incident.priority.color)
                        .shadow(color: .white, radius: 2)
                }
            }

            Annotation("Calle cortada por obras", coordinate: cityMapData.closureCoordinate, anchor: .bottom) {
                Label("Obras", systemImage: "cone.fill")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.red, in: Capsule())
            }
        }
        .mapControls { MapCompass(); MapScaleView() }
        .mapStyle(.standard(elevation: .flat))
        .onMapCameraChange(frequency: .continuous) { context in
            visibleRegion = context.region
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 3) {
                Text("RUTA ÓPTIMA · SIMULACIÓN")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.6)
                Text(route.option.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.leading, 14)
            .padding(.top, 12)
        }
        .overlay(alignment: .trailing) {
            VStack(spacing: 9) {
                zoomButton("plus", label: "Ampliar mapa") { zoom(by: 0.62) }
                zoomButton("minus", label: "Alejar mapa") { zoom(by: 1.6) }
            }
            .padding(.trailing, 14)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            navigationPanel
        }
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationTitle("Navigation")
        .navigationBarTitleDisplayMode(.inline)
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
            while !Task.isCancelled && responderProgress < 1 {
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

    private var navigationPanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: responderProgress >= 1 ? "checkmark" : "arrow.turn.up.right")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color(red: 0.05, green: 0.31, blue: 0.83), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(responderProgress >= 1 ? "Has llegado al destino" : "Siguiente indicación")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.57))
                    Text(currentInstruction)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                }
                Spacer(minLength: 2)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("~\(route.estimatedMinutes) min")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                    Text(String(format: "%.1f km", route.option.distanceKilometers))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.black.opacity(0.55))
                }
            }

            Rectangle().fill(.black.opacity(0.08)).frame(height: 1)

            HStack {
                Label("Tráfico simulado", systemImage: "circle.grid.3x3.fill")
                Spacer()
                Label("\(route.option.name)", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Color(red: 0.05, green: 0.31, blue: 0.7))
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.black.opacity(0.7))

            Text("Destino: \(incident.address)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
        .padding(.horizontal, 11)
        .padding(.bottom, 8)
    }

    private var currentInstruction: String {
        let index = min(Int(responderProgress * Double(route.option.directions.count)), route.option.directions.count - 1)
        return route.option.directions[max(index, 0)]
    }

    private var responderCoordinate: CLLocationCoordinate2D {
        let coordinates = route.option.coordinates
        guard coordinates.count > 1 else { return coordinates.first ?? incident.coordinate }
        let scaled = min(max(responderProgress, 0), 1) * Double(coordinates.count - 1)
        let startIndex = min(Int(scaled), coordinates.count - 2)
        let fraction = scaled - Double(startIndex)
        let start = coordinates[startIndex]
        let end = coordinates[startIndex + 1]
        return CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * fraction,
            longitude: start.longitude + (end.longitude - start.longitude) * fraction
        )
    }

    private func mapMarker(symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(9)
            .background(color, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
    }

    private func zoomButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
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
