/proc/soundbreaker_combo_echo_beat(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	soundbreaker_apply_damage(user, target, 0.5, BCLASS_PUNCH)
	sb_safe_offbalance(target, 2.0 SECONDS)
	user.visible_message(
		span_danger("[user]'s rhythm echoes into [target], staggering them!"),
		span_notice("Your echo beat staggers [target]."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_ECHO)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_tempo_flick(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	soundbreaker_apply_damage(user, target, 0.5, BCLASS_PUNCH)
	sb_safe_slow(target, 2)
	user.visible_message(
		span_danger("[user] knocks [target]'s tempo off with a flick of sound!"),
		span_notice("You disrupt [target]'s movement with a sharp change in tempo."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_TEMPO)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_snapback(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	soundbreaker_apply_damage(user, target, 0.75, BCLASS_PUNCH)
	user.visible_message(
		span_danger("[user]'s follow-up snaps back into [target]'s weak point!"),
		span_notice("You snap your follow-up into a soft spot."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_SNAPBACK)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_bass_drop(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	soundbreaker_apply_damage(user, target, 1.5, BCLASS_PUNCH)
	sb_safe_offbalance(target, 3.0 SECONDS)
	playsound(target, 'sound/magic/repulse.ogg', 90, TRUE)
	user.visible_message(
		span_danger("[user]'s rhythm drops heavy on [target]!"),
		span_notice("You slam [target] with a bass drop."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_BASS)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_crossfade(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	sb_small_bleed(target, 4)
	user.visible_message(
		span_danger("[user]'s passing strike leaves [target] bleeding!"),
		span_notice("Your crossfade cuts [target] open as you move through."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_CROSSFADE)

/proc/soundbreaker_combo_reverb_cut(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	sb_safe_slow(target, 5)
	soundbreaker_knockback(user, target, 2)
	user.visible_message(
		span_danger("[user]'s cutting reverb throws [target] back!"),
		span_notice("You send [target] reeling on the rebound."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_REVERB)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_syncopation(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	target.Immobilize(1.5 SECONDS)
	user.visible_message(
		span_danger("[user]'s off-beat rhythm locks [target] in place!"),
		span_notice("Your syncopated pattern roots [target] for a moment."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_SYNC)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_ritmo(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	soundbreaker_apply_damage(user, target, 0.75, BCLASS_PUNCH)
	user.visible_message(
		span_danger("[user]'s flurry of strikes peaks in a sharp hit on [target]!"),
		span_notice("Your ritmo peaks in a stronger hit."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_RITMO)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_crescendo(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	soundbreaker_apply_damage(user, target, 1.5, BCLASS_PUNCH)
	target.Stun(1.0 SECONDS)
	sb_safe_offbalance(target, 2.0 SECONDS)
	user.visible_message(
		span_danger("[user]'s crescendo crashes down on [target] in a brutal finale!"),
		span_notice("Your crescendo finale crushes [target]'s guard."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_CRESCENDO)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_overture(mob/living/user, mob/living/target)
	if(!user || !target)
		return

	for(var/i in 1 to 2)
		for(var/mob/living/L in view(1, target))
			if(L == user)
				continue
			if(L.stat == DEAD)
				continue
			soundbreaker_apply_damage(user, L, 0.75, BCLASS_PUNCH)
			sb_safe_offbalance(L, 0.8 SECONDS)
		sleep(0.4 SECONDS)

	user.visible_message(
		span_danger("[user]'s overture explodes around [target] in ringing pulses!"),
		span_notice("Your overture ripples outward from [target]."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_OVERTURE)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_blade_dancer(mob/living/user, mob/living/target)
	if(!user || !target)
		return
	sb_small_bleed(target, 7)
	soundbreaker_apply_damage(user, target, 0.75, BCLASS_PUNCH)
	user.visible_message(
		span_danger("[user] dances around [target], leaving deep cuts in their wake!"),
		span_notice("Your blade dancer combo carves into [target]."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_BLADE)
	soundbreaker_reset_rhythm(user)

/proc/soundbreaker_combo_harmonic_burst(mob/living/user, mob/living/target)
	if(!user || !target)
		return

	for(var/mob/living/L in view(1, target))
		if(L == user)
			continue
		if(L.stat == DEAD)
			continue
		soundbreaker_apply_damage(user, L, 1.25, BCLASS_PUNCH)
		sb_safe_offbalance(L, 5 SECONDS)
		L.Knockdown(1.5 SECONDS)

	playsound(target, 'sound/combat/ground_smash1.ogg', 90, TRUE)

	user.visible_message(
		span_danger("[user]'s harmonic burst crashes out from [target] in a shockwave!"),
		span_notice("Your harmonic burst rattles everyone around [target]."),
	)
	soundbreaker_show_combo_icon(target, SB_COMBO_ICON_HARMONIC)
	soundbreaker_reset_rhythm(user)
