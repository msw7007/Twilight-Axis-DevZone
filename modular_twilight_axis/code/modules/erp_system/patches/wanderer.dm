// ============================================================
// wanderer.dm
// Martial combat-style for combo_core.
// Base attacks are combo inputs: punch / kick / grab.
// Stance is always active and changes finisher behavior.
// Buttons go through COMSIG_COMBO_CORE_REGISTER_INPUT.
// Base attacks are registered through COMSIG_ATTACK_TRY_CONSUME.
// ============================================================

#define WANDERER_COMBO_WINDOW            (7 SECONDS)
#define WANDERER_MAX_HISTORY             5

#define WANDERER_MAX_COMBO_STACKS        5
#define WANDERER_MAX_AROUSAL_STACKS      10

#define WANDERER_COMBO_DMG_PER_STACK     0.10
#define WANDERER_AROUSAL_DMG_PER_STACK   0.05

#define WANDERER_KICK_MIN_RECOVERY       (0.5 SECONDS)

#define WANDERER_INPUT_PUNCH             1
#define WANDERER_INPUT_KICK              2
#define WANDERER_INPUT_GRAB              3

#define WANDERER_STANCE_PROC             1
#define WANDERER_STANCE_PRECISE          2

#define WANDERER_BUTTON_SWITCH_STANCE    101
#define WANDERER_BUTTON_EROTIC_EMBRACE   102

#define WANDERER_COMBO_ICON_FILE         'modular_twilight_axis/icons/roguetown/misc/roninspells.dmi'
#define WANDERER_EMBRACE_TRAIT_SOURCE    "wanderer_embrace"

// ------------------------------------------------------------
// helpers
// ------------------------------------------------------------

/proc/wanderer_get_component(mob/living/user)
	if(!isliving(user))
		return null

	var/datum/component/combo_core/wanderer/C = user.GetComponent(/datum/component/combo_core/wanderer)
	if(!C)
		C = user.AddComponent(/datum/component/combo_core/wanderer)
	return C

/proc/wanderer_get_component_safe(mob/living/user)
	if(!isliving(user))
		return null

	return user.GetComponent(/datum/component/combo_core/wanderer)

/proc/wanderer_get_kick_offbalance_duration(mob/living/user, base_duration = 3 SECONDS)
	if(!isliving(user))
		return base_duration

	var/datum/component/combo_core/wanderer/C = wanderer_get_component_safe(user)
	if(!C)
		return base_duration

	return C.GetKickOffbalanceDuration(base_duration)

// ============================================================
// Component
// ============================================================

/datum/component/combo_core/wanderer
	parent_type = /datum/component/combo_core/combat_style
	dupe_mode = COMPONENT_DUPE_UNIQUE

	/// Current stance is always active.
	var/current_stance = WANDERER_STANCE_PROC

	/// Play / prep mode.
	var/erotic_embrace_enabled = FALSE

	/// +1 per successful base hit, spent on finisher.
	var/combo_stacks = 0
	var/max_combo_stacks = WANDERER_MAX_COMBO_STACKS

	/// Direct damage resource.
	var/arousal_stacks = 0
	var/max_arousal_stacks = WANDERER_MAX_AROUSAL_STACKS

	/// Last successful resolved base action.
	var/last_action_success = FALSE
	var/last_action_skill = 0
	var/last_action_zone = BODY_ZONE_CHEST
	var/mob/living/last_action_target = null

	var/last_finisher_success = FALSE
	var/last_matched_rule = null

	var/list/granted_spells = list()
	var/spells_granted = FALSE

/datum/component/combo_core/wanderer/Initialize(_combo_window, _max_history)
	. = ..(_combo_window || WANDERER_COMBO_WINDOW, _max_history || WANDERER_MAX_HISTORY)
	if(. == COMPONENT_INCOMPATIBLE)
		return .

	StripExternalStyleSpells()
	GrantSpells()
	OnAttachApplyHiddenStats()

	RegisterSignal(owner, COMSIG_COMBO_CORE_REGISTER_INPUT, PROC_REF(_sig_register_input), override = TRUE)
	RegisterSignal(owner, COMSIG_ATTACK_TRY_CONSUME, PROC_REF(_sig_try_consume))
	RegisterSignal(owner, COMSIG_PARENT_EXAMINE, PROC_REF(_sig_examined))

	RefreshHiddenStats()
	_balloon_stance()
	return .

