#define MOUTH_MAX_UNITS 10
#define VAGINA_MAX_UNITS 20
#define ANUS_MAX_UNITS 30

/datum/sex_organ
	// Link to physical organ
	var/atom/movable/organ_link
	// how sensitive organ is - multiplayer to pleasure
	var/sensivity = 0
	// how painfull organ is - negative multiplayer to pleasure
	var/pain = 0
		// how sensitive organ max is - multiplayer to pleasure
	var/sensivity_max = 2
	// how painfull organ max is - negative multiplayer to pleasure
	var/pain_max = 2
	// object that currently this organ stuffed in
	var/datum/sex_organ/active_target = null
	// list of objects that use this organ
	var/list/datum/sex_organ/stuff_object  = list()
	// type of sex organ
	var/organ_type
	// list and amount of liquid inside
	var/datum/reagents/stored_liquid
	// amount of liquid can be stored inside
	var/stored_liquid_max = 0
	// active deflation timer
	var/deflation_timer_id = null 
	// reagent id that organ produce
	var/producing_reagent_id = null
	// reagent producing rate
	var/producing_reagent_rate = 0
	// ammount of reagent that ejects by events
	var/injection_amount = 0
	
/datum/sex_organ/New(atom/movable/organ)
	. = ..()
	organ_link = organ

	if(!stuff_object)
		stuff_object = list()

	if(stored_liquid_max)
		stored_liquid = new(stored_liquid_max)

	if(stored_liquid_max || (producing_reagent_id && producing_reagent_rate > 0))
		renew_timer(5 MINUTES)

/datum/sex_organ/proc/pleasure_bonus(datum/sex_organ/organ)
	return clamp(sensivity, 0, SEX_SENSITIVITY_MAX)  - clamp(pain, 0, SEX_PAIN_MAX)

/datum/sex_organ/proc/insert_organ(datum/sex_organ/organ)
	if(!stuff_object)
		stuff_object = list()
	if(!(organ in stuff_object))
		stuff_object += organ

/datum/sex_organ/proc/remove_organ(datum/sex_organ/organ)
	if(stuff_object && (organ in stuff_object))
		stuff_object -= organ

/datum/sex_organ/proc/add_reagent(datum/reagent/R, amount)
	if(!stored_liquid || amount <= 0) 
		return 0
	renew_timer(5 MINUTES)
	return stored_liquid.add_reagent(R.type, amount)

/datum/sex_organ/proc/remove_reagent(datum/reagent/R, amount)
	if(!stored_liquid || amount <= 0) 
		return 0
	return stored_liquid.remove_reagent(R.type, amount)

/datum/sex_organ/proc/drain_uniform(amount)
	if(!stored_liquid || !amount) 
		return 0
	var/total = stored_liquid.total_volume
	if(!total) 
		return 0

	var/factor = min(1, amount/total)
	var/removed = 0
	var/list/L = stored_liquid.reagent_list.Copy()

	for(var/datum/reagent/rr in L)
		var/take = rr.volume * factor
		if(take)
			removed += stored_liquid.remove_reagent(rr.type, take)

	return removed

/datum/sex_organ/proc/renew_timer(time)
	if(!stored_liquid)
		return FALSE

	if(deflation_timer_id)
		deltimer(deflation_timer_id)
		deflation_timer_id = null

	deflation_timer_id = addtimer(CALLBACK(src, PROC_REF(on_timer_end)), time, TIMER_STOPPABLE)
	return TRUE

/datum/sex_organ/proc/is_active()
	if(active_target)
		return TRUE
	if(stuff_object && length(stuff_object))
		return TRUE
	return FALSE

/datum/sex_organ/proc/bind_with(datum/sex_organ/other)
	if(active_target == other)
		return
	unbind()
	active_target = other
	if(other)
		if(!other.stuff_object)
			other.stuff_object = list()
		if(!(src in other.stuff_object))
			other.stuff_object += src

/datum/sex_organ/proc/unbind()
	if(active_target)
		if(active_target.stuff_object && (src in active_target.stuff_object))
			active_target.stuff_object -= src
	active_target = null

/datum/sex_organ/proc/can_start_active()
	return active_target == null

/datum/sex_organ/proc/start_active(datum/sex_organ/target)
	if(!can_start_active())
		return FALSE

	active_target = target
	target.insert_organ(src)
	return TRUE

/datum/sex_organ/proc/stop_active()
	if(active_target)
		active_target.remove_organ(src)
		active_target = null

/datum/sex_organ/proc/reset_after_sleep()
	sensivity = 0
	pain = 0

