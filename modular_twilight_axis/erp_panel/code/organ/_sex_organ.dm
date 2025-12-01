#define MOUTH_MAX_UNITS 10
#define VAGINA_MAX_UNITS 20
#define ANUS_MAX_UNITS 30

/datum/sex_organ
	// Link to physical organ
	var/atom/movable/organ_link
	// how sensitive organ is - multiplier to pleasure
	var/sensivity = 0
	// how painful organ is - negative multiplier to pleasure
	var/pain = 0
	// max sensitivity
	var/sensivity_max = 2
	// max pain
	var/pain_max = 2
	// object that currently this organ stuffed in
	var/datum/sex_organ/active_target = null
	// list of objects that use this organ
	var/list/datum/sex_organ/stuff_object = list()
	// type of sex organ
	var/organ_type
	// liquids
	var/datum/reagents/stored_liquid
	var/stored_liquid_max = 0
	// timers
	var/deflation_timer_id = null
	var/production_timer_id = null
	// reagent id that organ produces over time
	var/producing_reagent_id = null
	// production rate per tick
	var/producing_reagent_rate = 0
	// amount of reagent that ejects by events
	var/injection_amount = 0
	// intervals
	var/production_interval = 5 SECONDS
	var/drain_interval = 5 MINUTES


/datum/sex_organ/New(atom/movable/organ)
	. = ..()
	organ_link = organ

	if(!stuff_object)
		stuff_object = list()

	if(stored_liquid_max)
		stored_liquid = new(stored_liquid_max)

/datum/sex_organ/Destroy()
	if(deflation_timer_id)
		deltimer(deflation_timer_id)
	deflation_timer_id = null

	if(production_timer_id)
		deltimer(production_timer_id)
	production_timer_id = null

	return ..()

/datum/sex_organ/proc/pleasure_bonus(datum/sex_organ/organ)
	return clamp(sensivity, 0, SEX_SENSITIVITY_MAX) - clamp(pain, 0, SEX_PAIN_MAX)

/datum/sex_organ/proc/has_storage()
	return stored_liquid && stored_liquid_max > 0

/datum/sex_organ/proc/total_volume()
	if(!stored_liquid)
		return 0
	return stored_liquid.total_volume

/datum/sex_organ/proc/add_reagent(datum/reagent/R, amount)
	if(!has_storage() || amount <= 0 || !R)
		return 0
	var/added = stored_liquid.add_reagent(R.type, amount)
	if(added > 0)
		renew_timer(drain_interval)
	return added

/datum/sex_organ/proc/remove_reagent(datum/reagent/R, amount)
	if(!has_storage() || amount <= 0 || !R)
		return 0
	return stored_liquid.remove_reagent(R.type, amount)

/datum/sex_organ/proc/drain_uniform(amount)
	if(!has_storage() || amount <= 0)
		return 0

	var/total = total_volume()
	if(total <= 0)
		return 0

	var/factor = min(1, amount / total)
	var/removed = 0
	var/list/L = stored_liquid.reagent_list.Copy()

	for(var/datum/reagent/rr in L)
		var/take = rr.volume * factor
		if(take > 0)
			removed += stored_liquid.remove_reagent(rr.type, take)

	return removed

/datum/sex_organ/proc/can_receive_liquid(amount = 1)
	if(!has_storage())
		return FALSE

	if(total_volume() >= stored_liquid_max)
		return FALSE

	if(amount <= 0)
		return TRUE

	return (total_volume() + amount) <= stored_liquid_max

/datum/sex_organ/proc/renew_timer(time)
	if(!has_storage())
		return FALSE

	if(deflation_timer_id)
		deltimer(deflation_timer_id)
	deflation_timer_id = addtimer(CALLBACK(src, PROC_REF(on_timer_end)), time, TIMER_STOPPABLE)
	return TRUE

/datum/sex_organ/proc/start_production_timer()
	if(production_timer_id)
		return FALSE
	if(!has_storage())
		return FALSE
	if(!producing_reagent_id || producing_reagent_rate <= 0)
		return FALSE

	production_timer_id = addtimer(
		CALLBACK(src, PROC_REF(on_production_tick)),
		production_interval,
		TIMER_STOPPABLE,
	)
	return TRUE

/datum/sex_organ/proc/on_production_tick()
	production_timer_id = null

	if(!has_storage())
		return
	if(!producing_reagent_id || producing_reagent_rate <= 0)
		return

	if(total_volume() < stored_liquid_max)
		produce_liquid(null, producing_reagent_rate)

	if(has_storage() && producing_reagent_id && producing_reagent_rate > 0)
		start_production_timer()

/datum/sex_organ/proc/insert_organ(datum/sex_organ/organ)
	if(!stuff_object)
		stuff_object = list()
	if(!(organ in stuff_object))
		stuff_object += organ

/datum/sex_organ/proc/remove_organ(datum/sex_organ/organ)
	if(stuff_object && (organ in stuff_object))
		stuff_object -= organ

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

	if(!has_storage())
		return

	var/current = total_volume()
	if(current <= 0)
		return

	var/removed = drain_uniform(min(5, current))
	if(removed <= 0)
		return

	if(organ_type == SEX_ORGAN_VAGINA || organ_type == SEX_ORGAN_ANUS)
		var/mob/living/carbon/human/H = get_owner()
		if(istype(H))
			var/turf/T = get_turf(H)
			if(T)
				new /obj/effect/decal/cleanable/coom(T)

	if(total_volume() > 0)
		renew_timer(drain_interval)

