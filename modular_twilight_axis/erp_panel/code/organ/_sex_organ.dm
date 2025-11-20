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
	
/datum/sex_organ/New(atom/movable/organ)
	. = ..()
	organ_link = organ

	if(!stuff_object)
		stuff_object = list()

	if(stored_liquid_max)
		stored_liquid = new(stored_liquid_max)

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

/datum/sex_organ/proc/on_timer_end()
	deflation_timer_id = null

	drain_uniform(5)
	renew_timer(5 MINUTES)

/datum/sex_organ/mouth
	organ_type = SEX_ORGAN_MOUTH
	stored_liquid_max = MOUTH_MAX_UNITS

/datum/sex_organ/mouth/add_reagent(datum/reagent/R, amount)
	. = ..()
	//Добавить мудлет - нажал и выпил. Что-то сказал - вылил

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













/datum/sex_organ/hand
	organ_type = SEX_ORGAN_HANDS
	stored_liquid_max = 0

/datum/sex_organ/hand/right

/datum/sex_organ/penis
	organ_type = SEX_ORGAN_PENIS
	var/datum/reagent/liquid_type = /datum/reagent/erpjuice/cum
	var/liquid_ammount = 0
	var/liquid_ammount_max = 0
	var/injection_amount = 0

/datum/sex_organ/penis/New(obj/item/organ/penis/organ)
	. = ..()
	var/mob/living/carbon/human/owner = organ.owner
	if(!owner)
		return

	var/obj/item/organ/testicles/testicles = owner.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testicles)
		return
		
	liquid_ammount = 5 * testicles.ball_size
	liquid_ammount_max = 10 * testicles.ball_size
	injection_amount = organ.penis_size

/datum/sex_organ/vagina
	organ_type = SEX_ORGAN_VAGINA
	stored_liquid_max = VAGINA_MAX_UNITS

/datum/sex_organ/anus
	organ_type = SEX_ORGAN_ANUS
	stored_liquid_max = ANUS_MAX_UNITS

/datum/sex_organ/breasts
	organ_type = SEX_ORGAN_BREASTS
	stored_liquid_max = 0
	var/stored_milk = 0
	var/max_milk = 0

/datum/sex_organ/breasts/New(obj/item/organ/breasts/organ)
	. = ..()
	stored_milk = organ.milk_stored
	max_milk = organ.milk_max

/datum/sex_organ/tail
	organ_type = SEX_ORGAN_TAIL
	stored_liquid_max = 0

/datum/sex_organ/tail/New(obj/item/organ/tail/organ)
	. = ..()

/datum/sex_organ/legs
	organ_type = SEX_ORGAN_LEGS
	stored_liquid_max = 0