/datum/sex_organ/proc/get_owner()
	if(istype(organ_link, /obj/item/bodypart))
		var/obj/item/bodypart/BP = organ_link
		return BP.owner
	if(istype(organ_link, /obj/item/organ))
		var/obj/item/organ/O = organ_link
		return O.owner
	return null

/datum/sex_organ/proc/on_timer_end()
	deflation_timer_id = null

	if(!stored_liquid)
		return

	if(producing_reagent_id && producing_reagent_rate > 0)
		if(stored_liquid.total_volume < stored_liquid_max)
			produce_liquid(null, producing_reagent_rate)

	var/removed = 0
	if(stored_liquid.total_volume > 0)
		removed = drain_uniform(min(5, stored_liquid.total_volume))
		if(removed > 0 && (organ_type == SEX_ORGAN_VAGINA || organ_type == SEX_ORGAN_ANUS))
			var/mob/living/carbon/human/H = get_owner()
			if(istype(H))
				var/turf/T = get_turf(H)
				if(T)
					new /obj/effect/decal/cleanable/coom(T)

	if(stored_liquid.total_volume > 0 || (producing_reagent_id && producing_reagent_rate > 0))
		renew_timer(5 MINUTES)

/datum/sex_organ/proc/produce_liquid(datum/reagent/R, amount)
	if(!stored_liquid || amount <= 0)
		return 0

	if(!R && producing_reagent_id)
		R = GLOB.chemical_reagents_list[producing_reagent_id]

	if(!R)
		return 0

	renew_timer(5 MINUTES)
	return stored_liquid.add_reagent(R.type, amount)

/datum/sex_organ/proc/can_receive_liquid(amount = 1)
	if(!stored_liquid || stored_liquid_max <= 0)
		return FALSE

	if(stored_liquid.total_volume >= stored_liquid_max)
		return FALSE

	if(amount <= 0)
		return TRUE

	return (stored_liquid.total_volume + amount) <= stored_liquid_max

/datum/sex_organ/proc/is_valid_liquid_container(obj/item/I)
	if(!I)
		return FALSE

	if(istype(I, /obj/item/reagent_containers))
		return TRUE

	if(I.reagents)
		return TRUE

	return FALSE

/datum/sex_organ/proc/find_liquid_container()
	var/mob/living/carbon/human/H = get_owner()
	if(!H)
		return null

	if(H.held_items)
		for(var/obj/item/I in H.held_items)
			if(is_valid_liquid_container(I))
				return I

	var/turf/T = get_turf(H)
	if(!T)
		return null

	for(var/obj/item/I in T)
		if(is_valid_liquid_container(I))
			return I

	var/list/candidates = list()
	for(var/dir in list(NORTH, SOUTH, EAST, WEST))
		var/turf/NT = get_step(T, dir)
		if(!NT)
			continue
		for(var/obj/item/I in NT)
			if(is_valid_liquid_container(I))
				candidates += I

	if(length(candidates))
		return pick(candidates)

	return null

/datum/sex_organ/proc/inject_liquid()
	if(!stored_liquid || stored_liquid.total_volume <= 0)
		return 0

	var/amount = injection_amount
	if(!amount || amount <= 0)
		amount = 5

	var/moved = 0
	if(active_target && active_target.stored_liquid)
		if(active_target.can_receive_liquid(amount))
			moved = stored_liquid.trans_to(active_target.stored_liquid, amount)
			if(moved > 0)
				active_target.renew_timer(5 MINUTES)
				return moved

	var/obj/item/container = find_liquid_container()
	if(container)
		var/datum/reagents/R = container.reagents

		if(!R && istype(container, /obj/item/reagent_containers))
			var/obj/item/reagent_containers/RC = container
			if(RC.volume > 0)
				RC.create_reagents(RC.volume)
				R = RC.reagents

		if(R)
			moved = stored_liquid.trans_to(R, amount)
			if(moved > 0)
				return moved

	var/mob/living/carbon/human/H = get_owner()
	var/turf/T = H ? get_turf(H) : (organ_link ? get_turf(organ_link) : null)
	if(T)
		new /obj/effect/decal/cleanable/coom(T)
		moved = drain_uniform(amount)
		return moved

	moved = drain_uniform(amount)
	return moved

/datum/sex_organ/proc/tick_fluids()
	if(!stored_liquid)
		return

	if(producing_reagent_id && producing_reagent_rate > 0)
		if(stored_liquid.total_volume < stored_liquid_max)
			produce_liquid(null, producing_reagent_rate)

	if(stored_liquid.total_volume > 0)
		renew_timer(5 MINUTES)
