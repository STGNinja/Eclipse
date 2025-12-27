//
//  MapPreview.swift
//  Eclipse
//
//  Created by Jaxon Smith on 12/18/25.
//

import SwiftUI
import MapKit

struct MapPreview: View {
    let data: MapData
    @State private var region: MKCoordinateRegion
    
    init(data: MapData) {
        self.data = data
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: data.latitude, longitude: data.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Map(coordinateRegion: $region, annotationItems: [data]) { item in
                MapMarker(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude), tint: .orange)
            }
            .frame(height: 160)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                if let subtitle = data.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)
            
            Button {
                let coordinate = CLLocationCoordinate2D(latitude: data.latitude, longitude: data.longitude)
                let placemark = MKPlacemark(coordinate: coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = data.title
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Open in Maps")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
        )
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .frame(width: 280)
    }
}
