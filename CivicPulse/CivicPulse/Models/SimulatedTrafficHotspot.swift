import MapKit
import SwiftUI

enum TrafficCondition: String, CaseIterable {
    case fluid = "Fluido"
    case moderate = "Moderado"
    case dense = "Denso"

    var color: Color {
        switch self {
        case .fluid: return Color(red: 0.12, green: 0.62, blue: 0.32)
        case .moderate: return Color(red: 0.95, green: 0.63, blue: 0.10)
        case .dense: return Color(red: 0.82, green: 0.18, blue: 0.16)
        }
    }
}

struct SimulatedTrafficHotspot: Identifiable {
    let id: String
    let street: String
    let coordinate: CLLocationCoordinate2D
    let radiusMeters: CLLocationDistance
    let cycle: [TrafficCondition]

    func condition(at step: Int) -> TrafficCondition {
        cycle[step % cycle.count]
    }

    static let salamanca: [SimulatedTrafficHotspot] = [
        SimulatedTrafficHotspot(
            id: "plaza-espana",
            street: "Plaza de España",
            coordinate: CLLocationCoordinate2D(latitude: 40.9650, longitude: -5.6635),
            radiusMeters: 460,
            cycle: [.moderate, .dense, .dense, .fluid]
        ),
        SimulatedTrafficHotspot(
            id: "gran-via",
            street: "Gran Vía",
            coordinate: CLLocationCoordinate2D(latitude: 40.9622, longitude: -5.6601),
            radiusMeters: 390,
            cycle: [.fluid, .moderate, .dense, .moderate]
        ),
        SimulatedTrafficHotspot(
            id: "carmelitas",
            street: "Paseo de Carmelitas",
            coordinate: CLLocationCoordinate2D(latitude: 40.9658, longitude: -5.6772),
            radiusMeters: 420,
            cycle: [.dense, .fluid, .moderate, .fluid]
        ),
        SimulatedTrafficHotspot(
            id: "canalejas",
            street: "Paseo de Canalejas",
            coordinate: CLLocationCoordinate2D(latitude: 40.9609, longitude: -5.6562),
            radiusMeters: 360,
            cycle: [.moderate, .fluid, .moderate, .dense]
        )
    ]
}
