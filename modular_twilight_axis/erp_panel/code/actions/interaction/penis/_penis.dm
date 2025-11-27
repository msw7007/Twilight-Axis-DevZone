/datum/sex_panel_action/other/penis
	abstract_type = TRUE

	name = "Корневое действие членом"
	can_knot = TRUE
	required_init = SEX_ORGAN_PENIS
	stamina_cost = 0.3
	check_same_tile = TRUE
	var/active_knot = FALSE

/datum/sex_panel_action/other/penis/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message = span_love("[user] кончает ")
	return message

/datum/sex_panel_action/other/penis/proc/get_knot_action()
	var/datum/sex_session_tgui/S = session.session
	return (!S.has_knotted_penis || !S.do_knot_action) ? " по самый узел" : ""
