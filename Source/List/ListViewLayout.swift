//
// Copyright © 2020 Optimize Fitness Inc.
// Licensed under the MIT license
// https://github.com/OptimizeFitness/Minerva/blob/master/LICENSE
//

import Foundation
import UIKit

/// The base layout that should be used for any collection view controlled by Minerva.
open class ListViewLayout: UICollectionViewFlowLayout {
  override public class var layoutAttributesClass: AnyClass {
    ListViewLayoutAttributes.self
  }
}
