//
//  DIContainer.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import Foundation

final class DIContainer {
    // MARK: - Shared Instance
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - Network
    lazy var networkService: NetworkService = {
        return NetworkService()
    }()
    
    // MARK: - Repositories
    lazy var photoRepository: PhotoRepositoryProtocol = {
        return APIPhotoRepository(network: networkService)
    }()
    
    lazy var coreDataRepository: PhotoStorageRepositoryProtocol = {
        return CoreDataPhotoStorageRepository(coreDataStack: coreDataStack)
    }()
    
    // MARK: - Use Cases
    lazy var fetchPhotosUseCase: FetchPhotosUseCaseProtocol = {
        return FetchPhotosUseCase(repository: photoRepository, storageRepository: coreDataRepository)
    }()
    
    lazy var searchPhotosUseCase: SearchPhotosUseCaseProtocol = {
        return SearchPhotosUseCase(storageRepository: coreDataRepository)
    }()
    
    lazy var coreDataStack: CoreDataStack = {
        return CoreDataStack()
    }()
    
    // MARK: - ViewModels
    func makePhotoListViewModel() -> PhotoListViewModel {
        return DefaultPhotoListViewModel(
            fetchPhotosUseCase: fetchPhotosUseCase,
            searchPhotosUseCase: searchPhotosUseCase
        )
    }
    
    // MARK: - View Controllers
    func makePhotoListViewController() -> PhotoListViewController {
        let viewModel = makePhotoListViewModel()
        return PhotoListViewController(viewModel: viewModel)
    }
    
    func makeLaunchViewController() -> LaunchViewController {
            return LaunchViewController(viewModel: makeLaunchViewModel())
    }
    
    func makeLaunchViewModel() -> LaunchViewModel {
            return LaunchViewModel(initializeUseCase: makeInitializePhotosUseCase())
    }
    
    func makePhotoStorageRepository() -> PhotoStorageRepositoryProtocol {
        return CoreDataPhotoStorageRepository(coreDataStack: coreDataStack)
    }
        
    func makeInitializePhotosUseCase() -> InitializePhotosUseCaseProtocol {
        return InitializePhotosUseCase(
            photoRepository: photoRepository,
            storageRepository: makePhotoStorageRepository()
        )
    }
}