/datum/sex_organ/proc/produce_liquid(datum/reagent/R, amount)
	if(!has_storage() || amount <= 0)
		return 0

	if(!R && producing_reagent_id)
		R = GLOB.chemical_reagents_list[producing_reagent_id]

	if(!R)
		return 0

	// вот тут подключаем наш множитель
	var/mult = get_production_multiplier()
	if(mult <= 0)
		return 0

	amount *= mult

	var/added = stored_liquid.add_reagent(R.type, amount)
	if(added > 0)
		renew_timer(drain_interval)
	return added

/datum/sex_organ/proc/is_valid_liquid_container(obj/item/I)
	if(!I)
		return FALSE

	if(istype(I, /obj/item/reagent_containers))
		return TRUE

	if(I.reagents)
		return TRUE

	return FALSE

/datum/sex_organ/proc/find_liquid_container(mob/living/carbon/human/preferred_holder = null)
	if(preferred_holder)
		var/obj/item/I = preferred_holder.get_active_held_item()
		if(I && is_valid_liquid_container(I))
			return I

		I = preferred_holder.get_inactive_held_item()
		if(I && is_valid_liquid_container(I))
			return I

		for(var/obj/item/J in preferred_holder.contents)
			if(is_valid_liquid_container(J))
				return J

	var/mob/living/carbon/human/H = get_owner()
	if(!H)
		return null

	if(H.held_items)
		for(var/obj/item/K in H.held_items)
			if(is_valid_liquid_container(K))
				return K

	var/turf/T = get_turf(H)
	if(T)
		for(var/obj/item/L in T)
			if(is_valid_liquid_container(L))
				return L

	if(T)
		for(var/dir in list(NORTH, SOUTH, EAST, WEST))
			var/turf/NT = get_step(T, dir)
			if(!NT) continue
			for(var/obj/item/M in NT)
				if(is_valid_liquid_container(M))
					return M

	return null

/datum/sex_organ/proc/inject_liquid(obj/item/container = null, mob/living/carbon/human/preferred_holder = null)
	if(!has_storage() || total_volume() <= 0)
		return 0

	var/amount = injection_amount
	if(!amount || amount <= 0)
		amount = 5

	var/moved = 0
	var/mode = INJECT_MODE_NONE

	if(active_target && active_target.has_storage())
		if(active_target.can_receive_liquid(amount))
			moved = stored_liquid.trans_to(active_target.stored_liquid, amount)
			if(moved > 0)
				active_target.renew_timer(drain_interval)
				mode = INJECT_MODE_ORGAN
				on_after_inject(mode, moved, get_owner(), active_target, null, null)
				return moved

	if(container && is_valid_liquid_container(container))
		moved = stored_liquid.trans_to(container.reagents, amount)
		if(moved > 0)
			mode = INJECT_MODE_CONTAINER
			on_after_inject(mode, moved, get_owner(), active_target, container, null)
			return moved

	var/obj/item/user_cont = find_liquid_container(preferred_holder)
	if(user_cont && is_valid_liquid_container(user_cont))
		moved = stored_liquid.trans_to(user_cont.reagents, amount)
		if(moved > 0)
			mode = INJECT_MODE_CONTAINER
			on_after_inject(mode, moved, get_owner(), active_target, user_cont, null)
			return moved

	var/mob/living/carbon/human/H = get_owner()
	var/turf/T = H ? get_turf(H) : (organ_link ? get_turf(organ_link) : null)
	if(T)
		new /obj/effect/decal/cleanable/coom(T)
		moved = drain_uniform(amount)
		if(moved > 0)
			mode = INJECT_MODE_GROUND
			on_after_inject(mode, moved, H, active_target, null, T)
			return moved

	moved = drain_uniform(amount)
	if(moved > 0)
		on_after_inject(mode, moved, H, active_target, null, T)
	return moved

/datum/sex_organ/proc/on_after_inject(mode, moved, mob/living/carbon/human/owner, datum/sex_organ/target_org, obj/item/container, turf/T, context)
	if(moved <= 0)
		return

	if(mode == INJECT_MODE_ORGAN && target_org)
		var/mob/living/carbon/human/target = target_org.get_owner()

		if(target && target_org.organ_type == SEX_ORGAN_MOUTH)
			var/datum/reagents/R = stored_liquid
			if(R && R.total_volume)
				target.reagents.add_reagent(producing_reagent_id, moved)

	return

/datum/sex_organ/proc/get_arousal_data()
	var/mob/living/carbon/human/H = get_owner()	
	if(!H || !ismob(H))
		return null

	var/list/data = list()
	SEND_SIGNAL(H, COMSIG_SEX_GET_AROUSAL, data)
	if(!length(data))
		return null

	return data

/datum/sex_organ/proc/get_production_multiplier()
	var/mult = 1.0

	var/list/ad = get_arousal_data()
	if(!ad)
		return mult

	if(!ad["is_spent"])
		return mult

	switch(organ_type)
		if(SEX_ORGAN_PENIS)
			return PENIS_SPENT_PROD_MULT
		if(SEX_ORGAN_BREASTS)
			return BREAST_SPENT_PROD_MULT

	return mult
