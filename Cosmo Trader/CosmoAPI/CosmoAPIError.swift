import Foundation

enum CosmoAPIError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case decoding(Error)
    case unauthorized(message: String?)
    case server(statusCode: Int, message: String?)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .transport(let error):
            return error.localizedDescription
        case .decoding(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized(let message):
            return message ?? "Unauthorized."
        case .server(let statusCode, let message):
            return message ?? "Server error with status code \(statusCode)."
        case .emptyResponse:
            return "Empty response."
        }
    }
}
