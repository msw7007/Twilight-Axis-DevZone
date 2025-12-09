/datum/sex_panel_action/other/penis/butt_job
	abstract_type = FALSE

	name = "Использовать ягодицы"
	required_target = SEX_ORGAN_ANUS
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	can_knot = FALSE
	
	affects_self_arousal	= 0.03
	affects_arousal			= 0.12
	affects_self_pain		= 0.01
	affects_pain			= 0.03

	actor_sex_hearts = TRUE
	actor_make_sound = TRUE
	actor_do_onomatopoeia = TRUE

	message_on_start   = "{actor} {pose} приставляет свой член между ягодиц {partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} водит членом между ягодиц {partner}."
	message_on_finish  = "{actor} убирает член от попки {partner}."
	message_on_climax_actor  = "{actor} кончает на ягодицы {partner}."
	message_on_climax_target = "{partner} кончает под себя!"

/datum/sex_panel_action/other/penis/butt_job/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член между ягодиц [target]."

/datum/sex_panel_action/other/penis/butt_job/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	. = ..()
	return "onto"