/datum/component/combo_core/wanderer/Destroy(force)
	if(owner)
		UnregisterSignal(owner, COMSIG_COMBO_CORE_REGISTER_INPUT)
		UnregisterSignal(owner, COMSIG_ATTACK_TRY_CONSUME)
		UnregisterSignal(owner, COMSIG_PARENT_EXAMINE)

		REMOVE_TRAIT(owner, TRAIT_DODGEEXPERT, WANDERER_EMBRACE_TRAIT_SOURCE)

		OnDetachClearHiddenStats()
		RevokeSpells()

	owner = null
	granted_spells = null
	return ..()

// ------------------------------------------------------------
// combo_core overrides
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/DefineRules()

	// ======================
	// 2-hit combos
	// ======================

	RegisterRule("heel_tap",      list(WANDERER_INPUT_KICK,  WANDERER_INPUT_PUNCH), 30, PROC_REF(_cb_combo))
	RegisterRule("needle_thread", list(WANDERER_INPUT_PUNCH, WANDERER_INPUT_GRAB),  35, PROC_REF(_cb_combo))
	RegisterRule("double_strike", list(WANDERER_INPUT_PUNCH, WANDERER_INPUT_PUNCH), 25, PROC_REF(_cb_combo))
	RegisterRule("low_pressure",  list(WANDERER_INPUT_KICK,  WANDERER_INPUT_KICK),  25, PROC_REF(_cb_combo))

	// ======================
	// 3-hit combos
	// ======================

	RegisterRule("iron_bloom",    list(WANDERER_INPUT_PUNCH, WANDERER_INPUT_PUNCH, WANDERER_INPUT_KICK), 50, PROC_REF(_cb_combo))
	RegisterRule("leg_hook",      list(WANDERER_INPUT_KICK,  WANDERER_INPUT_PUNCH, WANDERER_INPUT_GRAB), 55, PROC_REF(_cb_combo))
	RegisterRule("triple_strike", list(WANDERER_INPUT_PUNCH, WANDERER_INPUT_PUNCH, WANDERER_INPUT_PUNCH), 45, PROC_REF(_cb_combo))
	RegisterRule("breaker_kicks", list(WANDERER_INPUT_KICK,  WANDERER_INPUT_KICK,  WANDERER_INPUT_KICK),  45, PROC_REF(_cb_combo))
	RegisterRule("grip_break",    list(WANDERER_INPUT_GRAB,  WANDERER_INPUT_GRAB,  WANDERER_INPUT_PUNCH), 40, PROC_REF(_cb_combo))
	RegisterRule("body_lock",     list(WANDERER_INPUT_GRAB,  WANDERER_INPUT_GRAB,  WANDERER_INPUT_KICK),  40, PROC_REF(_cb_combo))

	// ======================
	// 4-hit combos
	// ======================

	RegisterRule("gatebreaker", list(WANDERER_INPUT_PUNCH, WANDERER_INPUT_KICK, WANDERER_INPUT_GRAB, WANDERER_INPUT_KICK), 70, PROC_REF(_cb_combo))
	RegisterRule("crane_fold",  list(WANDERER_INPUT_KICK,  WANDERER_INPUT_PUNCH, WANDERER_INPUT_GRAB, WANDERER_INPUT_KICK), 75, PROC_REF(_cb_combo))

/datum/component/combo_core/wanderer/OnHistoryChanged()
	return

/datum/component/combo_core/wanderer/OnHistoryCleared(reason)
	last_matched_rule = null
	last_finisher_success = FALSE

/datum/component/combo_core/wanderer/OnComboExpired()
	last_matched_rule = null
	last_finisher_success = FALSE

/datum/component/combo_core/wanderer/OnComboMatched(rule_id, mob/living/target, zone)
	last_finisher_success = TRUE
	last_matched_rule = rule_id

/datum/component/combo_core/wanderer/ConsumeOnCombo(rule_id)
	ClearHistory("combo")
	ResetComboStacks()

