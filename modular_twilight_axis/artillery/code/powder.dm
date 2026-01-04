/obj/item/artillery_powder_keg
	name = "keg of black powder"
	desc = "A heavy keg. The powder quality varies by batch."
	icon = 'icons/obj/artillery.dmi'
	icon_state = "powder_keg"

	/// 0.85..1.15, generated per keg (roundstart or map spawn init)
	var/powder_quality = 1.0
	/// 0.0..1.0 (wet powder increases misfire risk / scatter)
	var/powder_moisture = 0.0

	/// How many measures remain (gameplay resource)
	var/measures_left = 50

/obj/item/artillery_powder_keg/Initialize(mapload)
	. = ..()
	// If you want per-round batches to be consistent, you can seed from GLOB.artillery_atmo or round id.
	powder_quality = rand(90, 110) / 100
	powder_moisture = rand(0, 25) / 100
	measures_left = rand(40, 70)

/// Takes measures from the keg, returns list(quality, moisture, amount_taken)
/obj/item/artillery_powder_keg/proc/take_measures(amount)
	if(amount <= 0)
		return list(powder_quality, powder_moisture, 0)

	var/take = min(amount, measures_left)
	measures_left -= take
	return list(powder_quality, powder_moisture, take)
