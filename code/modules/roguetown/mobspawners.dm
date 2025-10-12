#define SPAWN_DISTANCE 20
#define FORCESPAWN_DISTANCE 5

SUBSYSTEM_DEF(mob_spawners)
	name = "Mob Spawners"
	wait = 1 SECONDS
	priority = FIRE_PRIORITY_NPC
	flags = SS_POST_FIRE_TIMING|SS_NO_INIT|SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	var/list/currentrun = list()

/datum/controller/subsystem/mob_spawners/fire(resumed = FALSE)
	if (!resumed || !src.currentrun.len)
		var/list/activelist = GLOB.mob_spawners
		src.currentrun = activelist.Copy()

	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/obj/effect/landmark/mob_spawner/mob_spawner = currentrun[currentrun.len]
		--currentrun.len

		if(!mob_spawner || QDELETED(mob_spawner))
			continue

		var/turf/im_here = get_turf(mob_spawner)
		if(!im_here)
			continue

		for(var/mob/living/mob_player in GLOB.player_list)
			if(QDELETED(mob_spawner))
				break

			var/turf/you_here = get_turf(mob_player)
			if(!you_here || you_here.z != im_here.z)
				continue

			var/dist = get_dist(im_here, you_here)
			if(dist > SPAWN_DISTANCE)
				continue

			if(dist <= FORCESPAWN_DISTANCE)
				new /obj/effect/temp_visual/bluespace_fissure(im_here)
				mob_spawner.spawn_and_destroy()
				break

			var/list/turf_list = getline(im_here, you_here)
			var/has_wall = FALSE
			if(length(turf_list) > 2)
				turf_list.Cut(1, 2)
				for(var/turf/turf in turf_list)
					if(turf.opacity)
						has_wall = TRUE
						break
			if(has_wall)
				continue

			if(dist <= SPAWN_DISTANCE)
				new /obj/effect/temp_visual/bluespace_fissure(im_here)
				mob_spawner.spawn_and_destroy()
				break

		if (MC_TICK_CHECK)
			return

#undef SPAWN_DISTANCE
#undef FORCESPAWN_DISTANCE
