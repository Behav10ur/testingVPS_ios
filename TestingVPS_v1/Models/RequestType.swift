import Foundation

enum RequestType: String, CaseIterable, Identifiable {
    case health
    case echo
    case testError
    case testDelay
    
    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .health: return "Health check"
        case .echo: return "Echo POST"
        case .testError: return "Error 500"
        case .testDelay: return "Delay 3s"
        }
    }
    var url: String {
        switch self {
        case .health: return Secrets.baseURL + "health"
        case .echo: return Secrets.baseURL + "/api/v1/echo"
        case .testError: return Secrets.baseURL + "/api/v1/test-error/500"
        case .testDelay: return Secrets.baseURL + "/api/v1/test-delay/3"
        }
    }
    var httpMethod: String {
        switch self {
        case .health, .testError, .testDelay: return "GET"
        case .echo: return "POST"
        }
    }
}
