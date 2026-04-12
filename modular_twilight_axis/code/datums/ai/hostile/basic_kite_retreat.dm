/datum/ai_behavior/basic_kite/proc/try_retreat(datum/ai_controller/controller, atom/target)
	var/mob/living/simple_animal/M = controller.pawn
	if(!istype(M))
		return

	var/turf/current = get_turf(M)
	if(!current)
		return

	var/current_dist = get_dist(current, target)
	var/turf/best = null
	var/best_dist = current_dist

	for(var/dir in GLOB.cardinals)
		var/turf/T = get_step(current, dir)
		if(!T || T.density)
			continue

		var/d = get_dist(T, target)
		if(d > best_dist)
			best = T
			best_dist = d

	if(!best)
		for(var/dir in GLOB.alldirs)
			if(dir in GLOB.cardinals)
				continue

			var/turf/T = get_step(current, dir)
			if(!T || T.density)
				continue

			var/d = get_dist(T, target)
			if(d > best_dist)
				best = T
				best_dist = d

	if(best)
		M.Move(best)
		M.face_atom(target)
