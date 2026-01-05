/obj/item/artillery_powder_keg
	name = "keg of black powder"
	desc = "A heavy keg. The powder quality varies by batch."
	//icon = 'icons/obj/artillery.dmi'
	//icon_state = "powder_keg"

	var/powder_quality = 1.0
	var/powder_moisture = 0.0
	var/measures_left = 50

	/// guard
	var/detonated = FALSE

	/// tune: threshold for fire/heat detonation (in K if your code uses Kelvin)
	var/detonation_temp = 500

/obj/item/artillery_powder_keg/Initialize(mapload)
	. = ..()
	powder_quality = rand(90, 110) / 100
	powder_moisture = rand(0, 25) / 100
	measures_left = rand(40, 70)

/obj/item/artillery_powder_keg/proc/take_measures(amount)
	if(amount <= 0)
		return list(powder_quality, powder_moisture, 0)

	var/take = min(amount, measures_left)
	measures_left -= take
	return list(powder_quality, powder_moisture, take)

/// --- ignition hooks ---

/obj/item/artillery_powder_keg/fire_act(exposed_temperature, exposed_volume)
	. = ..()
	if(detonated)
		return
	if(exposed_temperature >= detonation_temp)
		detonate(null)

/obj/item/artillery_powder_keg/temperature_expose(exposed_temperature, exposed_volume)
	. = ..()
	if(detonated)
		return
	if(exposed_temperature >= detonation_temp)
		detonate(null)

/// If your codebase has "is_hot()" helpers, replace this.
/// INTEGRATION: adjust list to your ignition sources.
/proc/is_ignition_source(obj/item/I)
	if(!I)
		return FALSE

	// Lighter / match / torch — add your paths
	if(istype(I, /obj/item/flashlight/flare/torch))
		return TRUE

	// Generic "hot item" fallback if exists
	if(hascall(I, "is_hot") && call(I, "is_hot")())
		return TRUE

	return FALSE

/obj/item/artillery_powder_keg/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(detonated)
		return
	if(is_ignition_source(I))
		detonate(user)

/// --- detonation ---

/obj/item/artillery_powder_keg/proc/detonate(mob/user)
	if(detonated)
		return
	detonated = TRUE

	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return

	visible_message(span_danger("[src] detonates!"))

	// Power scales with amount + quality, reduced by moisture.
	// Tune freely.
	var/base = measures_left / 50 // ~0.8..1.4 for 40..70
	var/power = base * powder_quality
	power *= (1.0 - (powder_moisture * 0.6)) // wet powder dampens

	// Clamp so it doesn’t become silly
	power = clamp(power, 0.4, 2.0)

	// INTEGRATION: replace with your explosion wrapper if needed
	do_artillery_explosion(T, power)

	qdel(src)
