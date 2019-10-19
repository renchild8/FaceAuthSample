struct FaceDetectResponse: Codable {
    let faceId: String
    let faceRectangle: FaceRectangle
}

struct FaceRectangle: Codable {
    let top: Int
    let left: Int
    let width: Int
    let height: Int
}
