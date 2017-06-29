# Zen3D
High-performance 3D engine for Adobe Flash &amp; AIR (GPU based)

<table>
<tr>
<td>
<img src="https://github.com/hgupta9/Zen3D/raw/master/images/zen1.png" alt="img1" width="400px">
</td>
<td>
<img src="https://github.com/hgupta9/Zen3D/raw/master/images/zen2.png" alt="img2" width="400px">
</td>
</tr>
</table>

## API

### Display Objects
The `zen.display` namespace contains visual objects that can be added to a Zen3D instance.

*Stage*

- **Zen3D** - A 3D scene and viewport, that contains all the 3D objects to be displayed. Similar to the Stage in 2D graphics.

- **ZenStereo3D** - An extension to the Zen3D class that renders two views of the same scene for stereo rendering.

*Basic objects*

- **ZenObject** - The base class for all 3D display objects. Supports transformation (position, rotation, scaling), materials, animation and mouse dragging.

- **ZenCamera** - A 3D camera that supports perspective and orthogonal views. Link this to a Zen3D instance to modify its viewport according to the camera position/rotation. You can create multiple cameras but only one can be active at a time.

- **ZenLight** - A 3D directional or point light that supports various lighting configurations. Only objects whose materials have a LightFilter will respond to lighting.

*Mesh objects*

- **ZenMesh** - A 3D mesh object that holds the geometry and material used to render it.

- **ZenFace** - A face that holds a number of triangles of a given 3D mesh (ZenMesh). For performance optimization, you can create a single face for all the tris in a mesh.

*Graphics objects*

- **ZenSpline** - A 3D B-Spline that renders multiple Spline3D objects in 3D space.

- **ZenCanvas** - A 3D canvas that supports moveTo/lineTo API similar to the Graphics class. All elements are internally rendered with 3D lines, since curves are not supported by the GPU.

- **ZenPrimitives** - A static class that provides methods to create various types of 3D primitives.

*Other objects*

- **ZenParticles** - A 3D particle manager that automatically creates 3D particles based on its configuration.

- **ZenReflector** - A 3D plane that renders the reflection of nearby objects.

- **ZenShadowLight** - A 3D shadow projector that renders shadows behind objects it is pointed towards. Must be added to a Zen3D instance to take effect.

- **ZenBatchRenderer** - Used to efficiently render multiple faces by batching them in a single draw-call

- **ZenSkyBox** - A 3D skybox that renders a six-sided cube to display a skybox texture on. 



### Physics
The `zen.physics` namespace contains a rigid-body physics engine.

- **ZenPhysics** - The main physics manager that handles rigid-body dynamics for a given Zen3D instance.



### Animation
The `zen.animation` namespace contains animation managers for meshes (ZenMesh).

- **ZenSkinModifier** -  Animates a 3D mesh using skin transform to support kinematics.

- **ZenVertexModifier** - Animates a single 3D vertex of a mesh using linear interpolation.



### Input
The `zen.input` helps you handle mouse and keyboard events.

- **KeyCodes** - Provides constants for detecting specific key codes.

- **ZenInput** - Handles keyboard and mouse events.

- **MouseEvent3D** - Fired when the user interacts with a 3D object with the mouse/touchscreen.




### Materials
The `zen.materials` namespace contains texture and material objects used by meshes.

- **ZenMaterial** - A complete material that can be applied to a ZenMesh. Contains multiple filters that configure the material's rendering.

- **ZenTexture** - A single texture bitmap used for texture mapping and for various masks/maps. Added to a ZenMaterial using filters (see below).



### Filters
The `zen.filters.color` namespace contains color and texture related filters that can be added to a ZenMaterial.

- **ColorFilter** - A material filter that tints the face by the given color.

- **ColorMatrixFilter3D** - A material filter that modifies the face by the given color matrix.

- **ColorTransformFilter** - A material filter that modifies the face by the given color transform object.

- **FogFilter** - A material filter that creates a fog effect.

- **LightFilter** - A material filter that responds to scene lighting.

- **SpecularFilter** - A material filter that responds to scene lighting supporting specular lighting.

- **NullFilter** - A material filter that changes the tint by a given color .

- **SelfColorFilter** - A material filter that tints the face by the given color.

- **VertexColorFilter** - A material filter that changes the vertex color.

The `zen.filters.maps` namespace contains texture map and map-related filters that can be added to a ZenMaterial.

- **AlphaMaskFilter** - A material filter that uses a bitmap as an alpha mask.

- **CubeMapFilter** -  A material filter that uses a bitmap as a cube map.

- **EnvironmentMapFilter** - A material filter that uses a bitmap for environment mapping.

- **LightMapFilter** - A material filter that uses a bitmap to respond to scene lighting.

- **NormalMapFilter** - A material filter that uses a bitmap to specify normals, which adds fine details to a rough mesh.

- **PlanarMapFilter** - A material filter that uses a bitmap to specify a planar map.

- **ReflectionMapFilter** - A material filter that uses a bitmap to specify reflection.

- **SpecularMapFilter** - A material filter that uses a bitmap to specify a specular map.

- **TextureMapFilter** - A material filter that displays a bitmap as the texture.

- **TextureMaskFilter** - A material filter that uses a bitmap to specify which portions of the texture are visible.

The `zen.filters.transform` namespace contains transform-related filters that can be added to a ZenMaterial.

- **FlipNormalsFilter** - A material filter that flips all vertex/face normals.

- **SkinTransformFilter** -  A material filter that responds to skin transform.

- **TransformFilter** - A material filter that responds to transform.



### Geometry
The `zen.geom` namespace contains geometry objects used throughout the library.

- **M3D** - Primitive geometric calculations for 3D matrices.

- **V3D** - Primitive geometric calculations for 3D vectors and points.

- **Cube3D** - An axis-aligned 3D cube that storeds information of object bounds & dimensions.

- **Frame3D** - A matrix that stores information about a certain object's transform (or frame).

- **Intersection3D** - A single 3D intersection between two objects.

- **Spline3D** - A 3D B-spline consisting of multiple knots (SplineKnot3D).

- **SplineKnot3D** - A knot on a 3D spline (Spline3D).

The `zen.geom.intersects` namespace contains calculators for various types of 3D intersections.

- **MouseIntersect** - Calculates intersection of 3D objects and the mouse, or any 2D point.

- **RayIntersect** - Calculates intersection of 3D objects and a 3D ray.

- **SphereIntersect** - Calculates intersection of 3D objects and a 3D sphere.

