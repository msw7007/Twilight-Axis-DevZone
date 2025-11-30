/datum/sex_panel_action/other/penis/hemi
	abstract_type = TRUE
	name = "Корневое действие гемипенисом"

/datum/sex_panel_action/other/penis/hemi/proc/has_hemi_penis(mob/living/carbon/human/H)
	if(!H)
		return FALSE

	var/obj/item/organ/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!P)
		return FALSE

	var/datum/sex_organ/penis/PO = P.sex_organ
	if(!PO)
		return FALSE
		
	return (P.penis_type != PENIS_TYPE_TAPERED_DOUBLE && P.penis_type != PENIS_TYPE_TAPERED_DOUBLE_KNOTTED)

/datum/sex_panel_action/other/penis/hemi/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!..())
		return FALSE

	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/H = user
	if(!has_hemi_penis(H))
		return FALSE

	return TRUE
