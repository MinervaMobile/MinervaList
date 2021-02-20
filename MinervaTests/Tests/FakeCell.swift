//
// Copyright © 2020 Optimize Fitness Inc.
// Licensed under the MIT license
// https://github.com/OptimizeFitness/Minerva/blob/master/LICENSE
//

import Foundation
import Minerva

public struct FakeCellModel: ListTypedCellModel, ListSelectableCellModel,
  ListHighlightableCellModel, ListReorderableCellModel
{
  public typealias CellType = FakeCell

  public typealias SelectableModelType = FakeCellModel
  public var selectionAction: SelectionAction?

  public typealias HighlightableModelType = FakeCellModel
  public var highlightEnabled: Bool = true
  public var highlightColor: UIColor?

  public var highlightedAction: HighlightAction?
  public var unhighlightedAction: HighlightAction?

  public var reorderable: Bool = true

  public var identifier: String
  public var size: ListCellSize
  public var placeholderText: String?

  public func identical(to model: FakeCellModel) -> Bool {
    size == model.size
      && highlightEnabled == model.highlightEnabled
      && highlightColor == model.highlightColor
      && reorderable == model.reorderable
  }

  public func size(constrainedTo containerSize: CGSize) -> ListCellSize {
    size
  }

  public static func createCellModels(
    count: Int,
    idPrefix: String = UUID().uuidString + "-",
    width: CGFloat = 75,
    height: CGFloat = 100
  )
    -> [FakeCellModel]
  {
    (1...count)
      .map {
        FakeCellModel(
          identifier: "FakeCellModel-\(idPrefix)\($0)",
          size: .explicit(size: CGSize(width: width, height: 100))
        )
      }
  }
}

public final class FakeCell: ListCollectionViewCell, ListTypedCell, ListDisplayableCell {
  public var handledWillDisplay = false
  public var handledDidEndDisplaying = false

  public var displaying = false

  private var sizingView: UIView?

  override public func prepareForReuse() {
    super.prepareForReuse()
    sizingView?.removeFromSuperview()
    sizingView = nil
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func bind(model: FakeCellModel, sizing: Bool) {
    if let placeholderText = model.placeholderText {
      let view = UILabel()
      view.text = placeholderText
      contentView.addSubview(view)
      view.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
      view.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
      view.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
      view.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
      view.translatesAutoresizingMaskIntoConstraints = false

      sizingView = view
    }
  }

  public func bindViewModel(_ viewModel: Any) { bind(viewModel) }

  public func willDisplayCell() {
    handledWillDisplay = true
    displaying = true
  }

  public func didEndDisplayingCell() {
    handledDidEndDisplaying = true
    displaying = false
  }
}
