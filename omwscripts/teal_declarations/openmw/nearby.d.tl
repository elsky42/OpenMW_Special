--[[
  `openmw.nearby` provides read-only access to the nearest area of the game world.
  Can be used only from local scripts.
  local nearby = require('openmw.nearby')
]]

local openmw_async = require("openmw.async")
local openmw_core = require("openmw.core")
local openmw_util = require("openmw.util")
global record COLLISION_TYPE
  Actor: number
  
  --[[
    World+Door+Actor+HeightMap+Projectile+Water
  ]]
  AnyPhysical: number
  
  --[[
    Objects that should collide only with camera
  ]]
  Camera: number
  
  --[[
    Used by default: World+Door+Actor+HeightMap
  ]]
  Default: number
  
  Door: number
  
  HeightMap: number
  
  Projectile: number
  
  --[[
    Objects that were not intended to be part of the physics world
  ]]
  VisualOnly: number
  
  Water: number
  
  World: number
  
end
local record nearby
  --[[
    Collision types that are used in `castRay`.
    Several types can be combined with @{openmw_util#util.bitOr}.
  ]]
  COLLISION_TYPE: COLLISION_TYPE
  
  --[[
    List of nearby activators.
  ]]
  activators: openmw_core.ObjectList
  
  --[[
    List of nearby actors.
  ]]
  actors: openmw_core.ObjectList
  
  --[[
    Asynchronously cast ray from one point to another and find the first visual intersection with anything in the scene.
  ]]
  asyncCastRenderingRay: function(
    callback: openmw_async.Callback, --[[The callback to pass the result to (should accept a single argument @{openmw.nearby#RayCastingResult}).]]
    from: openmw_util.Vector3, --[[Start point of the ray.]]
    to: openmw_util.Vector3
  )
  
  --[[
    Finds a nearest to the ray target position starting from the initial position with resulting curve drawn on the
    navigation mesh surface.
    local position = nearby.castNavigationRay(from, to)
  ]]
  castNavigationRay: function(
    from: openmw_util.Vector3, --[[Initial ray position.]]
    to: openmw_util.Vector3, --[[Target ray position.]]
    options: nearby.NavMeshOptions
  ): openmw_util.Vector3 | nil
  
  --[[
    Cast ray from one point to another and return the first collision.
    if nearby.castRay(pointA, pointB).hit then print('obstacle between A and B') end
  ]]
  castRay: function(
    from: openmw_util.Vector3, --[[Start point of the ray.]]
    to: openmw_util.Vector3, --[[End point of the ray.]]
    options: nearby.CastRayOptions
  ): nearby.RayCastingResult
  
  --[[
    Cast ray from one point to another and find the first visual intersection with anything in the scene.
    As opposite to `castRay` can find an intersection with an object without collisions.
    In order to avoid threading issues can be used only in player scripts only in `onFrame` or
    in engine handlers for user input. In other cases use `asyncCastRenderingRay` instead.
  ]]
  castRenderingRay: function(
    from: openmw_util.Vector3, --[[Start point of the ray.]]
    to: openmw_util.Vector3
  ): nearby.RayCastingResult
  
  --[[
    List of nearby containers.
  ]]
  containers: openmw_core.ObjectList
  
  --[[
    List of nearby doors.
  ]]
  doors: openmw_core.ObjectList
  
  --[[
    Finds a nearest position on navigation mesh to the given position within given search area.
    local navMeshPosition = nearby.findNearestNavMeshPosition(position)
  ]]
  findNearestNavMeshPosition: function(
    position: openmw_util.Vector3, --[[Search area center.]]
    options: nearby.FindNearestNavMeshPositionOptions
  ): openmw_util.Vector3 | nil
  
  --[[
    Find path over navigation mesh from source to destination with given options.
    Result is unstable since navigation
    mesh generation is asynchronous.
    local status, path = nearby.findPath(source, destination)
  ]]
  findPath: function(
    source: openmw_util.Vector3, --[[Initial path position.]]
    destination: openmw_util.Vector3, --[[Final path position.]]
    options: nearby.FindPathOptions
  ): nearby.FIND_PATH_STATUS,
    { openmw_util.Vector3 }
  
  --[[
    Returns random location on navigation mesh within the reach of specified location.
    The location is not exactly constrained by the circle, but it limits the area.
    local position = nearby.findRandomPointAroundCircle(position, maxRadius)
  ]]
  findRandomPointAroundCircle: function(
    position: openmw_util.Vector3, --[[Center of the search circle.]]
    maxRadius: number, --[[Approximate maximum search distance.]]
    options: nearby.NavMeshOptions
  ): openmw_util.Vector3 | nil
  
  --[[
    Return an object by RefNum/FormId.
    Note: the function always returns @{openmw.core#GameObject} and doesn't validate that
    the object exists in the game world. If it doesn't exist or not yet loaded to memory),
    then `obj:isValid()` will be `false`.
    local obj = nearby.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))
  ]]
  getObjectByFormId: function(
    formId: string
  ): openmw_core.GameObject
  
  --[[
    Everything nearby that is derived from @{openmw.types#Item}.
  ]]
  items: openmw_core.ObjectList
  
  --[[
    List of nearby players.
    Currently (since multiplayer is not yet implemented) always has one element.
  ]]
  players: openmw_core.ObjectList
  
  --[[
    A table of parameters identifying navmesh
  ]]
  record AgentBounds
    halfExtents: openmw_util.Vector3
    
    shapeType: nearby.COLLISION_SHAPE_TYPE
    
  end
  --[[
    A table of parameters to specify relative path cost per each area type
  ]]
  record AreaCosts
    --[[
      Value >= 0, used in combination with @{#NAVIGATOR_FLAGS.OpenDoor}
      (default: 2).
    ]]
    door: number
    
    --[[
      Value >= 0, used in combination with @{#NAVIGATOR_FLAGS.Walk} (default: 1).
    ]]
    ground: number
    
    --[[
      Value >= 0, used in combination with @{#NAVIGATOR_FLAGS.UsePathgrid}
      (default: 1).
    ]]
    pathgrid: number
    
    --[[
      Value >= 0, used in combination with @{#NAVIGATOR_FLAGS.Swim} (default: 1).
    ]]
    water: number
    
  end
  record COLLISION_SHAPE_TYPE
    --[[
      Axis-Aligned Bounding Box is used for NPC and symmetric
      Creatures.
    ]]
    Aabb: number
    
    --[[
      is used for NPC and symmetric Creatures.
    ]]
    Cylinder: number
    
    --[[
      is used for Creatures with big difference in width and
      height.
    ]]
    RotatingBox: number
    
  end
  --[[
    A table of parameters for @{#nearby.castRay}
  ]]
  record CastRayOptions
    --[[
      Object types to work with (see @{openmw.nearby#COLLISION_TYPE})
    ]]
    collisionType: number
    
    --[[
      An object to ignore (specify here the source of the ray)
    ]]
    ignore: openmw_core.GameObject
    
    --[[
      The radius of the ray (zero by default). If not zero then castRay actually casts a sphere with given radius.
       NOTE: currently `ignore` is not supported if `radius>0`.
    ]]
    radius: number
    
  end
  --[[
    A table of parameters for @{#nearby.castRenderingRay} and @{#nearby.asyncCastRenderingRay}
  ]]
  record CastRenderingRayOptions
    --[[
      A list of @{openmw.core#GameObject} to ignore while doing the ray cast
    ]]
    ignore: table
    
  end
  record FIND_PATH_STATUS
    --[[
      `destination` position is too far from available
      navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside of covered
      area;
    ]]
    EndPolygonNotFound: number
    
    --[[
      Path over navigation mesh from `source` to
      `destination` does not exist or navigation mesh is not fully generated to provide the path;
    ]]
    FindPathOverPolygonsFailed: number
    
    --[[
      Couldn't map path over polygons into world
      coordinates.
    ]]
    FindStraightPathFailed: number
    
    --[[
      Couldn't initialize required data due to bad input
      or bad navigation mesh data.
    ]]
    InitNavMeshQueryFailed: number
    
    --[[
      Found path couldn't be smoothed due to imperfect
      algorithm implementation or bad navigation mesh data;
    ]]
    MoveAlongSurfaceFailed: number
    
    --[[
      Provided `agentBounds` don't have corresponding navigation
      mesh. For interior cells it means an agent with such `agentBounds` is present on the scene. For exterior cells only
      default `agentBounds` is supported;
    ]]
    NavMeshNotFound: number
    
    --[[
      Last path point is not a destination but a nearest position
      among found;
    ]]
    PartialPath: number
    
    --[[
      `source` position is too far from available
      navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside of covered
      area;
    ]]
    StartPolygonNotFound: number
    
    --[[
      Path is found.
    ]]
    Success: number
    
    --[[
      adjusted `destination` position is too far from
      available navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside
      of covered area;
    ]]
    TargetPolygonNotFound: number
    
  end
  --[[
    A table of parameters for @{#nearby.findNearestNavMeshPosition}
  ]]
  record FindNearestNavMeshPositionOptions
    --[[
      Identifies which navmesh to use.
    ]]
    agentBounds: nearby.AgentBounds
    
    --[[
      Allowed areas for agent to move, a sum of @{#NAVIGATOR_FLAGS}
      values (default: @{#NAVIGATOR_FLAGS.Walk} + @{#NAVIGATOR_FLAGS.Swim} + @{#NAVIGATOR_FLAGS.OpenDoor}
      + @{#NAVIGATOR_FLAGS.UsePathgrid}).
    ]]
    includeFlags: number
    
    --[[
      Defines AABB like area half extents around
      given position (default: (1 + 2 * CellGridRadius) * CellSize * (1, 1, 1) where CellGridRadius and depends on cell
      type to cover the whole active grid).
    ]]
    searchAreaHalfExtents: openmw_util.Vector3
    
  end
  --[[
    A table of parameters for @{#nearby.findPath}
  ]]
  record FindPathOptions
    --[[
      identifies which navmesh to use.
    ]]
    agentBounds: nearby.AgentBounds
    
    --[[
      a table defining relative cost for each type of area.
    ]]
    areaCosts: nearby.AreaCosts
    
    --[[
      a floating point number representing maximum allowed
      distance between destination and a nearest point on the navigation mesh in addition to agent size (default: 1).
    ]]
    destinationTolerance: number
    
    --[[
      allowed areas for agent to move, a sum of @{#NAVIGATOR_FLAGS}
      values (default: @{#NAVIGATOR_FLAGS.Walk} + @{#NAVIGATOR_FLAGS.Swim} + @{#NAVIGATOR_FLAGS.OpenDoor}
      + @{#NAVIGATOR_FLAGS.UsePathgrid}).
    ]]
    includeFlags: number
    
  end
  record NAVIGATOR_FLAGS
    --[[
      Allow agent to open doors on the way.
    ]]
    OpenDoor: number
    
    --[[
      Allow agent to swim on the water surface.
    ]]
    Swim: number
    
    --[[
      Allow agent to use predefined pathgrid imported from ESM files.
    ]]
    UsePathgrid: number
    
    --[[
      Allow agent to walk on the ground area.
    ]]
    Walk: number
    
  end
  --[[
    A table of parameters for @{#nearby.findRandomPointAroundCircle} and @{#nearby.castNavigationRay}
  ]]
  record NavMeshOptions
    --[[
      Identifies which navmesh to use.
    ]]
    agentBounds: nearby.AgentBounds
    
    --[[
      Allowed areas for agent to move, a sum of @{#NAVIGATOR_FLAGS}
      values (default: @{#NAVIGATOR_FLAGS.Walk} + @{#NAVIGATOR_FLAGS.Swim} + @{#NAVIGATOR_FLAGS.OpenDoor}
      + @{#NAVIGATOR_FLAGS.UsePathgrid}).
    ]]
    includeFlags: number
    
  end
  --[[
    Result of raycasing
  ]]
  record RayCastingResult
    --[[
      Is there a collision? (true/false)
    ]]
    hit: boolean
    
    --[[
      Normal to the surface in the collision point (nil if no collision)
    ]]
    hitNormal: openmw_util.Vector3
    
    --[[
      The object the ray has collided with (can be nil)
    ]]
    hitObject: openmw_core.GameObject
    
    --[[
      Position of the collision point (nil if no collision)
    ]]
    hitPos: openmw_util.Vector3
    
  end
end
return nearby