// ------------------------------------------------------------
// spells / strip old style abilities
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/StripExternalStyleSpells()
	if(!owner?.mind)
		return

	var/list/current = owner.mind.spell_list?.Copy()
	if(!length(current))
		return

	for(var/obj/effect/proc_holder/spell/S as anything in current)
		if(!S)
			continue

		if(istype(S, /obj/effect/proc_holder/spell/self/wanderer))
			owner.mind.RemoveSpell(S)
			continue

		if(istype(S, /obj/effect/proc_holder/spell/self/soundbreaker))
			owner.mind.RemoveSpell(S)
			continue

		if(istype(S, /obj/effect/proc_holder/spell/self/ronin))
			owner.mind.RemoveSpell(S)
			continue

/datum/component/combo_core/wanderer/proc/GrantSpells()
	if(spells_granted || !owner?.mind)
		return

	var/mob/living/L = owner
	RevokeSpells()

	var/list/paths = list(
		/obj/effect/proc_holder/spell/self/wanderer/switch_stance,
		/obj/effect/proc_holder/spell/self/wanderer/erotic_embrace,
		/obj/effect/proc_holder/spell/invoked/massage
	)

	for(var/path in paths)
		var/obj/effect/proc_holder/spell/S = new path
		L.mind.AddSpell(S)
		granted_spells += S

	spells_granted = TRUE

/datum/component/combo_core/wanderer/proc/RevokeSpells()
	if(!owner)
		return

	if(!length(granted_spells))
		spells_granted = FALSE
		return

	if(owner.mind)
		for(var/obj/effect/proc_holder/spell/S as anything in granted_spells)
			if(S)
				owner.mind.RemoveSpell(S)
	else
		for(var/obj/effect/proc_holder/spell/S as anything in granted_spells)
			if(S)
				qdel(S)

	granted_spells = list()
	spells_granted = FALSE

// ------------------------------------------------------------
// hidden stats hooks
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/OnAttachApplyHiddenStats()
	return

/datum/component/combo_core/wanderer/proc/OnDetachClearHiddenStats()
	return

/datum/component/combo_core/wanderer/proc/RefreshHiddenStats()
	return

// ------------------------------------------------------------
// signals
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/_sig_register_input(datum/source, skill_id, mob/living/target, zone)
	SIGNAL_HANDLER

	if(!owner || !skill_id)
		return 0

	switch(skill_id)
		if(WANDERER_BUTTON_SWITCH_STANCE)
			ToggleStance()
			return COMPONENT_COMBO_ACCEPTED

		if(WANDERER_BUTTON_EROTIC_EMBRACE)
			ToggleEroticEmbrace()
			return COMPONENT_COMBO_ACCEPTED

	return 0

/datum/component/combo_core/wanderer/proc/_sig_examined(datum/source, mob/living/user)
	SIGNAL_HANDLER

	if(!erotic_embrace_enabled)
		return 0
	if(!isliving(user))
		return 0
	if(user == owner)
		return 0

	SEND_SIGNAL(user, COMSIG_SEX_RECEIVE_ACTION, 10, 0, TRUE, 2, 2, null)
	AddArousalStack(1)
	return 0

/datum/component/combo_core/wanderer/proc/_sig_try_consume(datum/source, atom/target_atom, zone, obj/item/W, forced_skill_id)
	SIGNAL_HANDLER

	if(!owner)
		return 0

	if(W)
		return 0

	var/skill_id = forced_skill_id || ResolveAttackInput(target_atom, W)
	if(!IsBaseInput(skill_id))
		return 0

	var/mob/living/target = null
	if(isliving(target_atom))
		target = target_atom

	last_action_success = TRUE
	last_action_skill = skill_id
	last_action_zone = zone || BODY_ZONE_CHEST
	last_action_target = target
	last_finisher_success = FALSE
	last_matched_rule = null

	AddComboStack()

	if(erotic_embrace_enabled)
		if(target)
			SEND_SIGNAL(target, COMSIG_SEX_RECEIVE_ACTION, 5, 0, TRUE, 2, 2, null)
		AddArousalStack(1)
	else
		if(current_stance == WANDERER_STANCE_PROC)
			ApplyProcPressureOnHit(target, last_action_zone, FALSE)
		else
			ApplyPreciseOnHit(target, last_action_zone)

	var/fired = RegisterInput(skill_id, target, last_action_zone)
	if(fired && owner?.client)
		owner.balloon_alert(owner, "wanderer combo!")

	if(!erotic_embrace_enabled)
		SpendArousalStack(1)

	RefreshHiddenStats()
	return 0

