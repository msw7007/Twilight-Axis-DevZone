// caches: id(string) -> list(turf)
GLOBAL_LIST_EMPTY(landmark_turf_cache)

/// Returns list of turfs for landmarks matching `id`.
/// Match rules:
/// 1) landmark.tag == id
/// 2) landmark.name == id
/proc/get_landmark_turfs(id, use_cache = TRUE)
	if(!id)
		return null

	if(use_cache)
		var/list/cached = GLOB.landmark_turf_cache[id]
		if(cached)
			// ВАЖНО: кеш может протухать, если кто-то qdel'ит лендмарки.
			// Для ваших обычных landmark'ов это редкость, но можно чистить вручную при надобности.
			return cached

	var/list/out = list()

	for(var/obj/effect/landmark/L as anything in GLOB.landmarks_list)
		if(L.port_zone != id && L.name != id)
			continue

		var/turf/T = get_turf(L)
		if(T)
			out += T

	if(use_cache)
		GLOB.landmark_turf_cache[id] = out

	return out

/// Picks a random turf from landmarks matching `id`. Returns null if none found.
/proc/pick_landmark_turf(id, use_cache = TRUE)
	var/list/turfs = get_landmark_turfs(id, use_cache)
	if(!turfs || !turfs.len)
		return null
	return pick(turfs)

/// Optional: invalidate cache for one id (or all).
/proc/clear_landmark_turf_cache(id = null)
	if(isnull(id))
		GLOB.landmark_turf_cache = list()
	else
		GLOB.landmark_turf_cache -= id

/obj/effect/landmark
	var/port_zone

/obj/effect/landmark/abyss_return
	name = "abyss return"
	icon_state = "x2"
	port_zone = "abyss_return"

/obj/effect/landmark/sky_fall
	name = "sky fall"
	icon_state = "x2"
	port_zone = "sky_fall"
