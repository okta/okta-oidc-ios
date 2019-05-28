@testable import OktaOidc

class OktaOidcApiMock: OktaOidcHttpApiProtocol {
    
    var lastRequest: URLRequest?
    
    var requestHandler: ((URLRequest, OktaOidcApiMock.OktaApiSuccessCallback, OktaOidcApiMock.OktaApiErrorCallback) -> Void)?
    
    func fireRequest(_ request: URLRequest,
                     onSuccess: @escaping OktaOidcApiMock.OktaApiSuccessCallback,
                     onError: @escaping OktaOidcApiMock.OktaApiErrorCallback) {
        lastRequest = request
        
        DispatchQueue.main.async { [weak self] in
            self?.requestHandler?(request, onSuccess, onError)
        }
    }
    
    func configure(error: OktaOidcError, requestValidationBlock: ((URLRequest) -> Void)? = nil) {
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
