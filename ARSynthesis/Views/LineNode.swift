//Refer to the report to check where this code has been adapted from.
import ARKit

/// This class creates a line node structure between the center of two nodes. 
class LineNode: SCNNode
{
    init(name: String,
        v1: SCNVector3,
        v2: SCNVector3,
        material: [SCNMaterial] )  
    {
        super.init()
        let  height1 = self.distanceBetweenPoints2(A: v1, B: v2) as CGFloat //v1.distance(v2)
        self.name = name
        self.nodeDescription = "line"
        position = v1
        let ndV2 = SCNNode()
        ndV2.position = v2
        let ndZAlign = SCNNode()
        ndZAlign.eulerAngles.x = Float.pi/2
        let cylgeo = SCNBox(width: 0.02, height: height1, length: 0.001, chamferRadius: 0)
        cylgeo.materials = material
        let ndCylinder = SCNNode(geometry: cylgeo)
        ndCylinder.position.y = Float(-height1/2) + 0.001
        ndZAlign.addChildNode(ndCylinder)
        addChildNode(ndZAlign)
        constraints = [SCNLookAtConstraint(target: ndV2)]
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open func removeLink(){
        self.removeFromParentNode()
    }
    
    func distanceBetweenPoints2(A: SCNVector3, B: SCNVector3) -> CGFloat {
        let l = sqrt(
            (A.x - B.x) * (A.x - B.x)
                +   (A.y - B.y) * (A.y - B.y)
                +   (A.z - B.z) * (A.z - B.z)
        )
        return CGFloat(l)
    }
}

