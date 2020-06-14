import Foundation
import RxSwift
import TSCBasic
import TuistCore
import TuistSupport
import Zip

// TODO: Later, add a warmup function to check if it's correctly authenticated ONCE
final class CacheRemoteStorage: CacheStoring {
    // MARK: - Attributes

    private let cloudClient: CloudClienting
    private let fileUploader: FileUploader

    // MARK: - Init

    init(cloudClient: CloudClienting, fileUploader: FileUploader = FileUploader()) {
        self.cloudClient = cloudClient
        self.fileUploader = fileUploader
    }

    // MARK: - CacheStoring

    func exists(hash: String, config: Config) -> Single<Bool> {
        do {
            let successRange = 200 ..< 300
            let resource = try CloudHEADResponse.existsResource(hash: hash, config: config)
            return cloudClient.request(resource)
                .flatMap { _, response in
                    .just(successRange.contains(response.statusCode))
                }
                .catchError { error in
                    if case let HTTPRequestDispatcherError.serverSideError(_, response) = error, response.statusCode == 404 {
                        return .just(false)
                    } else {
                        throw error
                    }
                }
        } catch {
            return Single.error(error)
        }
    }

    func fetch(hash: String, config: Config) -> Single<AbsolutePath> {
        do {
            let resource = try CloudCacheResponse.fetchResource(hash: hash, config: config)
            return cloudClient.request(resource).map { _ in
                AbsolutePath.root // TODO:
            }
        } catch {
            return Single.error(error)
        }
    }

    func store(hash: String, config: Config, xcframeworkPath: AbsolutePath) -> Completable {
        do {
            let destinationZipPath = try zip(xcframeworkPath: xcframeworkPath, hash: hash)
            let resource = try CloudCacheResponse.storeResource(
                hash: hash,
                config: config,
                content_md5: try destinationZipPath.md5()
            )
            
            return cloudClient.request(resource).map { responseTuple in
                let cacheResponse = responseTuple.object.data
                let artefactToUploadURL = cacheResponse.url
                print(artefactToUploadURL)
                print("---")
                print(xcframeworkPath.pathString)

                var urlRequest = URLRequest(url: artefactToUploadURL)
                urlRequest.httpMethod = "POST"
                let result = try self.fileUploader.upload(file: destinationZipPath, with: urlRequest).map { obj, response in
                    print("String: \(obj)")
                    print("response: \(response)")
                }.toBlocking().last()
                print(result)
                // TODO: Download file at given url
            }.asCompletable()
        } catch {
            return Completable.error(error)
        }
    }

    private func zip(xcframeworkPath: AbsolutePath, hash: String) throws -> AbsolutePath {
        print("xcframeworkPath: \(xcframeworkPath)")
        let destinationZipPath = xcframeworkPath.removingLastComponent().appending(component: "\(hash).zip")
        print("destinationZipPath: \(destinationZipPath)")
        try Zip.zipFiles(paths: [xcframeworkPath.url], zipFilePath: destinationZipPath.url, password: nil, progress: nil)
        return destinationZipPath
    }
}
