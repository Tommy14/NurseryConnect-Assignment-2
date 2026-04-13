//
//  IncidentWorkflowTimelineView.swift
//  NurseryConnect
//
//  Feature: Incident Reporting
//  Role: Keyworker
//  Created: 12 April 2026
//  Description: Full-width vertical workflow timeline (no horizontal scrolling).
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 120426     Tommy1914   Gradient rail, step nodes, and progress capsule.
// -----------------------------------------------------------------

import SwiftUI

/// - Description: Incident stages in a single column so every label stays visible on narrow phones.
struct IncidentWorkflowTimelineView: View {
    let currentStatus: IncidentStatus

    private var steps: [IncidentStatus] { IncidentStatus.allCases }

    private var currentIndex: Int { currentStatus.stepIndex }

    private let connectorHeight: CGFloat = 14
    private let nodeSize: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    stepRow(index: index, step: step)
                }
            }
        }
        .padding(16)
        .background { timelineCardBackground }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "point.topleft.filled.down.to.point.bottomright.curvepath.fill")
                .font(.title2)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.ncPrimary, Color.cyan.opacity(0.75))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Workflow")
                    .font(AppTheme.titleRounded())
                Text("Incident journey")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text("\(currentIndex + 1) / \(steps.count)")
                .font(.caption.weight(.bold).monospacedDigit())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.ncPrimary.opacity(0.14))
                )
                .foregroundStyle(Color.ncPrimary)
        }
        .padding(.bottom, 14)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func stepRow(index: Int, step: IncidentStatus) -> some View {
        let isLast = index == steps.count - 1
        let isDone = step.stepIndex < currentIndex
        let isCurrent = step.stepIndex == currentIndex

        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                if index == 0 {
                    Color.clear.frame(height: 4)
                } else {
                    connectorLine(active: currentIndex >= index)
                        .frame(height: connectorHeight)
                }
                stepNode(step: step, isDone: isDone, isCurrent: isCurrent)
                if !isLast {
                    connectorLine(active: currentIndex > index)
                        .frame(height: connectorHeight)
                }
            }
            .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline.weight(isCurrent ? .semibold : .medium))
                    .foregroundStyle(isDone || isCurrent ? Color.primary : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if isCurrent {
                    Text("Current stage")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ncPrimary, Color.cyan.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                } else if isDone {
                    Text("Done")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Pending")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, isLast ? 2 : 12)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func stepNode(step: IncidentStatus, isDone: Bool, isCurrent: Bool) -> some View {
        ZStack {
            if isDone {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ncPrimary, Color.cyan.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: nodeSize, height: nodeSize)
                    .shadow(color: Color.ncPrimary.opacity(0.35), radius: 4, x: 0, y: 2)
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            } else if isCurrent {
                Circle()
                    .fill(Color.ncCardSurface)
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.ncPrimary, Color.cyan.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    }
                    .shadow(color: Color.ncPrimary.opacity(0.45), radius: 8, x: 0, y: 0)
                Image(systemName: step.workflowSymbolName)
                    .font(.caption)
                    .foregroundStyle(Color.ncPrimary)
                    .symbolRenderingMode(.hierarchical)
            } else {
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.5)
                    .background(Circle().fill(Color.ncCardSurface.opacity(0.6)))
                    .frame(width: nodeSize, height: nodeSize)
                Image(systemName: step.workflowSymbolName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .frame(width: nodeSize, height: nodeSize)
        .accessibilityLabel(accessibilityLabel(for: step, isDone: isDone, isCurrent: isCurrent))
    }

    private func connectorLine(active: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(
                active
                    ? LinearGradient(
                        colors: [Color.ncPrimary.opacity(0.95), Color.cyan.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [Color.secondary.opacity(0.22), Color.secondary.opacity(0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
            )
            .frame(width: 4)
    }

    private var timelineCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.ncCardSurface)
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 6)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.ncPrimary.opacity(0.35),
                                Color.cyan.opacity(0.2),
                                Color.ncPrimary.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }

    private func accessibilityLabel(for step: IncidentStatus, isDone: Bool, isCurrent: Bool) -> String {
        if isDone { return "\(step.title), completed" }
        if isCurrent { return "\(step.title), current stage" }
        return "\(step.title), pending"
    }
}

#Preview {
    IncidentWorkflowTimelineView(currentStatus: .managerReviewed)
        .padding()
        .background(Color.ncBackground)
}
