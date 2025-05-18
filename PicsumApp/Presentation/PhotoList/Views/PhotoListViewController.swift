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
        tableView.prefetchDataSource = self
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
    private var imageLoadTasks: [IndexPath: URLSessionDataTask] = [:]
    private var imageLoad: [IndexPath: Data] = [:]
    private var loadingCells: Set<IndexPath> = []
    private var didPreloadInitialImages = false
    
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
        
        print("Preloading images for visible index paths: \(visibleIndexPaths)")
        self.loadImages(for: visibleIndexPaths)
    }
    
    private func loadImages(for indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.row < self.viewModel.photos.value.count else { continue }
            let photo = self.viewModel.photos.value[indexPath.row]
            
            // Check cache
            guard self.imageLoad[indexPath] == nil else {
                print("Hit cache: \(indexPath)")
                DispatchQueue.main.async {
                    if let cell = self.tableView.cellForRow(at: indexPath) as? PhotoTableViewCell,
                       let data = self.imageLoad[indexPath] {
                        cell.configure(with: photo)
                        cell.setImage(data: data)
                    }
                }
                continue
            }
            
            // Mark cell as loading
            self.loadingCells.insert(indexPath)
            
            let task = URLSession.shared.dataTask(with: photo.optimizedImageURL) { [weak self] data, response, error in
                guard let `self` = self else { return }
                
                DispatchQueue.main.async {
                    self.loadingCells.remove(indexPath)
                    
                    if let data = data {
                        self.imageLoad[indexPath] = data
                        if let cell = self.tableView.cellForRow(at: indexPath) as? PhotoTableViewCell {
                            cell.configure(with: photo)
                            cell.setImage(data: data)
                        }
                    } else if let cell = self.tableView.cellForRow(at: indexPath) as? PhotoTableViewCell {
                        // If load failed, reset cell state
                        cell.configure(with: photo)
                    }
                }
                self.imageLoadTasks.removeValue(forKey: indexPath)
            }
            
            // Cancel existing task
            self.imageLoadTasks[indexPath]?.cancel()
            self.imageLoadTasks[indexPath] = task
            task.resume()
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
        
        // If we have cached image data, show image
        if let cachedData = self.imageLoad[indexPath] {
            cell.configure(with: photo)
            cell.setImage(data: cachedData)
        } else {
            // If cell is not in loading state, start loading
            cell.configure(with: photo)
            if !self.loadingCells.contains(indexPath) {
                self.loadImages(for: [indexPath])
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected cell at index path: \(indexPath)")
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

// MARK: - UITableViewDataSourcePrefetching
extension PhotoListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("Prefetching images for index paths: \(indexPaths)")
        self.loadImages(for: indexPaths)
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        print("Calcel Prefetching images for index paths: \(indexPaths)")
        for indexPath in indexPaths {
            if let task = self.imageLoadTasks[indexPath] {
                task.cancel()
                self.imageLoadTasks.removeValue(forKey: indexPath)
                self.loadingCells.remove(indexPath)
            }
        }
    }
}
