@testable import OktaAuth

class OktaApiMock: OktaApi {
    
    var lastRequest: URLRequest?
    
    var requestHandler: ((URLRequest, OktaApiMock.OktaApiSuccessCallback, OktaApiMock.OktaApiErrorCallback) -> Void)?
    
    func installMock() {
        OktaAuth.authApi = self
    }
    
    static func resetMock() {
        OktaAuth.authApi = OktaApiImpl()
    }
    
    func fireRequest(_ request: URLRequest,
                     onSuccess: @escaping OktaApiMock.OktaApiSuccessCallback,
                     onError: @escaping OktaApiMock.OktaApiErrorCallback) {
        lastRequest = request
        
        DispatchQueue.main.async { [weak self] in
            self?.requestHandler?(request, onSuccess, onError)
        }
    }
    
    func configure(error: OktaError, requestValidationBlock: ((URLRequest) -> Void)? = nil) {
        requestHandler = { request, onSuccess, onError in
            requestValidationBlock?(request)
            onError(error)
        }
    }
    
     func configure(response: [String:Any]?, requestValidationBlock: ((URLRequest) -> Void)? = nil) {
        requestHandler = { request, onSuccess, onError in
            requestValidationBlock?(request)
            onSuccess(response)
        }
    }
}
