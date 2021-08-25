//
// Copyright © 2020 Optimize Fitness Inc.
// Licensed under the MIT license
// https://github.com/OptimizeFitness/Minerva/blob/master/LICENSE
//

import Foundation
import UIKit

public final class ModernListController: NSObject, ListController {
  private enum Action {
    case didEndDisplaying
    case invalidateLayout
    case reloadData(completion: Completion?)
    case scrollTo(
      cellModel: ListCellModel,
      scrollPosition: UICollectionView.ScrollPosition,
      animated: Bool
    )
    case scroll(scrollPosition: UICollectionView.ScrollPosition, animated: Bool)
    case update(listSections: [ListSection], animated: Bool, completion: Completion?)
    case willDisplay
  }

  public typealias Completion = (Bool) -> Void

  public weak var animationDelegate: ListControllerAnimationDelegate?
  public weak var reorderDelegate: ListControllerReorderDelegate?
  public weak var sizeDelegate: ListControllerSizeDelegate?

  public weak var scrollViewDelegate: UIScrollViewDelegate?
  public weak var viewController: UIViewController?
  public weak var collectionView: UICollectionView?

  public private(set) var listSections: [ListSection]

  private var noLongerDisplayingCells = false
  private var sizeController: ListCellSizeController
  private var actionQueue = [Action]()
  private var updating = false

  // MARK: - Initializers

  override public init() {
    self.sizeController = ListCellSizeController()
    self.listSections = []
    super.init()
    sizeController.delegate = self
  }

  // MARK: - Public

  public func reloadData(completion: Completion?) {
    dispatchPrecondition(condition: .onQueue(.main))
    reloadData(completion: completion, enqueueIfNeeded: true, listSections: nil)
  }

  public func reloadData(listSections: [ListSection], completion: Completion?) {
    dispatchPrecondition(condition: .onQueue(.main))
    reloadData(completion: completion, enqueueIfNeeded: true, listSections: listSections)
  }

  public func update(with listSections: [ListSection], animated: Bool, completion: Completion?) {
    dispatchPrecondition(condition: .onQueue(.main))
    update(with: listSections, animated: animated, completion: completion, enqueueIfNeeded: true)
  }

  public func willDisplay() {
    dispatchPrecondition(condition: .onQueue(.main))
    willDisplay(enqueueIfNeeded: true)
  }

  public func didEndDisplaying() {
    dispatchPrecondition(condition: .onQueue(.main))
    didEndDisplaying(enqueueIfNeeded: true)
  }

  public func invalidateLayout() {
    dispatchPrecondition(condition: .onQueue(.main))
    invalidateLayout(enqueueIfNeeded: true)
  }

  public func indexPath(for cellModel: ListCellModel) -> IndexPath? {
    dispatchPrecondition(condition: .onQueue(.main))
    for (sectionIndex, section) in listSections.enumerated() {
      for (rowIndex, model) in section.cellModels.enumerated() {
        if cellModel.identifier == model.identifier, cellModel.identical(to: model) {
          return IndexPath(item: rowIndex, section: sectionIndex)
        }
      }
    }
    return nil
  }

  public var centerCellModel: ListCellModel? {
    dispatchPrecondition(condition: .onQueue(.main))
    guard
      let indexPath = collectionView?.centerCellIndexPath,
      let cellModel = cellModel(at: indexPath)
    else {
      return nil
    }
    return cellModel
  }

  public func cellModel(at indexPath: IndexPath) -> ListCellModel? {
    dispatchPrecondition(condition: .onQueue(.main))
    guard let model = listSections.at(indexPath.section)?.cellModels.at(indexPath.item) else {
      return nil
    }
    return model
  }

  public func removeCellModel(at indexPath: IndexPath, animated: Bool, completion: Completion?) {
    dispatchPrecondition(condition: .onQueue(.main))
    guard listSections.at(indexPath.section)?.cellModels.at(indexPath.item) != nil else {
      assertionFailure("Could not find model at indexPath")
      return
    }
    var listSections = self.listSections
    var section = listSections[indexPath.section]
    var cellModels = section.cellModels
    cellModels.remove(at: indexPath.row)

    if cellModels.isEmpty {
      listSections.remove(at: indexPath.section)
    } else {
      section.cellModels = cellModels
      listSections[indexPath.section] = section
    }
    update(with: listSections, animated: animated, completion: completion)
  }

  public func scrollTo(
    cellModel: ListCellModel,
    scrollPosition: UICollectionView.ScrollPosition,
    animated: Bool
  ) {
    dispatchPrecondition(condition: .onQueue(.main))
    scrollTo(
      cellModel: cellModel,
      scrollPosition: scrollPosition,
      animated: animated,
      enqueueIfNeeded: true
    )
  }

