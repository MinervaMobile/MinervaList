//
// Copyright © 2020 Optimize Fitness Inc.
// Licensed under the MIT license
// https://github.com/OptimizeFitness/Minerva/blob/master/LICENSE
//

import Foundation
import UIKit

extension UIView {
  public func anchor(
    toLeading leading: NSLayoutXAxisAnchor?,
    top: NSLayoutYAxisAnchor?,
    trailing: NSLayoutXAxisAnchor?,
    bottom: NSLayoutYAxisAnchor?
  ) {
    if let leading = leading {
      leadingAnchor.constraint(equalTo: leading).isActive = true
    }
    if let top = top {
      topAnchor.constraint(equalTo: top).isActive = true
    }
    if let trailing = trailing {
      trailingAnchor.constraint(equalTo: trailing).isActive = true
    }
    if let bottom = bottom {
      bottomAnchor.constraint(equalTo: bottom).isActive = true
    }
  }

  public func anchorTo(layoutGuide: UILayoutGuide) {
    anchor(
      toLeading: layoutGuide.leadingAnchor,
      top: layoutGuide.topAnchor,
      trailing: layoutGuide.trailingAnchor,
      bottom: layoutGuide.bottomAnchor
    )
  }

  public func anchor(to view: UIView) {
    anchor(
      toLeading: view.leadingAnchor,
      top: view.topAnchor,
      trailing: view.trailingAnchor,
      bottom: view.bottomAnchor
    )
  }

  public func anchorHeight(to height: CGFloat) {
    heightAnchor.constraint(equalToConstant: height).isActive = true
  }

  public func anchorWidth(to width: CGFloat) {
    widthAnchor.constraint(equalToConstant: width).isActive = true
  }

  public func shouldTranslateAutoresizingMaskIntoConstraints(_ value: Bool) {
    subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = value }
  }
}
