/datum/sex_organ/mouth
	organ_type = SEX_ORGAN_MOUTH
	stored_liquid_max = MOUTH_MAX_UNITS

/datum/sex_organ/mouth/add_reagent(datum/reagent/R, amount)
	. = ..()

	var/mob/living/carbon/human/H = get_owner()
	if(!istype(H) || !stored_liquid)
		return .

	if(stored_liquid.total_volume > 0)
		H.apply_status_effect(/datum/status_effect/mouth_full)

	return .
	
/datum/sex_organ/mouth/Destroy(force, ...)
	. = ..()
	var/mob/living/carbon/human/H = get_owner()
	H.remove_status_effect(/datum/status_effect/mouth_full)
