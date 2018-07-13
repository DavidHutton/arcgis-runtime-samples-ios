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
import ArcGIS

/// A view controller that manages the interface of the List Transformations by
/// Suitability sample.
class TransformationsBySuitabilityViewController: UIViewController {
    /// The map managed by the view controller.
    let map: AGSMap
    /// A blue square displayed on the map.
    let graphicPoint: AGSPoint
    /// A red cross displayed on the map. Will be `nil` if no transformation has
    /// been selected.
    var projectedGraphic: AGSGraphic?
    
    required init?(coder aDecoder: NSCoder) {
        map = AGSMap(basemap: .lightGrayCanvas())
        
        graphicPoint = AGSPoint(x: 538985.355, y: 177329.516, spatialReference: AGSSpatialReference(wkid: 27700))
        
        super.init(coder: aDecoder)
        
        map.load { [weak self] (error) in
            if let error = error {
                print("Error loading map: \(error)")
            } else {
                self?.updateTransformations()
            }
        }
    }
    
    @IBOutlet weak var mapView: AGSMapView!
    var transformationBrowserViewController: TransformationBrowserViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.map = map
        mapView.setViewpoint(AGSViewpoint(center: graphicPoint, scale: 5000))
        
        let graphic = AGSGraphic(geometry: graphicPoint, symbol: AGSSimpleMarkerSymbol(style: .square, color: .blue, size: 15), attributes: nil)
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.graphics.add(graphic)
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        updateTransformations()
    }
    
    /// Assigns the appropriate transformations to the transformation browser if
    /// both the view and the map have loaded.
    func updateTransformations() {
        guard isViewLoaded,
            let transformationBrowserViewController = transformationBrowserViewController,
            let inputSpacialReference = graphicPoint.spatialReference,
            let outputSpatialReference = map.spatialReference else {
                return
        }
        transformationBrowserViewController.transformations = AGSTransformationCatalog.transformationsBySuitability(withInputSpatialReference: inputSpacialReference, outputSpatialReference: outputSpatialReference)
        if let areaOfInterest = mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry as? AGSEnvelope {
            transformationBrowserViewController.filteredTransformations = AGSTransformationCatalog.transformationsBySuitability(withInputSpatialReference: inputSpacialReference, outputSpatialReference: outputSpatialReference, areaOfInterest: areaOfInterest)
        }
        transformationBrowserViewController.defaultTransformation = AGSTransformationCatalog.transformation(forInputSpatialReference: inputSpacialReference, outputSpatialReference: outputSpatialReference)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.destination {
        case let transformationBrowserViewController as TransformationBrowserViewController:
            transformationBrowserViewController.delegate = self
            self.transformationBrowserViewController = transformationBrowserViewController
        default:
            break
        }
    }
}

extension TransformationsBySuitabilityViewController: TransformationBrowserViewControllerDelegate {
    func transformationBrowser(_ controller: TransformationBrowserViewController, didSelect transformation: AGSDatumTransformation) {
        let projectedPoint = AGSGeometryEngine.projectGeometry(graphicPoint, to: map.spatialReference!, datumTransformation: transformation)
        if let graphic = projectedGraphic {
            graphic.geometry = projectedPoint
        } else {
            let graphic = AGSGraphic(geometry: projectedPoint, symbol: AGSSimpleMarkerSymbol(style: .cross, color: .red, size: 15), attributes: nil)
            let graphicsOverlay = mapView.graphicsOverlays.firstObject as? AGSGraphicsOverlay
            graphicsOverlay?.graphics.add(graphic)
            projectedGraphic = graphic
        }
    }
}
