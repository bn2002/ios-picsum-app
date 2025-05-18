//
//  PhotoListViewModel.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//
import Foundation
import UIKit

protocol PhotoListViewModelInput {
    func viewDidLoad()
    func loadMore()
    func refresh()
    func search(query: String)
}

protocol PhotoListViewModelOutput {
    var photos: Observable<[Photo]> { get }
    var isLoading: Observable<Bool> { get }
    var error: Observable<Error?> { get }
}

protocol PhotoListViewModel: PhotoListViewModelInput, PhotoListViewModelOutput {}

final class DefaultPhotoListViewModel: PhotoListViewModel {
    // MARK: - Output
    let photos: Observable<[Photo]> = Observable([])
    let isLoading: Observable<Bool> = Observable(false)
    let error: Observable<Error?> = Observable(nil)
    
    // MARK: - Private Properties
    private let fetchPhotosUseCase: FetchPhotosUseCaseProtocol
    private let searchPhotosUseCase: SearchPhotosUseCaseProtocol
    private var currentPage = 1
    private let itemsPerPage = 100
    private var allPhotos: [Photo] = []
    private var currentTask: URLSessionDataTask?
    
    // MARK: - Init
    init(fetchPhotosUseCase: FetchPhotosUseCaseProtocol,
         searchPhotosUseCase: SearchPhotosUseCaseProtocol) {
        self.fetchPhotosUseCase = fetchPhotosUseCase
        self.searchPhotosUseCase = searchPhotosUseCase
    }
    
    // MARK: - Input
    func viewDidLoad() {
        self.loadPhotos()
    }
    
    func loadMore() {
        guard !self.isLoading.value else { return }
        self.currentPage += 1
        self.loadPhotos()
    }
    
    func refresh() {
        self.currentPage = 1
        self.allPhotos.removeAll()
        self.loadPhotos()
    }
    
    func search(query: String) {
       
    }
    
    // MARK: - Private Methods
    private func loadPhotos() {
        self.isLoading.value = true
        
        self.currentTask?.cancel()
        
        self.currentTask = fetchPhotosUseCase.execute(
            page: currentPage,
            limit: itemsPerPage
        ) { [weak self] (result: Result<[Photo], Error>) in
            guard let `self` = self else { return }
            self.handlePhotosResult(result)
        }
    }
    
    private func handlePhotosResult(_ result: Result<[Photo], Error>) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            self.isLoading.value = false
            
            switch result {
            case .success(let newPhotos):
                if newPhotos.count > 0 {
                    if self.currentPage == 1 {
                        self.allPhotos = newPhotos
                    } else {
                        self.allPhotos.append(contentsOf: newPhotos)
                    }
                    
                    self.photos.value = self.allPhotos
                }
                self.error.value = nil
                
            case .failure(let error):
                self.error.value = error
            }
        }
    }
}