// ------------------------------------------------------------
// stance / embrace
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/ToggleStance()
	if(current_stance == WANDERER_STANCE_PROC)
		SetStance(WANDERER_STANCE_PRECISE)
	else
		SetStance(WANDERER_STANCE_PROC)

/datum/component/combo_core/wanderer/proc/SetStance(new_stance)
	if(current_stance == new_stance)
		return

	current_stance = new_stance
	RefreshHiddenStats()
	_balloon_stance()

/datum/component/combo_core/wanderer/proc/ToggleEroticEmbrace()
	erotic_embrace_enabled = !erotic_embrace_enabled

	if(erotic_embrace_enabled)
		ADD_TRAIT(owner, TRAIT_DODGEEXPERT, WANDERER_EMBRACE_TRAIT_SOURCE)
	else
		REMOVE_TRAIT(owner, TRAIT_DODGEEXPERT, WANDERER_EMBRACE_TRAIT_SOURCE)

	RefreshHiddenStats()
	_balloon_embrace()

// ------------------------------------------------------------
// combo callback / execution
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/_cb_combo(rule_id, mob/living/target, zone)
	if(!last_action_success)
		return FALSE
	if(!owner)
		return FALSE

	if(!target)
		target = last_action_target
	if(!zone)
		zone = last_action_zone

	if(!target)
		return FALSE

	ExecuteCombo(rule_id, target, zone)
	return TRUE

