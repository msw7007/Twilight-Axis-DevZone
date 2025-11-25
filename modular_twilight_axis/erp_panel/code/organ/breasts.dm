/datum/sex_organ/breasts
	organ_type = SEX_ORGAN_BREASTS
	var/datum/reagent/liquid_type = /datum/reagent/erpjuice

/datum/sex_organ/breasts/New(obj/item/organ/breasts/organ)
	. = ..()
	stored_liquid_max = organ.milk_max
