/datum/sex_organ/breasts
	organ_type = SEX_ORGAN_BREASTS
	producing_reagent_id = /datum/reagent/consumable/milk
	stored_liquid_max = 75
	producing_reagent_rate = 0

/datum/sex_organ/breasts/New(obj/item/organ/breasts/organ)
	. = ..()
	stored_liquid_max = max(75, organ.breast_size * 100)
	producing_reagent_rate = organ.breast_size
	injection_amount = organ.breast_size
	stored_liquid.maximum_volume = stored_liquid_max

	if(producing_reagent_id && producing_reagent_rate > 0 && stored_liquid)
		start_production_timer()
