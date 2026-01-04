/// BYOND sin/cos are in degrees.
/// Returns normalized forward vector (dx, dy) for azimuth degrees.
/// NOTE: because of tile grid, we round; "diagonals" will appear naturally.
/proc/azimuth_to_step(azimuth)
	var/dx = round(cos(azimuth))
	var/dy = round(sin(azimuth))

	// Fallback so we never get 0,0 for odd rounding cases
	if(!dx && !dy)
		dx = 1
	return list(dx, dy)

/// Returns perpendicular (right-hand) vector for given forward step.
/// forward (dx,dy) => right (dy, -dx)
/proc/perp_step(dx, dy)
	return list(dy, -dx)

/// Move from start turf along (dx,dy) for N tiles; stops if turf becomes null/out of map.
/proc/step_n(turf/start, dx, dy, steps)
	var/turf/T = start
	for(var/i in 1 to steps)
		if(!T)
			break
		var/next_x = T.x + dx
		var/next_y = T.y + dy
		T = locate(next_x, next_y, T.z)
	return T

/// Random scatter inside a square radius; cheap and cheerful for SS13.
/// If you want a true circle, you can reject points outside radius.
/proc/apply_scatter(turf/origin, scatter)
	if(scatter <= 0 || !origin)
		return origin

	var/dx = rand(-scatter, scatter)
	var/dy = rand(-scatter, scatter)
	return locate(origin.x + dx, origin.y + dy, origin.z)

/// Wind cross component relative to shot azimuth.
/// Positive means drift to the "right" of the shot direction, negative to the left.
/// Uses sin(angle_diff) for side drift (classic crosswind simplification).
/proc/wind_cross_component(wind_dir, shot_azimuth)
	var/diff = wind_dir - shot_azimuth
	// Normalize to [-180,180] for nicer behavior
	while(diff > 180)
		diff -= 360
	while(diff < -180)
		diff += 360
	return sin(diff)

/// INTEGRATION: replace these with your actual stat/skill accessors.
/// Ranged skill should be a reasonable scale, e.g. 0..100.
proc/get_ranged_skill(mob/living/user)
	// Example placeholder:
	return 0

/// INTEGRATION: "ПЕРС" stat, scale 0..100 (or whatever you use)
proc/get_pers_stat(mob/living/user)
	// Example placeholder:
	return 0

/// INTEGRATION: Explosion wrapper.
/// You MUST replace this with your codebase's explosion call.
/// On /tg it's usually: explosion(turf, devastation, heavy, light, flash, flame, ...)
proc/do_artillery_explosion(turf/impact, power)
	if(!impact)
		return

	// Placeholder behavior (no-op).
	// Replace with real explosion implementation.
	// Example pseudo:
	// explosion(impact, 0, 1, 2, 3)
	return

/// helper: коротчайшая разница углов (если используешь fire())
/proc/angle_delta(a, b)
	var/d = (b - a + 540) % 360 - 180
	return d
