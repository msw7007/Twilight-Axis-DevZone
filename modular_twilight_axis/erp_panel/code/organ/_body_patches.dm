/obj/item/organ
	var/datum/sex_organ/sex_organ

/obj/item/organ/breasts/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/breasts(src)

/obj/item/organ/penis
    var/manual_erection_override = FALSE

/obj/item/organ/penis/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/penis(src)

/obj/item/organ/penis/on_arousal_changed()
	if(manual_erection_override)
		return

	var/list/arousal_data = list()
	SEND_SIGNAL(owner, COMSIG_SEX_GET_AROUSAL, arousal_data)

	var/max_arousal = MAX_AROUSAL || 120
	var/current_arousal = arousal_data["arousal"] || 0
	var/arousal_percent = min(100, (current_arousal / max_arousal) * 100)

	var/new_state = ERECT_STATE_NONE
	switch(arousal_percent)
		if(0 to 10)
			new_state = ERECT_STATE_NONE
		if(11 to 35)
			new_state = ERECT_STATE_PARTIAL
		if(36 to 100)
			new_state = ERECT_STATE_HARD

	update_erect_state(new_state)

/obj/item/organ/penis/proc/set_manual_erect_state(state)
	manual_erection_override = TRUE
	erect_state = state
	if(owner)
		owner.update_body_parts(TRUE)

/obj/item/organ/penis/proc/disable_manual_erect()
	manual_erection_override = FALSE
	erect_state = null
	on_arousal_changed()

/obj/item/organ/vagina/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/vagina(src)

/obj/item/organ/tail/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/tail(src)

/obj/item/bodypart
	var/datum/sex_organ/sex_organ

/obj/item/bodypart/head/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/mouth(src)

/obj/item/bodypart/r_arm/attach_limb(mob/living/carbon/C)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/hand/right(src)
	
/obj/item/bodypart/l_arm/attach_limb(mob/living/carbon/C)
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/hand(src)

/mob/living/carbon/human
	var/datum/sex_organ/legs/legs_organ

/obj/item/bodypart/l_leg/attach_limb(mob/living/carbon/C)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(H)
		if(!H.legs_organ)
			H.legs_organ = new /datum/sex_organ/legs(src)
		sex_organ = H.legs_organ

/obj/item/bodypart/r_leg/attach_limb(mob/living/carbon/C)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(H)
		if(!H.legs_organ)
			H.legs_organ = new /datum/sex_organ/legs(src)
		sex_organ = H.legs_organ

/obj/item/bodypart/chest/Initialize()
	. = ..()
	if(!sex_organ)
		sex_organ = new /datum/sex_organ/anus(src)
