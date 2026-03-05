/turf/open/floor/rogue/dirt/nospawn

/turf/open/floor/rogue/grass/nospawn

/turf/open/floor/rogue/grasspurple
	name = "fungal 'grass'"
	desc = "Thin fungal strands rising from the ground. Spongey to walk on."
	icon_state = "grass_purple"
	layer = MID_TURF_LAYER
	footstep = FOOTSTEP_GRASS
	barefootstep = FOOTSTEP_SOFT_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	tiled_dirt = FALSE
	icon = 'modular_twilight_axis/icons/turf/roguefloor.dmi'
	landsound = 'sound/foley/jumpland/grassland.wav'
	slowdown = 0
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/turf/open/floor/rogue/grassred,
						/turf/open/floor/rogue/grassyel,
						/turf/open/floor/rogue/grasscold,
						/turf/open/floor/rogue/snowpatchy,
						/turf/open/floor/rogue/snow,
						/turf/open/floor/rogue/snowrough,)
	neighborlay = "grass_purpleedge"

/turf/open/floor/rogue/grasspurple/Initialize()
	dir = pick(GLOB.cardinals)
	. = ..()

/turf/open/floor/rogue/grasspurple/cardinal_smooth(adjacencies)
	roguesmooth(adjacencies)

/turf/open/floor/rogue/grassgrey
	name = "dead grass"
	desc = "Pale, like a bloated corpse."
	icon_state = "grass_grey"
	layer = MID_TURF_LAYER
	footstep = FOOTSTEP_GRASS
	barefootstep = FOOTSTEP_SOFT_BAREFOOT
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	tiled_dirt = FALSE
	icon = 'modular_twilight_axis/icons/turf/roguefloor.dmi'
	landsound = 'sound/foley/jumpland/grassland.wav'
	slowdown = 0
	smooth = SMOOTH_TRUE
	canSmoothWith = list(/turf/open/floor/rogue/grassred,
						/turf/open/floor/rogue/grassyel,
						/turf/open/floor/rogue/grasscold,
						/turf/open/floor/rogue/snowpatchy,
						/turf/open/floor/rogue/snow,
						/turf/open/floor/rogue/snowrough,)
	neighborlay = "grass_greyedge"

/turf/open/floor/rogue/grassgrey/Initialize()
	dir = pick(GLOB.cardinals)
	. = ..()

/turf/open/floor/rogue/grassgrey/cardinal_smooth(adjacencies)
	roguesmooth(adjacencies)

/turf/open/floor/rogue/tile/bath
	icon = 'modular_twilight_axis/icons/turf/roguefloor.dmi'

/turf/open/abyss
	name = "abyss"
	desc = "Staring into it makes your stomach drop."
	icon = 'modular_twilight_axis/icons/turf/roguefloor.dmi'
	icon_state = "undervoid3"
	density = FALSE
	opacity = FALSE

	var/landmark_tag = "abyss_return"
	var/damage = 20
	var/cooldown_ds = 10  // 1 сек, если world.tick_lag=1

/turf/open/abyss/Entered(atom/movable/AM, atom/oldloc)
	. = ..()
	var/mob/living/L = AM
	if(!istype(L))
		return

	if(L.stat == DEAD)
		return

	if(L.get_variable("abyss_cd") && L.get_variable("abyss_cd") > world.time)
		return
	
	L.set_variable("abyss_cd", world.time + cooldown_ds)
	L.apply_damage(damage, BRUTE)
	var/turf/target = pick_landmark_turf(landmark_tag)
	if(target)
		L.forceMove(target)

/turf/open/abyss/sky
	name = "sky"
	icon_state = "bluespace"
	landmark_tag = "sky_fall_to_ground"

/turf/open/dark_path
	name = "path"
	desc = "Something is here... if you know how to look."
	icon = 'modular_twilight_axis/icons/turf/roguefloor.dmi'
	icon_state = "undervoid3"

	var/reveal_count = 0
	var/revealed_state = "arcynewall"

/turf/open/dark_path/proc/set_revealed(enable)
	if(enable)
		reveal_count++
	else
		reveal_count = max(0, reveal_count - 1)

	var/new_state = (reveal_count > 0) ? revealed_state : initial(icon_state)
	if(icon_state != new_state)
		icon_state = new_state
		update_icon()

/obj/item/flashlight/flare/torch/lantern/bronzelamptern
	var/list/last_revealed

/obj/item/flashlight/flare/torch/lantern/bronzelamptern/proc/update_bronze_reveal()
	var/turf/center = get_turf(src)
	if(!center)
		return

	var/list/now = list()

	if(on)
		for(var/turf/T in range(light_outer_range, center))
			if(istype(T, /turf/open/dark_path))
				now += T

	if(last_revealed)
		for(var/turf/open/dark_path/P in last_revealed)
			if(!(P in now))
				P.set_revealed(FALSE)

	for(var/turf/open/dark_path/P in now)
		if(!last_revealed || !(P in last_revealed))
			P.set_revealed(TRUE)

	last_revealed = now

/obj/item/flashlight/flare/torch/lantern/bronzelamptern/attack_self(mob/user)
	. = ..()
	update_bronze_reveal()

/obj/item/flashlight/flare/torch/lantern/bronzelamptern/Moved(atom/oldloc, movement_dir, forced, list/knownblockers)
	. = ..()
	if(on)
		update_bronze_reveal()

/obj/item/flashlight/flare/torch/lantern/bronzelamptern/Destroy()
	if(last_revealed)
		for(var/turf/open/dark_path/P in last_revealed)
			P.set_revealed(FALSE)
	return ..()