  public func scroll(to scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
    dispatchPrecondition(condition: .onQueue(.main))
    scroll(to: scrollPosition, animated: animated, enqueueIfNeeded: true)
  }

  public func size(of listSection: ListSection, containerSize: CGSize) -> CGSize {
    dispatchPrecondition(condition: .onQueue(.main))
    let sizeConstraints = ListSizeConstraints(
      containerSize: containerSize,
      sectionConstraints: listSection.constraints
    )

    guard let sectionIndex = sectionIndexOf(listSection) else { return .zero }
    return sizeController.size(of: listSection, atSectionIndex: sectionIndex, with: sizeConstraints)
  }

  public func size(of cellModel: ListCellModel, with constraints: ListSizeConstraints) -> CGSize {
    dispatchPrecondition(condition: .onQueue(.main))

    let indexPath = self.indexPath(for: cellModel)
    let listSection: ListSection?
    if let indexPath = indexPath {
      listSection = listSections.at(indexPath.section)
    } else {
      listSection = nil
    }

    return sizeController.size(
      for: cellModel,
      at: indexPath,
      in: listSection,
      with: constraints,
      enableSizeByDelegate: false
    )
  }

  // MARK: - Private

  private func endDisplayingVisibleCells() {
    guard let visibleCells = collectionView?.visibleCells else { return }
    visibleCells.compactMap { $0 as? ListDisplayableCell }.forEach { $0.didEndDisplayingCell() }
  }

  private func sectionIndexOf(_ listSection: ListSection) -> Int? {
    guard
      let sectionIndex = listSections.firstIndex(where: { $0.identifier == listSection.identifier })
    else {
      assertionFailure(
        "The listSection should be in listSections"
      )
      return nil
    }
    return sectionIndex
  }

  private func processActionQueue() {
    guard !actionQueue.isEmpty else {
      return
    }
    let action = actionQueue.removeFirst()
    switch action {
    case .didEndDisplaying:
      didEndDisplaying(enqueueIfNeeded: false)
    case .invalidateLayout:
      invalidateLayout(enqueueIfNeeded: false)
    case let .reloadData(completion):
      reloadData(completion: completion, enqueueIfNeeded: false)
    case let .scroll(scrollPosition, animated):
      scroll(to: scrollPosition, animated: animated, enqueueIfNeeded: false)
    case let .scrollTo(cellModel, scrollPosition, animated):
      scrollTo(
        cellModel: cellModel,
        scrollPosition: scrollPosition,
        animated: animated,
        enqueueIfNeeded: false
      )
    case let .update(listSections, animated, completion):
      update(with: listSections, animated: animated, completion: completion, enqueueIfNeeded: false)
    case .willDisplay:
      willDisplay(enqueueIfNeeded: false)
    }
  }

  private func reloadData(completion: Completion?, enqueueIfNeeded: Bool, listSections: [ListSection]? = nil) {
    guard !enqueueIfNeeded || (actionQueue.isEmpty && !updating) else {
      actionQueue.append(.reloadData(completion: completion))
      return
    }
    updating = true
    if let listSections = listSections {
      self.listSections = listSections
    }
    collectionView?.reloadData()
    if noLongerDisplayingCells {
      endDisplayingVisibleCells()
    }
    updating = false
    processActionQueue()
    completion?(true)
  }

  private func update(
    with listSections: [ListSection],
    animated: Bool,
    completion: Completion?,
    enqueueIfNeeded: Bool
  ) {
    guard !enqueueIfNeeded || (actionQueue.isEmpty && !updating) else {
      actionQueue.append(
        .update(listSections: listSections, animated: animated, completion: completion)
      )
      return
    }
    #if DEBUG
    var identifiers = [String: ListCellModel]() // Should be unique across ListSections in the same UICollectionView.
    for section in listSections {
      for cellModel in section.cellModels {
        let identifier = cellModel.identifier
        if identifier.isEmpty {
          assertionFailure("Found a cell model with an invalid ID \(cellModel)")
        }
        if let existingCellModel = identifiers[identifier] {
          assertionFailure(
            "Found a cell model with a duplicate ID \(identifier) - \(cellModel) - \(existingCellModel)"
          )
        }
        identifiers[identifier] = cellModel
      }
    }
    #endif
    updating = true
    self.listSections = listSections
    collectionView?.performBatchUpdates({}, completion: { [weak self] finished in
      defer {
        completion?(finished)
      }
      guard let strongSelf = self else {
        return
      }
      if strongSelf.noLongerDisplayingCells {
        strongSelf.endDisplayingVisibleCells()
      }
      strongSelf.updating = false
      strongSelf.processActionQueue()
    })
  }

