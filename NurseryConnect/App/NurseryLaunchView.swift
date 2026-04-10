//
//  NurseryLaunchView.swift
//  NurseryConnect
//
//  Feature: App
//  Role: Keyworker
//  Created: 10 April 2026
//  Description: UK nursery-themed animated loading screen shown briefly at app start.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 100426     Tommy1914   Created launch animation with playful nursery motifs and loading indicator.
// 100426     Tommy1914   Added rotating safeguarding subtitles for a more dynamic launch experience.
// -----------------------------------------------------------------

import Combine
import SwiftUI

struct NurseryLaunchView: View {
    @State private var isAnimating = false
    @State private var subtitleIndex = 0

    private let subtitles = [
        "Safeguarding checks in progress...",
        "Registering attendance for today...",
        "Preparing wellbeing snapshots..."
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.ncBackground, Color.ncPrimary.opacity(0.08), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.ncPrimary.opacity(0.14))
                .frame(width: 230, height: 230)
                .blur(radius: 42)
                .offset(x: -120, y: -240)

            Circle()
                .fill(Color.red.opacity(0.12))
                .frame(width: 190, height: 190)
                .blur(radius: 36)
                .offset(x: 110, y: 210)

            VStack(spacing: 20) {
                HStack(spacing: 14) {
                    Image(systemName: "building.columns.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.ncPrimary)
                    Text("NurseryConnect UK")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                }

                HStack(alignment: .bottom, spacing: 12) {
                    nurseryBlock(letter: "A", color: Color.ncPrimary, delay: 0.0)
                    nurseryBlock(letter: "B", color: Color.red.opacity(0.78), delay: 0.12)
                    nurseryBlock(letter: "C", color: Color.ncSecondary, delay: 0.24)
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.headline.weight(.semibold))
                    Text(subtitles[subtitleIndex])
                        .font(.subheadline.weight(.medium))
                        .contentTransition(.opacity)
                }
                .foregroundStyle(.secondary)
                .animation(.easeInOut(duration: 0.25), value: subtitleIndex)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.ncPrimary)
                    .scaleEffect(1.1)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            isAnimating = true
        }
        .onReceive(Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()) { _ in
            subtitleIndex = (subtitleIndex + 1) % subtitles.count
        }
    }

    private func nurseryBlock(letter: String, color: Color, delay: Double) -> some View {
        Text(letter)
            .font(.system(size: 26, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color)
            )
            .shadow(color: color.opacity(0.35), radius: 10, x: 0, y: 6)
            .offset(y: isAnimating ? -6 : 6)
            .animation(
                .easeInOut(duration: 0.9)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
    }
}

#Preview {
    NurseryLaunchView()
}
