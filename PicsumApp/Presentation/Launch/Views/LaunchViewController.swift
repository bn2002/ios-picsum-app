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
        self.setupViews()
        self.setupBindings()
        self.viewModel.viewDidLoad()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.containerView)
        self.containerView.addSubview(self.logoImageView)
        self.containerView.addSubview(self.progressView)
        self.containerView.addSubview(self.statusLabel)
        self.containerView.addSubview(self.retryButton)
        
        NSLayoutConstraint.activate([
            self.containerView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.containerView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.containerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 32),
            self.containerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -32),
            
            self.logoImageView.topAnchor.constraint(equalTo: self.containerView.topAnchor),
            self.logoImageView.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor),
            self.logoImageView.widthAnchor.constraint(equalToConstant: 120),
            self.logoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            self.progressView.topAnchor.constraint(equalTo: self.logoImageView.bottomAnchor, constant: 32),
            self.progressView.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
            self.progressView.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor),
            
            self.statusLabel.topAnchor.constraint(equalTo: self.progressView.bottomAnchor, constant: 16),
            self.statusLabel.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor),
            self.statusLabel.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor),
            
            self.retryButton.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 16),
            self.retryButton.centerXAnchor.constraint(equalTo: self.containerView.centerXAnchor),
            self.retryButton.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor)
        ])
        
        self.retryButton.addTarget(self, action: #selector(self.retryTapped), for: .touchUpInside)
    }
    
    private func setupBindings() {
        self.viewModel.state.observe(on: self) { [weak self] state in
            self?.handleState(state)
        }
    }
    
    private func handleState(_ state: LaunchState) {
        switch state {
        case .initial:
            self.progressView.progress = 0
            self.statusLabel.text = "Preparing..."
            self.retryButton.isHidden = true
            
        case .loading(let progress):
            self.progressView.progress = progress
            self.statusLabel.text = "Loading... \(Int(progress * 100))%"
            self.retryButton.isHidden = true
            
        case .error(let error):
            self.statusLabel.text = "Error: \(error.localizedDescription)"
            self.retryButton.isHidden = false
            
        case .completed:
            self.navigateToMain()
        }
    }
    
    private func navigateToMain() {
        // Transition to main screen
        let mainVC = DIContainer.shared.makePhotoListViewController()
        // Set as root view controller with fade transition
        UIView.transition(with: UIApplication.shared.windows.first!,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            UIApplication.shared.windows.first?.rootViewController = mainVC
        })
    }
    
    // MARK: - Actions
    
    @objc private func retryTapped() {
        viewModel.retry()
    }
}
