import SwiftUI

@MainActor @Observable class RequestViewModel {
    private let apiKey = Secrets.apiKey
    
    var selectedType: RequestType = .health
    var responseText: String = ""
    var isLoading: Bool = false
    
    func sendRequest() async {
        isLoading = true
        responseText = ""
        
        do {
        
            guard let url = URL(string: selectedType.url) else {
                responseText = "Ошибка: Неверный URL"
                isLoading = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = selectedType.httpMethod

            
            if selectedType != .health {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            if selectedType == .echo {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body: [String: String] = ["Hello" : "world!"]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
                    
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "Пусто"
            
            responseText = "Статус: \(statusCode)\n\nОтвет:\n\(body)"
        } catch {
            responseText = "Ошибка: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