/datum/component/combo_core/wanderer/proc/ExecuteCombo(rule_id, mob/living/target, zone)
	if(!owner || !target || !rule_id)
		return FALSE

	var/zone_used = TryGetZone(zone)
	var/combo_mult = GetComboDamageMultiplier()

	switch(rule_id)
		if("heel_tap")
			if(current_stance == WANDERER_STANCE_PROC)
				var/dmg1 = max(1, round(combo_mult * 1.25))
				target.adjustBruteLoss(dmg1)
				target.stamina_add(round(target.max_stamina * 0.12))

				if(!erotic_embrace_enabled)
					SafeSlow(target, 1.5)
					ApplyProcPressureOnHit(target, zone_used, TRUE)
			else
				var/dmg1p = max(1, round(combo_mult * 0.95))
				target.adjustBruteLoss(dmg1p)

				if(!erotic_embrace_enabled)
					ApplyPreciseFinisher(target, zone_used, last_action_skill)

			owner.visible_message(
				span_danger("[owner] chains a sharp heel tap finish!"),
				span_notice("Heel Tap lands clean."),
			)

		if("needle_thread")
			if(current_stance == WANDERER_STANCE_PROC)
				if(!erotic_embrace_enabled)
					target.Immobilize(1 SECONDS)
				target.stamina_add(round(target.max_stamina * 0.12))

				if(!erotic_embrace_enabled)
					ApplyProcPressureOnHit(target, zone_used, TRUE)
			else
				var/dmg_nt = max(1, round(combo_mult * 0.90))
				target.adjustBruteLoss(dmg_nt)

				if(!erotic_embrace_enabled)
					ApplyPreciseFinisher(target, zone_used, last_action_skill)

			owner.visible_message(
				span_danger("[owner] slips in and secures a controlling catch!"),
				span_notice("Needle Thread turns contact into control."),
			)

		if("iron_bloom")
			if(current_stance == WANDERER_STANCE_PROC)
				var/dmg2 = max(2, round(combo_mult * 1.5))
				target.adjustBruteLoss(dmg2)

				if(!erotic_embrace_enabled)
					if(_get_stamina_pct(target) <= 0.4)
						SafeOffbalance(target, 2 SECONDS)
					else
						target.stamina_add(round(target.max_stamina * 0.18))
					ApplyProcPressureOnHit(target, zone_used, TRUE)
			else
				var/dmg2p = max(1, round(combo_mult * 1.10))
				target.adjustBruteLoss(dmg2p)

				if(!erotic_embrace_enabled)
					ApplyPreciseFinisher(target, zone_used, last_action_skill)

			owner.visible_message(
				span_danger("[owner] blooms through the guard with a crushing finisher!"),
				span_notice("Iron Bloom bursts through [target]'s footing."),
			)

		if("leg_hook")
			if(current_stance == WANDERER_STANCE_PROC)
				var/dmg_lh = max(1, round(combo_mult * 0.85))
				target.adjustBruteLoss(dmg_lh)

				if(!erotic_embrace_enabled)
					SafeOffbalance(target, 1.5 SECONDS)
					target.stamina_add(round(target.max_stamina * 0.10))
					ApplyProcPressureOnHit(target, zone_used, TRUE)
			else
				var/dmg_lhp = max(1, round(combo_mult * 0.85))
				target.adjustBruteLoss(dmg_lhp)

				if(!erotic_embrace_enabled)
					ApplyPreciseFinisher(target, zone_used, last_action_skill)

			owner.visible_message(
				span_danger("[owner] catches [target]'s footing and drags them off balance!"),
				span_notice("Leg Hook turns precision into control."),
			)

		if("gatebreaker")
			var/d = get_dir(owner, target)
			if(!d)
				d = owner.dir

			if(current_stance == WANDERER_STANCE_PROC)
				var/dmg3 = max(3, round(combo_mult * 2.0))
				target.adjustBruteLoss(dmg3)

				if(!erotic_embrace_enabled)
					target.stamina_add(round(target.max_stamina * 0.22))
					Knockback(target, 1, d, MOVE_FORCE_STRONG)
					SafeOffbalance(target, 2.2 SECONDS)
					ApplyProcPressureOnHit(target, zone_used, TRUE)
			else
				var/dmg3p = max(2, round(combo_mult * 1.25))
				target.adjustBruteLoss(dmg3p)

				if(!erotic_embrace_enabled)
					ApplyPreciseFinisher(target, zone_used, last_action_skill)

			owner.visible_message(
				span_danger("[owner] drives through with a gatebreaker finish!"),
				span_notice("Gatebreaker caves the line."),
			)

		if("crane_fold")
			if(current_stance == WANDERER_STANCE_PROC)
				var/dmg_cf = max(2, round(combo_mult * 1.15))
				target.adjustBruteLoss(dmg_cf)

				if(!erotic_embrace_enabled)
					if(zone_used == BODY_ZONE_HEAD)
						target.Stun(1.5 SECONDS)
					else if(zone_used == BODY_ZONE_L_LEG || zone_used == BODY_ZONE_R_LEG)
						SafeOffbalance(target, 2.5 SECONDS)
					else
						target.Immobilize(1.5 SECONDS)

					ApplyProcPressureOnHit(target, zone_used, TRUE)
			else
				var/dmg_cfp = max(1, round(combo_mult * 1.00))
				target.adjustBruteLoss(dmg_cfp)

				if(!erotic_embrace_enabled)
					ApplyPreciseFinisher(target, zone_used, last_action_skill)

			owner.visible_message(
				span_danger("[owner] folds [target] with a sharp, clinical finish!"),
				span_notice("Crane Fold punishes the opening."),
			)

		if("double_strike")
			target.adjustBruteLoss(max(1, round(combo_mult * 1.1)))

		if("low_pressure")
			target.adjustBruteLoss(max(1, round(combo_mult * 1.1)))

		if("triple_strike")
			target.adjustBruteLoss(max(2, round(combo_mult * 1.4)))

		if("breaker_kicks")
			target.adjustBruteLoss(max(2, round(combo_mult * 1.4)))

		if("grip_break")
			target.adjustBruteLoss(max(2, round(combo_mult * 1.2)))
			target.Immobilize(1 SECONDS)

		if("body_lock")
			target.adjustBruteLoss(max(2, round(combo_mult * 1.2)))
			SafeOffbalance(target, 1.5 SECONDS)

	ShowComboIcon(target, rule_id)
	return TRUE

// ------------------------------------------------------------
// proc pressure
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/GetPressureChance()
	return clamp(20 + (combo_stacks * 10), 0, 100)

/datum/component/combo_core/wanderer/proc/GetPressureDamage()
	if(!owner)
		return 1
	return max(1, round(owner.get_stat(STAT_STRENGTH) / 2))

/datum/component/combo_core/wanderer/proc/ApplyArmorDamageToZone(mob/living/target, zone, amount)
	if(!ishuman(target))
		return

	var/mob/living/carbon/human/H = target
	var/cover_flag

	switch(zone)
		if(BODY_ZONE_HEAD)
			cover_flag = HEAD
		if(BODY_ZONE_CHEST)
			cover_flag = CHEST
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			cover_flag = ARMS
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			cover_flag = LEGS
		else
			cover_flag = CHEST

	for(var/obj/item/clothing/C in H.contents)
		if(C.loc != H)
			continue
		if(!(C.body_parts_covered & cover_flag))
			continue
		if(!C.armor)
			continue

		C.take_damage(amount, BRUTE, "slash")
		break

