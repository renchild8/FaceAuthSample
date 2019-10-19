struct ErrorResponse: Codable {
    public let error: ErrorStatus
}

struct ErrorStatus: Codable {
    let code: String
    let message: String
}
