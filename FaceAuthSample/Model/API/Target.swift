import Moya

enum Target {
    case detect(imageData: Data)
    case identify(faceId: String)
}

extension Target: TargetType {

    var baseURL: URL {
        return URL(string: Const.baseURL)!
    }

    var path: String {
        switch self {
        case .detect:
            return "detect/"
        case .identify:
            return "identify/"
        }
    }

    var method: Moya.Method {
        switch self {
        case .detect:
            return .post
        case .identify:
            return .post
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch self {
        case .detect(let imageData):

            return .requestCompositeData(bodyData: imageData, urlParameters: ["recognitionModel" : "recognition_02"])

        case .identify(let faceId):
            let parameters: [String: Any] = [
                "personGroupId": Const.personGroupId,
                "faceIds": [faceId]
            ]

            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)

        }

    }

    var headers: [String: String]? {
        var header = [
            "Ocp-Apim-Subscription-Key" : Const.subscriptionKey
        ]

        switch self {
        case .detect:
            header["Content-Type"] = "application/octet-stream"
            return header
        case .identify:
            header["Content-Type"] = "application/json"
            return header
        }
    }

}