/datum/component/combo_core/wanderer/proc/ApplyProcPressureOnHit(mob/living/target, zone, guaranteed = FALSE)
	if(!owner || !target)
		return

	var/chance = guaranteed ? 100 : GetPressureChance()
	if(!prob(chance))
		return

	ApplyArmorDamageToZone(target, zone, GetPressureDamage())

// ------------------------------------------------------------
// precise stance
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/GetPreciseStaminaDamage()
	if(!owner)
		return 1
	return max(1, round(owner.get_stat(STAT_STRENGTH) / 2))

/datum/component/combo_core/wanderer/proc/ApplyPreciseOnHit(mob/living/target, zone)
	if(!owner || !target)
		return

	var/zone_used = TryGetZone(zone)

	switch(zone_used)
		if(BODY_ZONE_HEAD)
			if(prob(25))
				target.Dizzy(1 SECONDS)

		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			if(prob(25))
				SafeSlow(target, 1)

		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			if(prob(25))
				if(ishuman(target))
					var/mob/living/carbon/human/H = target
					H.drop_all_held_items()
				else
					target.Immobilize(0.5 SECONDS)

		if(BODY_ZONE_CHEST)
			if(prob(25))
				target.stamina_add(GetPreciseStaminaDamage())

/datum/component/combo_core/wanderer/proc/ApplyPreciseFinisher(mob/living/target, zone, finisher_skill)
	if(!target)
		return

	var/zone_used = TryGetZone(zone)

	switch(zone_used)
		if(BODY_ZONE_HEAD)
			var/chance_head = 25
			if(finisher_skill == WANDERER_INPUT_PUNCH)
				chance_head = 50
			if(prob(chance_head))
				target.Stun(1.5 SECONDS)

		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			var/chance_arms = 25
			if(finisher_skill == WANDERER_INPUT_GRAB)
				chance_arms = 50
			if(prob(chance_arms))
				target.Immobilize(1.5 SECONDS)

		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			var/chance_legs = 25
			if(finisher_skill == WANDERER_INPUT_KICK)
				chance_legs = 50
			if(prob(chance_legs))
				SafeOffbalance(target, 2 SECONDS)

		if(BODY_ZONE_CHEST)
			var/chance_chest = 15
			if(finisher_skill == WANDERER_INPUT_GRAB)
				chance_chest = 25
			if(prob(chance_chest))
				target.Knockdown(1.5 SECONDS)

// ------------------------------------------------------------
// kick helpers
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/GetKickOffbalanceDuration(base_duration = 3 SECONDS)
	var/stacks = clamp(combo_stacks, 0, max_combo_stacks)
	if(stacks <= 0)
		return base_duration

	var/mult = 1 - (stacks * 0.10)
	mult = clamp(mult, 0.35, 1)
	return max(WANDERER_KICK_MIN_RECOVERY, round(base_duration * mult))

// ------------------------------------------------------------
// arousal / resources
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/AddComboStack(amount = 1)
	if(amount <= 0)
		return

	combo_stacks = clamp(combo_stacks + amount, 0, max_combo_stacks)
	_balloon_stacks()
	RefreshHiddenStats()

/datum/component/combo_core/wanderer/proc/ResetComboStacks()
	if(combo_stacks <= 0)
		return

	combo_stacks = 0
	_balloon_stacks()
	RefreshHiddenStats()

/datum/component/combo_core/wanderer/proc/AddArousalStack(amount = 1)
	if(amount <= 0)
		return

	arousal_stacks = clamp(arousal_stacks + amount, 0, max_arousal_stacks)
	_balloon_arousal()
	RefreshHiddenStats()

/datum/component/combo_core/wanderer/proc/SpendArousalStack(amount = 1)
	if(amount <= 0)
		return
	if(arousal_stacks <= 0)
		return

	arousal_stacks = clamp(arousal_stacks - amount, 0, max_arousal_stacks)
	_balloon_arousal()
	RefreshHiddenStats()

/datum/component/combo_core/wanderer/proc/GetComboDamageMultiplier()
	if(erotic_embrace_enabled)
		return 0.10

	var/mult = 1
	mult += (combo_stacks * WANDERER_COMBO_DMG_PER_STACK)
	mult += (arousal_stacks * WANDERER_AROUSAL_DMG_PER_STACK)
	return max(1, mult)

