/datum/sex_organ/penis
	organ_type = SEX_ORGAN_PENIS
	var/datum/reagent/liquid_type = /datum/reagent/erpjuice/cum
	var/liquid_ammount = 0
	var/liquid_ammount_max = 0
	var/injection_amount = 0
	var/have_knot = FALSE

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
	
	switch(organ.penis_type)
		if(PENIS_TYPE_KNOTTED, PENIS_TYPE_TAPERED_DOUBLE_KNOTTED, PENIS_TYPE_BARBED_KNOTTED)
			have_knot = TRUE
		else
			have_knot = FALSE

	if(have_knot && !owner.GetComponent(/datum/component/knotting))
		owner.AddComponent(/datum/component/knotting)
