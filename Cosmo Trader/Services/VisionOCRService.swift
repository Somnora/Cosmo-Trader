import Foundation
import Vision
import UIKit

// MARK: - VisionOCRService
// ========================
// Runs Vision framework OCR on a brokerage screenshot and returns the raw
// recognized text. Structured holdings parsing lives in the registered
// BrokerScreenshotParser implementations (see PortfolioImportService); this
// service only turns pixels into text.

// MARK: - OCR Error

enum VisionOCRError: Error, LocalizedError {
    case imageConversionFailed
    case noTextFound
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to process the image"
        case .noTextFound:
            return "No text could be detected in the image"
        case .processingFailed(let details):
            return "OCR processing failed: \(details)"
        }
    }
}

// MARK: - Service

final class VisionOCRService {

    // MARK: - Singleton

    static let shared = VisionOCRService()

    private init() {}

    // MARK: - Text Recognition

    /// Recognize all text in a screenshot, returned newline-joined in reading order.
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw VisionOCRError.imageConversionFailed
        }

        let recognizedText = try await performOCR(on: cgImage)

        guard !recognizedText.isEmpty else {
            throw VisionOCRError.noTextFound
        }

        return recognizedText
    }

    // MARK: - Vision OCR

    private func performOCR(on cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: VisionOCRError.processingFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                // Combine all recognized text in reading order.
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }

            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            // Perform request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VisionOCRError.processingFailed(error.localizedDescription))
            }
        }
    }
}
