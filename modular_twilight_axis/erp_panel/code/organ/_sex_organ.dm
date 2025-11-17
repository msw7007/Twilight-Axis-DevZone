#define MOUTH_MAX_UNITS 10
#define VAGINA_MAX_UNITS 20
#define ANUS_MAX_UNITS 30

/datum/sex_organ
	// Link to physical organ
	var/obj/item/organ/organ_link
	// how sensitive organ is - multiplayer to pleasure
	var/sensivity = 0
	// how painfull organ is - negative multiplayer to pleasure
	var/pain = 0
	// object that currently "uses" this organ
	var/list/datum/sex_organ/stuff_object
	// type of sex organ
	var/organ_type
	// list and amount of liquid inside
	var/datum/reagents/stored_liquid
	// amount of liquid can be stored inside
	var/stored_liquid_max = 0
	// active deflation timer
	var/deflation_timer_id = null 
	
/datum/sex_organ/New(obj/item/organ/organ)
	. = ..()
	organ_link = organ
	if(stored_liquid_max)
		stored_liquid = new(stored_liquid_max)

/datum/sex_organ/proc/pleasure_bonus(datum/sex_organ/organ)
	return sensivity - pain

/datum/sex_organ/proc/insert_organ(datum/sex_organ/organ)
	stuff_object += organ

/datum/sex_organ/proc/remove_organ(datum/sex_organ/organ)
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
	var/obj/item/organ/testicles/testicles = owner.getorganslot(ORGAN_SLOT_TESTICLES)
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