// ------------------------------------------------------------
// utils
// ------------------------------------------------------------

/datum/component/combo_core/wanderer/proc/ResolveAttackInput(atom/target_atom, obj/item/W)
	if(!owner)
		return 0

	if(W)
		return 0

	if(owner.used_intent && findtext(lowertext("[owner.used_intent.type]"), "grab"))
		return WANDERER_INPUT_GRAB
	if(owner.used_intent && findtext(lowertext("[owner.used_intent.name]"), "grab"))
		return WANDERER_INPUT_GRAB

	return WANDERER_INPUT_PUNCH

/datum/component/combo_core/wanderer/proc/IsBaseInput(skill_id)
	return (skill_id == WANDERER_INPUT_PUNCH || skill_id == WANDERER_INPUT_KICK || skill_id == WANDERER_INPUT_GRAB)

/datum/component/combo_core/wanderer/proc/ShowComboIcon(mob/living/target, rule_id)
	if(!target || !rule_id)
		return

	var/icon_state = null

	switch(rule_id)
		if("heel_tap")
			icon_state = "ronin_tanuki"
		if("needle_thread")
			icon_state = "ronin_kitsune"
		if("iron_bloom")
			icon_state = "ronin_ryu"
		if("leg_hook")
			icon_state = "ronin_tengu"
		if("gatebreaker")
			icon_state = "ronin_ryu"
		if("crane_fold")
			icon_state = "ronin_kitsune"

		if("double_strike")
			icon_state = "ronin_ryu"
		if("low_pressure")
			icon_state = "ronin_tengu"
		if("triple_strike")
			icon_state = "ronin_ryu"
		if("breaker_kicks")
			icon_state = "ronin_tengu"
		if("grip_break")
			icon_state = "ronin_kitsune"
		if("body_lock")
			icon_state = "ronin_kitsune"

	if(icon_state)
		target.play_overhead_indicator_flick(WANDERER_COMBO_ICON_FILE, icon_state, 0.9 SECONDS, ABOVE_MOB_LAYER + 0.3, null, 18)

/datum/component/combo_core/wanderer/proc/_balloon_stacks()
	if(owner?.client)
		owner.balloon_alert(owner, "wanderer stacks: [combo_stacks]")

/datum/component/combo_core/wanderer/proc/_balloon_arousal()
	if(owner?.client)
		owner.balloon_alert(owner, "wanderer arousal: [arousal_stacks]")

/datum/component/combo_core/wanderer/proc/_balloon_stance()
	if(!owner?.client)
		return

	if(current_stance == WANDERER_STANCE_PROC)
		owner.balloon_alert(owner, "stance: proc")
	else
		owner.balloon_alert(owner, "stance: precise")

/datum/component/combo_core/wanderer/proc/_balloon_embrace()
	if(!owner?.client)
		return

	if(erotic_embrace_enabled)
		owner.balloon_alert(owner, "embrace: on")
	else
		owner.balloon_alert(owner, "embrace: off")

// ============================================================
// Wanderer spells
// ============================================================

/obj/effect/proc_holder/spell/self/wanderer
	name = "Wanderer Ability"
	desc = "Base wanderer ability."
	clothes_req = FALSE
	charge_type = "recharge"
	cost = 0
	xp_gain = FALSE

	releasedrain = 0
	chargedrain = 0
	chargetime = 0
	recharge_time = 6 SECONDS

	warnie = "spellwarning"
	no_early_release = TRUE
	movement_interrupt = FALSE
	spell_tier = 1

	invocations = list()
	invocation_type = "none"
	hide_charge_effect = TRUE
	charging_slowdown = 0
	chargedloop = null
	overlay_state = null

	action_icon = 'modular_twilight_axis/icons/roguetown/misc/soundspells.dmi'

/obj/effect/proc_holder/spell/self/wanderer/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user))
		return

	var/mob/living/L = user
	if(L.incapacitated())
		return

	var/datum/component/combo_core/wanderer/C = wanderer_get_component_safe(L)
	if(!C)
		return

	Execute(L, C)

/obj/effect/proc_holder/spell/self/wanderer/proc/Execute(mob/living/user, datum/component/combo_core/wanderer/C)
	return

