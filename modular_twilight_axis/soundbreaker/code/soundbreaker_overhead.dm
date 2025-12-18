// code/modules/roguetown/bard/soundbreaker_overhead.dm

/// Максимум видимых нот над головой
#define SB_MAX_VISIBLE_NOTES 5

/// DMI с маленькими (8x8) значками нот
#define SOUNDBREAKER_NOTES_ICON 'modular_twilight_axis/soundbreaker/icons/soundspells.dmi'

/// DMI с большими (32x32) иконками комбо
#define SOUNDBREAKER_COMBOS_ICON 'modular_twilight_axis/soundbreaker/icons/soundspells.dmi'

/proc/sb_get_note_icon_state(note_id)
	switch(note_id)
		if(SOUNDBREAKER_NOTE_STRIKE)      return "note_strike"
		if(SOUNDBREAKER_NOTE_WAVE)        return "note_wave"
		if(SOUNDBREAKER_NOTE_DULCE)       return "note_dulce"
		if(SOUNDBREAKER_NOTE_OVERLOAD)    return "note_overload"
		if(SOUNDBREAKER_NOTE_ENCORE)      return "note_encore"
		if(SOUNDBREAKER_NOTE_SOLO)        return "note_solo"
	return null

/mob/living
	/// история введённых нот (id)
	var/list/sb_note_history
	/// текущие overlay’и маленьких 8x8 иконок
	var/list/sb_note_overlays

/// Добавить ноту в историю и обновить оверлеи (над БЬЮЩИМ)
/proc/soundbreaker_show_note_icon(mob/living/user, note_id)
	if(!user || !note_id)
		return

	if(!islist(user.sb_note_history))
		user.sb_note_history = list()

	user.sb_note_history += note_id

	// оставляем только последние SB_MAX_VISIBLE_NOTES
	while(user.sb_note_history.len > SB_MAX_VISIBLE_NOTES)
		user.sb_note_history.Cut(1, 2)

	soundbreaker_update_note_overlays(user)

/// Полная перерисовка нот над головой
/proc/soundbreaker_update_note_overlays(mob/living/user)
	if(!user)
		return

	// 1) Сносим старые оверлеи
	if(islist(user.sb_note_overlays) && user.sb_note_overlays.len)
		for(var/mutable_appearance/old_ma as anything in user.sb_note_overlays)
			if(old_ma)
				user.cut_overlay(old_ma)
		user.sb_note_overlays.Cut()
	else
		user.sb_note_overlays = list()

	// 2) Если истории нет — всё, вышли
	if(!islist(user.sb_note_history) || !user.sb_note_history.len)
		return

	// 3) Рисуем заново: НОВАЯ нота справа, СТАРЫЕ смещаются влево.
	//    То есть при истории [1,3,4,6,2,3] (после обрезки → [3,4,6,2,3])
	//    справа налево будет: 3(новая),2,6,4,3 → визуально "34623".
	var/base_y = 18        // высота над головой, подгони под свой спрайт
	var/step_x = 8         // ширина иконки
	var/offset_idx = 0     // 0,1,2,3,4...

	// идём с КОНЦА к НАЧАЛУ: от самой новой ноты к самой старой
	for(var/i = user.sb_note_history.len, i >= 1, i--)
		var/note_id = user.sb_note_history[i]
		var/state = sb_get_note_icon_state(note_id)
		if(!state)
			continue

		var/mutable_appearance/MA = mutable_appearance(SOUNDBREAKER_NOTES_ICON, state)
		MA.layer = ABOVE_MOB_LAYER + 0.2
		MA.pixel_y = base_y

		// 0, -8, -16, -24, -32 … — рост ВЛЕВО от головы
		MA.pixel_x = -(offset_idx * step_x)
		offset_idx++

		user.add_overlay(MA)
		user.sb_note_overlays += MA

/// Полная очистка (история + мелкие оверлеи)
/// Зовём:
/// - при сбросе ритма,
/// - при спадении баффа,
/// - при смерти / сильном ресете.
/proc/soundbreaker_clear_note_icons(mob/living/user)
	if(!user)
		return

	if(islist(user.sb_note_overlays) && user.sb_note_overlays.len)
		for(var/mutable_appearance/MA as anything in user.sb_note_overlays)
			if(MA)
				user.cut_overlay(MA)
		user.sb_note_overlays.Cut()

	if(islist(user.sb_note_history) && user.sb_note_history.len)
		user.sb_note_history.Cut()

/// Мигалка-иконка финишера (32x32) над головой КАСТЕРА
/proc/soundbreaker_show_combo_icon(mob/living/user, icon_state)
	if(!user || !icon_state)
		return

	var/duration = 0.7 SECONDS
	user.play_overhead_indicator_flick(
		SOUNDBREAKER_COMBOS_ICON,
		icon_state,
		duration,
		ABOVE_MOB_LAYER + 0.3,
		null,
		16,
		0
	)
