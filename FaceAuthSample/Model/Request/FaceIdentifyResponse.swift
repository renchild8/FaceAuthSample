struct FaceIdentifyResponse: Codable {
    let faceId: String
    let candidates: [Candidates]
}

struct Candidates: Codable {
    let personId: String
    let confidence: Double
}
