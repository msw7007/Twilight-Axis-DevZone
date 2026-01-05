// ================================================
// artillery_coords_ss.dm
// ================================================

SUBSYSTEM_DEF(artillery_coords)
	name = "Artillery Coords"
	init_order = INIT_ORDER_DEFAULT

	/// Rotation of coord grid in degrees
	var/rot_deg = 0

	/// Scale: coord units per tile (lat/lon)
	var/scale_lat = 1.0
	var/scale_lon = 1.0

	/// Offsets so coords don't start from 0,0
	var/offset_lat = 0.0
	var/offset_lon = 0.0

/datum/controller/subsystem/artillery_coords/Initialize(timeofday)
	generate_roundstart()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/artillery_coords/proc/generate_roundstart()
	rot_deg = rand(0, 359)

	// "System changes each round": rotation + scale + offset
	// Keep numbers readable: ~0.6..1.6 coord units per tile
	scale_lat = rand(60, 160) / 100
	scale_lon = rand(60, 160) / 100

	// Offsets so разведка не "угадывает" карту по близости к нулю
	offset_lat = rand(-5000, 5000) / 10
	offset_lon = rand(-5000, 5000) / 10

/// Convert turf -> (lat, lon) in current round system
/datum/controller/subsystem/artillery_coords/proc/get_coords(turf/T)
	if(!T)
		return list(0.0, 0.0)

	var/c = cos(rot_deg)
	var/s = sin(rot_deg)

	// [lat'; lon'] = S * (R * [x;y])
	var/lat = offset_lat + scale_lat * (c * T.x - s * T.y)
	var/lon = offset_lon + scale_lon * (s * T.x + c * T.y)

	return list(lat, lon)

/// Convert delta coords -> delta world tiles (floats)
/// [dx;dy] = R^T * S^-1 * [dlat;dlon]
/datum/controller/subsystem/artillery_coords/proc/delta_world_from_delta_coords(dlat, dlon)
	var/c = cos(rot_deg)
	var/s = sin(rot_deg)

	var/dlat_u = dlat / max(scale_lat, 0.01)
	var/dlon_u = dlon / max(scale_lon, 0.01)

	var/dx = (c * dlat_u) + (s * dlon_u)
	var/dy = (-s * dlat_u) + (c * dlon_u)

	return list(dx, dy)

/datum/controller/subsystem/artillery_coords/proc/get_tile_steps()
	var/c = cos(rot_deg)
	var/s = sin(rot_deg)

	var/dlat_e = scale_lat * c
	var/dlon_e = scale_lon * s

	var/dlat_n = -scale_lat * s
	var/dlon_n = scale_lon * c

	return list(dlat_e, dlon_e, dlat_n, dlon_n)
