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
