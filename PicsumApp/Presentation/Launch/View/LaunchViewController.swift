//
//  LaunchViewController.swift
//  PicsumApp
//
//  Created by Doanh on 19/5/25.
//
import UIKit

final class LaunchViewController: UIViewController {
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "launch_logo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    private let viewModel: LaunchViewModel
    
    // MARK: - Initialization
    
    init(viewModel: LaunchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.startInitialization()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(containerView)
        containerView.addSubview(logoImageView)
        containerView.addSubview(progressView)
        containerView.addSubview(statusLabel)
        containerView.addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            logoImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            logoImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            progressView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 32),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            retryButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            retryButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            retryButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        viewModel.state.observe(on: self) { [weak self] state in
            self?.handleState(state)
        }
    }
    
    private func handleState(_ state: LaunchState) {
        switch state {
        case .initial:
            progressView.progress = 0
            statusLabel.text = "Preparing..."
            retryButton.isHidden = true
            
        case .loading(let progress):
            progressView.progress = progress
            statusLabel.text = "Loading... \(Int(progress * 100))%"
            retryButton.isHidden = true
            
        case .error(let error):
            statusLabel.text = "Error: \(error.localizedDescription)"
            retryButton.isHidden = false
            
        case .completed:
            navigateToMain()
        }
    }
    
    private func navigateToMain() {
        // Transition to main screen
        let mainVC = PhotoListViewController(viewModel: DIContainer.shared.makePhotoListViewModel())
        let navController = UINavigationController(rootViewController: mainVC)
        
        // Set as root view controller with fade transition
        UIView.transition(with: UIApplication.shared.windows.first!,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            UIApplication.shared.windows.first?.rootViewController = navController
        })
    }
    
    // MARK: - Actions
    
    @objc private func retryTapped() {
        viewModel.retry()
    }
}
