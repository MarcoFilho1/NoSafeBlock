extends RefCounted
static func nearest(origin: Vector3, nodes: Array) -> Node:
	var result: Node3D = null
	var distance := 2.5
	for node in nodes:
		var candidate: float = node.global_position.distance_to(origin)
		if candidate >= distance:
			continue
		var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP, node.global_position + Vector3.UP, 1)
		if node.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			result = node
			distance = candidate
	return result
