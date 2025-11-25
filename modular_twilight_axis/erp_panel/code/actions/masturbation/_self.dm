/datum/sex_panel_action/self
	abstract_type = TRUE

	name = "Корневое действие на себя"

	can_knot = FALSE
	continous = TRUE
	interaction_timer = 2 SECONDS
	stamina_cost = 0.2

	check_incapacitated = TRUE
	check_same_tile = FALSE
	require_grab = FALSE
	required_grab_state = null

/datum/sex_panel_action/self/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	if(user != target)
		return FALSE

	return TRUE

/datum/sex_panel_action/self/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message = span_love("[user] оставляет под собой беспорядок")
	user.visible_message(message)
	return TRUE

/datum/sex_panel_action/self/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	SEND_SIGNAL(user, COMSIG_SEX_RECEIVE_ACTION, affects_self_arousal, affects_self_pain)
