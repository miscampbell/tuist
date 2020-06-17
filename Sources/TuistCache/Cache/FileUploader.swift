import Foundation
import RxSwift
import TSCBasic
import TuistCore
import TuistSupport
import Alamofire

public class FileUploader {
    // MARK: - Attributes
    
    let requestDispatcher: HTTPRequestDispatching
    let multipartFormData: MultipartFormData
    let session: URLSession
    
    // MARK: - Init
    
    public init(requestDispatcher: HTTPRequestDispatching = HTTPRequestDispatcher(),
                multipartFormData: MultipartFormData = MultipartFormData(),
                session: URLSession = URLSession.shared
    ) {
        self.requestDispatcher = requestDispatcher
        self.multipartFormData = multipartFormData
        self.session = session
    }
    
    // MARK: - Public
    
    public func upload(file: AbsolutePath, hash: String, to url: URL) -> Single<String> {
        return Single<String>.create { obs -> Disposable in
            
            let attr = try! FileManager.default.attributesOfItem(atPath: file.pathString)
            let fileSize: UInt64 = attr[FileAttributeKey.size] as! UInt64
            
            do {
                let data = try Data(contentsOf: file.url)
                
                let request = self.uploadRequest(url: url, fileSize: fileSize, data: data)
                let uploadTask = self.session.dataTask(with: request) { data, response, error in
                    print(response)
                    print("data: " + (String(data: data!, encoding: .utf8) ?? ""))
                    obs(.success(response.debugDescription))
                }
                uploadTask.resume()
                return Disposables.create {
                    uploadTask.cancel()
                }
            } catch {
                obs(.error(error))
            }
            return Disposables.create {}
        }
    }
    
    // MARK: - Private

    private func uploadRequest(url: URL, fileSize: UInt64, data: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/zip", forHTTPHeaderField: "Content-Type")
        request.setValue(String(fileSize), forHTTPHeaderField: "Content-Length")
        request.setValue("zip", forHTTPHeaderField: "Content-Encoding")
        request.httpBody = data
        return request
    }
}
