/datum/sex_panel_action/other/penis/tea_bag
	abstract_type = FALSE

	name = "Чайный пакетик"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_init = BODY_ZONE_PRECISE_GROIN
	can_knot = FALSE

	affects_self_arousal	= 0.12
	affects_arousal			= 0.06
	affects_self_pain		= 0
	affects_pain			= 0

	actor_sex_hearts = TRUE
	target_sex_hearts = TRUE
	actor_make_sound = TRUE
	target_make_sound = TRUE
	actor_suck_sound = TRUE
	target_suck_sound = TRUE
	actor_make_fingering_sound = TRUE
	target_make_fingering_sound = TRUE
	actor_do_onomatopoeia = TRUE
	target_do_onomatopoeia = TRUE
	actor_do_thrust = TRUE
	target_do_thrust = TRUE
	can_be_custom = FALSE

	message_on_start   = "{actor} {pose}, {force} и {speed} приставляет тестикулы к лицу {dullahan?отделенной головы :}{partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} водит тестикулам по лицу {dullahan?отделенной головы :}{partner}."
	message_on_finish  = "{actor} убирает тестикулы от лица {dullahan?отделенной головы :}{partner}."
	message_on_climax_actor  = "{actor} кончает на лицо  {dullahan?отделенной головы :}{partner}."
	message_on_climax_target = "{partner} кончает под себя."

/datum/sex_panel_action/other/penis/tea_bag/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	if(!user)
		return

	var/obj/item/organ/testicles/testicles = user.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testicles)
		return

/datum/sex_panel_action/other/penis/tea_bag/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	. = ..()
	return "onto"
