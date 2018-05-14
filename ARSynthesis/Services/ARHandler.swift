import ARKit

class ARHandler{
    var arScene = ARSCNView()
    var collectionCells: [UICollectionViewCell] = []
    private init (){}
    static let arHandler = ARHandler()
}
