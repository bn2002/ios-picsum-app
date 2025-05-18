//
//  PhotoListViewController.swift
//  PicsumApp
//
//  Created by Nguyễn Duy Doanh on 17/5/25.
//

import UIKit

final class PhotoListViewController: UIViewController {
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PhotoTableViewCell.self, forCellReuseIdentifier: PhotoTableViewCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search by author or id"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    private var viewModel: PhotoListViewModel
    private var isLoadingMore = false
    private var imageLoadTasks: ThreadSafeDictionary<IndexPath, String> = ThreadSafeDictionary()
    private var loadingCells: Set<IndexPath> = []
    private var didPreloadInitialImages = false
    private var scrollTimer: Timer?
    private let scrollStopDelay: TimeInterval = 0.1
    
    // MARK: - Initialization
    init(viewModel: PhotoListViewModel) {
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
        self.view.addSubview(self.searchBar)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.loadingIndicator)
        
        self.tableView.refreshControl = self.refreshControl
        self.refreshControl.addTarget(self, action: #selector(self.handleRefresh), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            self.searchBar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.searchBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.searchBar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            self.tableView.topAnchor.constraint(equalTo: self.searchBar.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            self.loadingIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.loadingIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        self.viewModel.photos.observe(on: self) { [weak self] photos in
            guard let `self` = self else { return }
            self.tableView.reloadData()
            
            // Call only once when photos are loaded(initial images)
            if !self.didPreloadInitialImages && !photos.isEmpty {
                DispatchQueue.main.async {
                    self.didPreloadInitialImages = true
                    self.preloadImagesForVisibleCells()
                }
            }
        }
        
        self.viewModel.error.observe(on: self) { [weak self] error in
            if let error = error {
                self?.showError(error)
            }
        }
        
        self.viewModel.isLoading.observe(on: self) { [weak self] isLoading in
            guard let `self` = self else { return }
            if isLoading {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                self.isLoadingMore = false
            }
        }
    }
    
    private func preloadImagesForVisibleCells() {
        // If no visible cells, load first few items
        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows, !visibleIndexPaths.isEmpty else {
            let initialIndexPaths = (0..<min(3, self.viewModel.photos.value.count)).map { IndexPath(row: $0, section: 0) }
            self.loadImages(for: initialIndexPaths)
            return
        }
        
        self.loadImages(for: visibleIndexPaths)
    }
    
    private func loadImages(for indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.row < self.viewModel.photos.value.count else { continue }
            let photo = self.viewModel.photos.value[indexPath.row]
                        
            // Mark cell as loading
            self.loadingCells.insert(indexPath)
            let taskId = ImageLoader.shared.loadImage(from: photo.optimizedImageURL) { [weak self] image in
                guard let `self` = self else { return }
                self.loadingCells.remove(indexPath)
                if let image = image {
                   if let cell = self.tableView.cellForRow(at: indexPath) as? PhotoTableViewCell {
                       cell.configure(with: photo)
                       cell.setImage(data: image)
                   }
               } else if let cell = self.tableView.cellForRow(at: indexPath) as? PhotoTableViewCell {
                   // If load failed, reset cell state
                   cell.configure(with: photo)
               }
                self.imageLoadTasks.removeValue(forKey: indexPath)
            }
            
            if let preTaskId = self.imageLoadTasks[indexPath] {
                ImageLoader.shared.cancelTask(with: preTaskId)
            }
            self.imageLoadTasks[indexPath] = taskId
        }
    }
    
    // MARK: - Actions
    @objc private func handleRefresh() {
        self.viewModel.refresh()
    }
    
    // MARK: - Helper Methods
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension PhotoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.photos.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: PhotoTableViewCell.reuseIdentifier, for: indexPath) as? PhotoTableViewCell
        else {
            return UITableViewCell()
        }
        
        let photo = self.viewModel.photos.value[indexPath.row]
        cell.configure(with: photo)
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension PhotoListViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        if offsetY > contentHeight - height * 2 {
            guard !self.viewModel.isLoading.value, !self.isLoadingMore else { return }
            self.isLoadingMore = true
            self.viewModel.loadMore()
        }
    }
}

// MARK: - UISearchBarDelegate
extension PhotoListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.viewModel.search(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UIScrollViewDelegate
extension PhotoListViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.imageLoadTasks.values.forEach { taskId in
            ImageLoader.shared.cancelTask(with: taskId)
        }
        self.imageLoadTasks.removeAll()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.handleScrollStopped()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.handleScrollStopped()
        }
    }
    
    private func handleScrollStopped() {
        self.scrollTimer?.invalidate()
        self.scrollTimer = Timer.scheduledTimer(withTimeInterval: scrollStopDelay, repeats: false) { [weak self] _ in
           self?.loadVisibleImages()
        }
    }
    
    private func loadVisibleImages() {
        // Load image for visible cell
        let visibleIndexPaths = tableView.indexPathsForVisibleRows ?? []
        self.loadImages(for: visibleIndexPaths)
        
        // After load for visible cell, prefetch next image
        let nextIndexPaths = calculateNextIndexPathsToPrefetch(after: visibleIndexPaths)
        self.loadImages(for: nextIndexPaths)
    }
    
    private func calculateNextIndexPathsToPrefetch(after visibleIndexPaths: [IndexPath]) -> [IndexPath] {
        guard let lastVisible = visibleIndexPaths.last?.item else { return [] }

        let nextItems = (1...5) // Prefetch 5 next item
           .map { lastVisible + $0 }
           .filter { $0 < self.viewModel.photos.value.count }
           .map { IndexPath(item: $0, section: 0) }

        return nextItems
    }
}
