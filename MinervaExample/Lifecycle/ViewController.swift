//
// Copyright © 2020 Optimize Fitness Inc.
// Licensed under the MIT license
// https://github.com/OptimizeFitness/Minerva/blob/master/LICENSE
//

import Foundation
import Minerva
import UIKit

open class ViewController: UIViewController, ListControllerSizeDelegate {
  public let collectionView: UICollectionView
  public let listController: ListController

  // MARK: - Lifecycle

  public init() {
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: ListViewLayout())
    self.listController = ModernListController()
    super.init(nibName: nil, bundle: nil)

    listController.collectionView = collectionView
    listController.viewController = self
    listController.sizeDelegate = self
  }

  @available(*, unavailable)
  public required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UIViewController

  override open func viewDidLoad() {
    super.viewDidLoad()
    setupViewsAndConstraints()
  }

  override open func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    listController.willDisplay()
  }

  override open func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let cellModels = [
      MarginCellModel(identifier: "top", cellSize: .relative),
      LabelCellModel(text: "Hello World!", font: UIFont.preferredFont(forTextStyle: .body)),
      MarginCellModel(identifier: "bottom", cellSize: .relative),
    ]
    let section = ListSection(cellModels: cellModels, identifier: "section")
    listController.update(with: [section], animated: true)
  }

  override open func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    listController.didEndDisplaying()
  }

  override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    listController.invalidateLayout()
  }

  override open func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    let context = collectionView.collectionViewLayout.invalidationContext(forBoundsChange: .zero)
    coordinator.animate(
      alongsideTransition: { [weak self] _ in
        self?.collectionView.collectionViewLayout.invalidateLayout(with: context)
      },
      completion: nil
    )
  }

  // MARK: - ListControllerSizeDelegate

  open func listController(
    _ listController: ListController,
    sizeFor model: ListCellModel,
    at indexPath: IndexPath,
    constrainedTo sizeConstraints: ListSizeConstraints
  ) -> CGSize? {
    RelativeCellSizingHelper.sizeOf(
      cellModel: model,
      listController: listController,
      constrainedTo: sizeConstraints
    )
  }

  // MARK: - Private

  private func setupViewsAndConstraints() {
    view.addSubview(collectionView)
    collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    collectionView.translatesAutoresizingMaskIntoConstraints = false
  }
}