// ------------------------------------------------------------
// Ability 1 = Switch Stance
// ------------------------------------------------------------

/obj/effect/proc_holder/spell/self/wanderer/switch_stance
	name = "Switch Stance"
	desc = "Switch between proc stance and precise stance."
	overlay_state = "active_strike"

/obj/effect/proc_holder/spell/self/wanderer/switch_stance/Execute(mob/living/user, datum/component/combo_core/wanderer/C)
	if(!user || !C)
		return

	SEND_SIGNAL(user, COMSIG_COMBO_CORE_REGISTER_INPUT, WANDERER_BUTTON_SWITCH_STANCE, null, null)

// ------------------------------------------------------------
// Ability 2 = Erotic Embrace
// ------------------------------------------------------------

/obj/effect/proc_holder/spell/self/wanderer/erotic_embrace
	name = "Erotic Embrace"
	desc = "Preparation / play mode."
	overlay_state = "active_wave"

/obj/effect/proc_holder/spell/self/wanderer/erotic_embrace/Execute(mob/living/user, datum/component/combo_core/wanderer/C)
	if(!user || !C)
		return

	SEND_SIGNAL(user, COMSIG_COMBO_CORE_REGISTER_INPUT, WANDERER_BUTTON_EROTIC_EMBRACE, null, null)

// ============================================================
// kick patch kept here for now as requested
// ============================================================

/mob/living/try_kick(atom/A)

	if(ismob(A) && HAS_TRAIT(A, "ethereal"))
		to_chat(src, span_warning("My foot passes right through the mist!"))
		return FALSE

	if(!can_kick(A))
		return FALSE

	changeNext_move(mmb_intent.clickcd)
	face_atom(A)
	SEND_SIGNAL(src, COMSIG_MOB_ON_KICK)
	playsound(src, pick(PUNCHWOOSH), 100, FALSE, -1)

	if(mmb_intent)
		do_attack_animation_simple(A, visual_effect_icon = mmb_intent.animname)

	var/atom/target = A
	if(isturf(A))
		for(var/mob/living/M in A)
			target = M
			break

	var/mob/living/living_target = null
	if(isliving(target))
		living_target = target

	var/kick_success = FALSE

	if(ismob(target) && mmb_intent)
		var/mob/living/M = target
		sleep(mmb_intent.swingdelay)
		if(QDELETED(src) || QDELETED(M))
			return FALSE
		if(!M.Adjacent(src))
			return FALSE
		if(incapacitated(ignore_restraints = TRUE))
			return FALSE

		if(M.checkmiss(src))
			return FALSE

		SEND_SIGNAL(M, COMSIG_MOB_KICKED)

		if(M.checkdefense(mmb_intent, src))
			return FALSE

		if(ishuman(M))
			var/mob/living/carbon/human/H = M
			H.dna.species.kicked(src, H)
		else
			M.onkick(src)

		kick_success = TRUE
	else
		target.onkick(src)
		kick_success = TRUE

	if(kick_success)
		SEND_SIGNAL(src, COMSIG_SOUNDBREAKER_KICK_SUCCESS, target)
		SEND_SIGNAL(src, COMSIG_ATTACK_TRY_CONSUME, living_target || target, zone_selected, null, WANDERER_INPUT_KICK)

	OffBalance(wanderer_get_kick_offbalance_duration(src, 3 SECONDS))
	return TRUE

// ============================================================
// cleanup
// ============================================================

#undef WANDERER_COMBO_WINDOW
#undef WANDERER_MAX_HISTORY
#undef WANDERER_MAX_COMBO_STACKS
#undef WANDERER_MAX_AROUSAL_STACKS
#undef WANDERER_COMBO_DMG_PER_STACK
#undef WANDERER_AROUSAL_DMG_PER_STACK
#undef WANDERER_KICK_MIN_RECOVERY
#undef WANDERER_INPUT_PUNCH
#undef WANDERER_INPUT_KICK
#undef WANDERER_INPUT_GRAB
#undef WANDERER_STANCE_PROC
#undef WANDERER_STANCE_PRECISE
#undef WANDERER_BUTTON_SWITCH_STANCE
#undef WANDERER_BUTTON_EROTIC_EMBRACE
#undef WANDERER_COMBO_ICON_FILE
#undef WANDERER_EMBRACE_TRAIT_SOURCE
