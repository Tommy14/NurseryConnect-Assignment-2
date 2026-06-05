//
//  SpatialTransportTrackerView.swift
//  NurseryConnect Spatial
//
//  Feature: Spatial
//  Created: 4 June 2026
//  Description: Live school-run tracker with simulated van movement, manifest, and ETA.
//

import Combine
import MapKit
import SwiftUI

struct SpatialTransportTrackerView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var dataStore: SpatialDataStore

    @State private var run: NCTransportRun = .sampleRun
    @State private var routeIndex = 0
    @State private var cameraPosition: MapCameraPosition = .automatic

    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            statusBar
            HStack(alignment: .top, spacing: 20) {
                mapPanel
                manifestPanel
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background {
            LinearGradient(
                colors: [Color.ncBackground, Color.ncGlowBlue.opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        .task { run = dataStore.transport }
        .onReceive(timer) { _ in advanceVan() }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "bus.fill")
                .foregroundStyle(Color.ncPrimary)
            Text("Van in transit · \(run.boardedCount) of \(run.children.count) children boarded · ETA \(run.estimatedArrival, style: .time)")
                .font(.ncCaption.weight(.semibold))
            Spacer()
            Button("Done") { dismissWindow(id: SpatialWindowID.transport) }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 0, style: .continuous))
    }

    // MARK: - Map

    private var mapPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live route")
                .font(.ncHeadline)

            Map(position: $cameraPosition) {
                Annotation("Nursery Van", coordinate: vanMapCoord) {
                    ZStack {
                        Circle()
                            .fill(Color.ncPrimary)
                            .frame(width: 36, height: 36)
                        Image(systemName: "bus.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 4)
                }
                ForEach(run.routePath.indices, id: \.self) { i in
                    if i > 0 {
                        Annotation("Stop \(i)", coordinate: CLLocationCoordinate2D(latitude: run.routePath[i].latitude, longitude: run.routePath[i].longitude)) {
                            Circle()
                                .fill(Color.ncAccentWarm.opacity(0.8))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                Annotation("Nursery", coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)) {
                    ZStack {
                        Circle().fill(Color.ncSecondary).frame(width: 32, height: 32)
                        Image(systemName: "building.2.fill").font(.caption2).foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var vanMapCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: run.vanCoordinate.latitude, longitude: run.vanCoordinate.longitude)
    }

    // MARK: - Manifest

    private var manifestPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Transport manifest")
                    .font(.ncHeadline)
                Text(run.routeName)
                    .font(.ncCaption)
                    .foregroundStyle(.secondary)
            }

            if run.boardedCount == run.children.count {
                Label("All children accounted for ✅", systemImage: "checkmark.circle.fill")
                    .font(.ncCaption.weight(.semibold))
                    .foregroundStyle(Color.ncSecondary)
                    .padding(10)
                    .background(Color.ncSecondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(spacing: 8) {
                ForEach(run.children) { child in
                    manifestRow(child)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(Color.ncAccentWarm)
                Text("ETA: \(run.estimatedArrival, style: .time)")
                    .font(.ncHeadline)
            }
            .padding(14)
            .background(Color.ncAccentWarm.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(20)
        .frame(width: 320)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func manifestRow(_ child: NCTransportChild) -> some View {
        HStack(spacing: 12) {
            statusIcon(for: child.status)
            VStack(alignment: .leading, spacing: 2) {
                Text(child.childName)
                    .font(.ncCaption.weight(.semibold))
                Text(child.school)
                    .font(.ncCaption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let t = child.boardingTime {
                Text(t, style: .time)
                    .font(.ncCaption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            transportStatusBadge(child.status)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func statusIcon(for status: NCTransportStatus) -> some View {
        switch status {
        case .boarded:  Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.ncSecondary)
        case .awaiting: Image(systemName: "clock.circle").foregroundStyle(.secondary)
        case .notFound: Image(systemName: "questionmark.circle.fill").foregroundStyle(Color.ncAccentWarm)
        }
    }

    @ViewBuilder
    private func transportStatusBadge(_ status: NCTransportStatus) -> some View {
        let (label, color): (String, Color) = {
            switch status {
            case .boarded:  return ("Boarded ✅", Color.ncSecondary)
            case .awaiting: return ("Awaiting", .secondary)
            case .notFound: return ("Not found ⚠️", Color.ncAccentWarm)
            }
        }()
        Text(label)
            .font(.ncCaption2.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }

    // MARK: - Simulate van movement

    private func advanceVan() {
        let path = run.routePath
        guard !path.isEmpty else { return }
        routeIndex = (routeIndex + 1) % path.count
        let next = path[routeIndex]
        run.vanCoordinate = next

        if routeIndex < run.children.count {
            var children = run.children
            if children[routeIndex].status == .awaiting {
                children[routeIndex].status = .boarded
                children[routeIndex].boardingTime = Date()
            }
            run.children = children
        }
    }
}