  private func didEndDisplaying(enqueueIfNeeded: Bool) {
    guard !enqueueIfNeeded || (actionQueue.isEmpty && !updating) else {
      actionQueue.append(.didEndDisplaying)
      return
    }
    defer {
      processActionQueue()
    }
    guard !noLongerDisplayingCells else { return }
    endDisplayingVisibleCells()
    noLongerDisplayingCells = true
  }

  private func willDisplay(enqueueIfNeeded: Bool) {
    guard !enqueueIfNeeded || (actionQueue.isEmpty && !updating) else {
      actionQueue.append(.willDisplay)
      return
    }
    defer {
      processActionQueue()
    }
    guard noLongerDisplayingCells else { return }
    guard let visibleCells = collectionView?.visibleCells else { return }
    visibleCells.compactMap { $0 as? ListDisplayableCell }.forEach { $0.willDisplayCell() }
    noLongerDisplayingCells = false
  }

  private func invalidateLayout(enqueueIfNeeded: Bool) {
    guard !enqueueIfNeeded || (actionQueue.isEmpty && !updating) else {
      actionQueue.append(.invalidateLayout)
      return
    }
    sizeController.clearCache()
    if let collectionView = collectionView {
      let context = collectionView.collectionViewLayout.invalidationContext(forBoundsChange: .zero)
      collectionView.collectionViewLayout.invalidateLayout(with: context)
    }
    processActionQueue()
  }

  private func scrollTo(
    cellModel: ListCellModel,
    scrollPosition: UICollectionView.ScrollPosition,
    animated: Bool,
    enqueueIfNeeded: Bool
  ) {
    guard let collectionView = self.collectionView else { return }
    guard !enqueueIfNeeded || (actionQueue.isEmpty && !updating) else {
      actionQueue.append(
        .scrollTo(cellModel: cellModel, scrollPosition: scrollPosition, animated: animated)
      )
      return
    }
    defer {
      processActionQueue()
    }
    guard
      let sectionIndex = listSections.firstIndex(where: {
        $0.cellModels.contains(where: { $0.identifier == cellModel.identifier })
      })
    else {
      assertionFailure("Section should exist for \(cellModel)")
      return
    }
    let section = listSections[sectionIndex]
    guard
      let modelIndex = section.cellModels.firstIndex(where: {
        $0.identifier == cellModel.identifier
      })
    else {
      assertionFailure("index should exist for \(cellModel)")
      return
    }
    let indexPath = IndexPath(item: modelIndex, section: sectionIndex)
    guard collectionView.isIndexPathAvailable(indexPath) else {
      assertionFailure("IndexPath should exist for \(cellModel)")
      return
    }
    collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
  }

  private func scroll(
    to scrollPosition: UICollectionView.ScrollPosition,
    animated: Bool,
    enqueueIfNeeded: Bool
  ) {
    guard !enqueueIfNeeded || (actionQueue.isEmpty && !updating) else {
      actionQueue.append(.scroll(scrollPosition: scrollPosition, animated: animated))
      return
    }
    guard !listSections.isEmpty else {
      processActionQueue()
      return
    }
    let cellModels = listSections.flatMap(\.cellModels)
    guard !cellModels.isEmpty else {
      processActionQueue()
      return
    }
    let model: ListCellModel?
    switch scrollPosition {
    case .top, .left:
      model = cellModels.first
    case .centeredVertically, .centeredHorizontally:
      let middleIndex = cellModels.count / 2
      model = cellModels.at(middleIndex)
    case .bottom, .right:
      model = cellModels.last
    default:
      model = cellModels.first
    }

    guard let cellModel = model else {
      processActionQueue()
      return
    }
    scrollTo(
      cellModel: cellModel,
      scrollPosition: .centeredVertically,
      animated: animated,
      enqueueIfNeeded: false
    )
  }
}

// MARK: - ListCellSizeControllerDelegate

extension ModernListController: ListCellSizeControllerDelegate {
  internal func sizeController(
    _ sizeController: ListCellSizeController,
    sizeFor model: ListCellModel,
    at indexPath: IndexPath,
    constrainedTo sizeConstraints: ListSizeConstraints
  ) -> CGSize? {
    sizeDelegate?
      .listController(
        self,
        sizeFor: model,
        at: indexPath,
        constrainedTo: sizeConstraints
      )
  }
}
