//
//  ActivityShare.swift
//  NurseryConnect
//
//  Feature: Shared UI
//  Role: Keyworker
//  Created: 8 April 2026
//  Description: UIKit bridge for sharing exported PDFs via the system share sheet.
//
// -----------------------------------------------------------------
// Date       Name        What has done
// -----------------------------------------------------------------
// 080426     Tommy1914   Created the file with UIActivityViewController wrapper.
// -----------------------------------------------------------------

import SwiftUI
import UIKit

/// - Description: Presents `UIActivityViewController` from SwiftUI for document export.
struct ActivityShareView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
