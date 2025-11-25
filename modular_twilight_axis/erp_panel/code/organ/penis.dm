/datum/sex_organ/penis
	organ_type = SEX_ORGAN_PENIS
	producing_reagent_id = /datum/reagent/erpjuice/cum
	producing_reagent_rate = 0
	injection_amount = 0
	stored_liquid_max = 0
	var/have_knot = FALSE

/datum/sex_organ/penis/New(obj/item/organ/penis/organ)
	. = ..()

	var/mob/living/carbon/human/owner = organ.owner
	if(!owner)
		return

	var/obj/item/organ/testicles/testicles = owner.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testicles)
		return

	producing_reagent_rate = testicles.ball_size
	stored_liquid_max = 5 * producing_reagent_rate

	if(stored_liquid)
		stored_liquid.maximum_volume = stored_liquid_max
	else
		stored_liquid = new(stored_liquid_max)

	injection_amount = organ.penis_size

	switch(organ.penis_type)
		if(PENIS_TYPE_KNOTTED, PENIS_TYPE_TAPERED_DOUBLE_KNOTTED, PENIS_TYPE_BARBED_KNOTTED)
			have_knot = TRUE
		else
			have_knot = FALSE

	if(have_knot && !owner.GetComponent(/datum/component/knotting))
		owner.AddComponent(/datum/component/knotting)
