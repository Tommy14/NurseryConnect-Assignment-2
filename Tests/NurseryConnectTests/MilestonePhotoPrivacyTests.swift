//
//  MilestonePhotoPrivacyTests.swift
//  NurseryConnectTests
//

import CoreData
import UIKit
import XCTest
@testable import NurseryConnect

@MainActor
final class MilestonePhotoPrivacyTests: XCTestCase {
    func testMilestoneCaptureAllowedOnlyWhenConsentAndMilestoneType() {
        XCTAssertTrue(AddDiaryEntryView.isMilestonePhotoCaptureAllowed(hasPhotoConsent: true, entryType: .milestone))
        XCTAssertFalse(AddDiaryEntryView.isMilestonePhotoCaptureAllowed(hasPhotoConsent: false, entryType: .milestone))
        XCTAssertFalse(AddDiaryEntryView.isMilestonePhotoCaptureAllowed(hasPhotoConsent: true, entryType: .activity))
    }

    func testApplyDraftPersistsMilestonePhotoFields() {
        let stack = PersistenceController(inMemory: true)
        let context = stack.container.viewContext
        let entry = DiaryEntry(context: context)
        let photoData = makeSolidColorImageData()

        let draft = DiaryEntryDraftValues(
            timestamp: Date(),
            entryType: .milestone,
            notes: "Captured milestone",
            activityType: "Built first tower",
            eyfsArea: EyfsArea.expressiveArts.rawValue,
            duration: 15,
            mealDescription: "",
            mealConsumed: nil,
            fluidIntake: 0,
            fluidType: "",
            nappyType: "",
            moodRating: 0,
            sleepPosition: "",
            milestonePhotoData: photoData,
            milestonePhotoMimeType: "image/jpeg",
            milestonePhotoBlurredFaceCount: 2
        )

        entry.applyDraft(draft)

        XCTAssertEqual(entry.milestonePhotoData, photoData)
        XCTAssertEqual(entry.milestonePhotoMimeType, "image/jpeg")
        XCTAssertEqual(entry.milestonePhotoBlurredFaceCount, 2)
    }

    func testFaceBlurProcessorReturnsImageWhenNoFacesSelected() {
        let image = makeSolidColorImage()
        let output = FaceBlurProcessor.applyBlur(to: image, faceBoxes: [], selectedIndexes: [])
        XCTAssertNotNil(output)
    }

    private func makeSolidColorImageData() -> Data {
        makeSolidColorImage().jpegData(compressionQuality: 0.9) ?? Data()
    }

    private func makeSolidColorImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80))
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
        }
    }
}
