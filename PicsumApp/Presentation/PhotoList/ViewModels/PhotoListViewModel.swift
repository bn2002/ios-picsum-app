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
    var currentPage: Int { get }
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
    private(set) var currentPage = 1
    private let itemsPerPage = 100
    private var allPhotos: [Photo] = []
    private var isSearchActive = false
    private var lastSearchQuery: String = ""
    private var searchResults: [Photo] = []
    
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
        if self.isSearchActive {
            self.search(query: self.lastSearchQuery)
        } else {
            self.loadPhotos()
        }
    }
    
    func refresh() {
        self.currentPage = 1
        if self.isSearchActive {
            self.searchResults.removeAll()
            self.search(query: lastSearchQuery)
        } else {
            self.allPhotos.removeAll()
            self.loadPhotos()
        }
    }
    
    func search(query: String) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Reset search state if query is empty
        if query.isEmpty && self.isSearchActive {
            self.currentPage = 1
            self.isSearchActive = false
            self.lastSearchQuery = ""
            self.photos.value = allPhotos
            return
        }
        
        // Reset page and results if query changed
        if query != self.lastSearchQuery {
            self.currentPage = 1
            self.searchResults.removeAll()
        }
        
        // Nếu query không thay đổi -> không cần search lại
        if query == self.lastSearchQuery && !self.searchResults.isEmpty {
            return
        }
        
        self.isSearchActive = true
        self.lastSearchQuery = query
        self.isLoading.value = true
        
        self.searchPhotosUseCase.execute(
            query: query,
            page: self.currentPage,
            limit: self.itemsPerPage
        ) { [weak self] results in
            DispatchQueue.main.async {
                guard
                    let `self` = self,
                    self.isSearchActive,
                    query == self.lastSearchQuery
                else {
                    return
                }
                
                self.isLoading.value = false
                
                if self.currentPage == 1 {
                    self.searchResults = results
                } else {
                    self.searchResults.append(contentsOf: results)
                }
                
                self.photos.value = self.searchResults
                self.error.value = nil
            }
        }
    }
    
    // MARK: - Private Methods
    private func loadPhotos() {
        self.isLoading.value = true
        
        fetchPhotosUseCase.execute(
           page: currentPage,
           limit: itemsPerPage
        ) { [weak self] result in
                   guard let `self` = self else { return }
                   
                   switch result {
                   case .success(let newPhotos):
                       self.handlePhotosResult(.success(newPhotos))
                       
                   case .failure(let error):
                       self.handlePhotosResult(.failure(error))
                   }
            }
    }
    
    private func handlePhotosResult(_ result: Result<[Photo], Error>) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            
            self.isLoading.value = false
            
            switch result {
            case .success(let newPhotos):
                if newPhotos.isEmpty {
                    self.currentPage = max(1, self.currentPage - 1)
                    self.error.value = nil
                    return
                }
                
                if self.currentPage == 1 {
                    self.allPhotos = newPhotos
                } else {
                    self.allPhotos.append(contentsOf: newPhotos)
                }
                
                self.photos.value = self.allPhotos
                self.error.value = nil
                
            case .failure(let error):
                self.error.value = error
            }
        }
    }
}
