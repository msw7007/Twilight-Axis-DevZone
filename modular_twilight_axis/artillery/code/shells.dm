/obj/item/artillery_shell
	name = "mortar shell"
	desc = "A heavy projectile."
	icon = 'icons/obj/artillery.dmi'
	icon_state = "shell"

	/// Higher mass => shorter range, lower drift, typically lower scatter
	var/mass = 10.0
	/// Base scatter in tiles (before weather/skill)
	var/base_scatter = 2
	/// Explosion scale multiplier (used by your explosion wrapper)
	var/blast_mult = 1.0
	/// Drift multiplier (heavier shells drift less)
	var/drift_mult = 1.0

/obj/item/artillery_shell/heavy
	name = "heavy iron shell"
	icon_state = "shell_heavy"
	mass = 16.0
	base_scatter = 1
	blast_mult = 1.25
	drift_mult = 0.7

/obj/item/artillery_shell/light
	name = "light stone shell"
	icon_state = "shell_light"
	mass = 8.0
	base_scatter = 3
	blast_mult = 0.85
	drift_mult = 1.2

/obj/item/artillery_shell/canister
	name = "canister shot"
	icon_state = "shell_canister"
	mass = 9.0
	base_scatter = 4
	blast_mult = 0.6
	drift_mult = 1.1
