import Foundation

struct GradiumTTSRequest: Codable {
    let text: String
    let voice_id: String
    let output_format: String
    let model_name: String
    let only_audio: Bool
}

class GradiumService {
    static let shared = GradiumService()
    
    let apiKey = "placeholder"
    let endpoint = "https://api.gradium.ai/api/post/speech/tts"
    
    func generateSpeech(text: String) async throws -> Data {
        let requestBody = GradiumTTSRequest(
            text: text,
            voice_id: "YTpq7expH9539ERJ",
            output_format: "wav",
            model_name: "default",
            only_audio: true
        )
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GradiumService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GradiumService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        return data
    }
}
