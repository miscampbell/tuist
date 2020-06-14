import Foundation
import RxSwift
import TSCBasic
import TuistCore
import TuistSupport

public class FileUploader {
    // MARK: - Attributes

    let requestDispatcher: HTTPRequestDispatching

    // MARK: - Init

    public init(requestDispatcher: HTTPRequestDispatching = HTTPRequestDispatcher()) {
        self.requestDispatcher = requestDispatcher
    }

    // MARK: - Public

//    public func upload(file: AbsolutePath, with request: URLRequest) -> Single<(object: String, response: HTTPURLResponse)> {
//        Single<(URL, URLRequest)>.create { (observer) -> Disposable in
//            do {
////                var request = request
////                try request.setMultipartFormData(
////                    ["key": file.basename, "file": "file"],
////                    encoding: .utf8
////                )
//                observer(.success((file.url, request)))
//            } catch {
//                observer(.error(error))
//            }
//            return Disposables.create()
//        }.flatMap(requestDispatcher.upload)
//    }
    
        public func upload(file: AbsolutePath, with request: URLRequest) -> Single<(object: String, response: HTTPURLResponse)> {
            requestDispatcher.upload(fileURL: file.url, with: request)
        }
    
}
