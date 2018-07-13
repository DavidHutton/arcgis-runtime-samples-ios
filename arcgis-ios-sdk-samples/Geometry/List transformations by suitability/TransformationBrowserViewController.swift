//
// Copyright © 2018 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import class ArcGIS.AGSDatumTransformation

/// The protocol you implement to respond as the user interacts with the
/// transformation browser.
protocol TransformationBrowserViewControllerDelegate: class {
    func transformationBrowser(_ controller: TransformationBrowserViewController, didSelect transformation: AGSDatumTransformation)
}

/// A view controller for browsing and selecting datum transformations.
class TransformationBrowserViewController: UITableViewController {
    /// The transformation browser's delegate.
    weak var delegate: TransformationBrowserViewControllerDelegate?
    /// The transformations displayed by the view controller.
    var transformations = [AGSDatumTransformation]() {
        didSet {
            guard isViewLoaded else { return }
            tableView.reloadSections([0], with: .none)
        }
    }
    var filteredTransformations = [AGSDatumTransformation]()
    /// The transformation that will be displayed in bold.
    var defaultTransformation: AGSDatumTransformation? {
        didSet {
            guard defaultTransformation != oldValue else { return }
            guard isViewLoaded else { return }
            var indexPaths = [IndexPath]()
            if let transformation = oldValue, let indexPath = indexPathOfRow(for: transformation) {
                indexPaths.append(indexPath)
            }
            if let transformation = defaultTransformation, let indexPath = indexPathOfRow(for: transformation) {
                indexPaths.append(indexPath)
            }
            tableView.reloadRows(at: indexPaths, with: .none)
        }
    }
    
    var effectiveTransformations: [AGSDatumTransformation] {
        return []
    }
    
    /// Returns an index path for the cell of the given transformation.
    ///
    /// - Parameter transformation: A datum transformation object.
    /// - Returns: An index path for the cell of the given transformation or
    /// `nil` if the index path is invalid.
    func indexPathOfRow(for transformation: AGSDatumTransformation) -> IndexPath? {
        if let row = transformations.index(of: transformation) {
            return IndexPath(row: row, section: 0)
        } else {
            return nil
        }
    }
    
    /// Returns the transformation for the row at the given index path.
    ///
    /// - Parameter indexPath: An index path.
    /// - Returns: A transformation object for the row at the given index path.
    func transformationForRow(at indexPath: IndexPath) -> AGSDatumTransformation {
        return transformations[indexPath.row]
    }
}

extension TransformationBrowserViewController /* UITableViewDataSource */ {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transformations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transformation = transformationForRow(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransformationCell", for: indexPath)
        cell.textLabel?.text = transformation.name
        cell.textLabel?.font = {
            let fontSize = UIFont.systemFontSize
            if transformation == defaultTransformation {
                return UIFont.boldSystemFont(ofSize: fontSize)
            } else {
                return UIFont.systemFont(ofSize: fontSize)
            }
        }()
        cell.textLabel?.textColor = !transformation.isMissingProjectionEngineFiles ? .black : .gray
        cell.isUserInteractionEnabled = !transformation.isMissingProjectionEngineFiles
        return cell
    }
}

extension TransformationBrowserViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.transformationBrowser(self, didSelect: transformationForRow(at: indexPath))
    }
}
