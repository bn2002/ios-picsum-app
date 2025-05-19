//
//  LaunchViewModel.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import Foundation

enum LaunchState {
    case initial
    case loading(progress: Float)
    case error(Error)
    case completed
}

final class LaunchViewModel {
    private let initializeUseCase: InitializePhotosUseCaseProtocol
    
    let state: Observable<LaunchState> = Observable(.initial)
        
    init(initializeUseCase: InitializePhotosUseCaseProtocol) {
        self.initializeUseCase = initializeUseCase
    }
    
    func startInitialization(force: Bool = false) {
        state.value = .loading(progress: 0)
        
        initializeUseCase.execute(
            force: force,
            progress: { [weak self] progress in
                print("Progress: \(progress)")
                self?.state.value = .loading(progress: progress)
            },
            completion: { [weak self] result in
                switch result {
                case .success:
                    self?.state.value = .completed
                case .failure(let error):
                    self?.state.value = .error(error)
                }
            }
        )
    }
    
    func retry() {
       startInitialization(force: true)
    }

    func cancel() {
       initializeUseCase.cancel()
    }

    deinit {
       cancel()
    }
}
