/// subtype of splatter capable of doing proper "stacking" behavior
/obj/effect/decal/cleanable/blood/splatter/stacking
	appearance_flags =  TILE_BOUND|PIXEL_SCALE|LONG_GLIDE // BILINEAR FILTERING LOOKS DOGSHIT WHEN YOU FUCK WITH THE TRANSFORM
	/// Maximum amount of blood overlays we can have visually
	var/maximum_splats = 50
	/// Listing containing overlays of all the splatters we've merged with
	var/list/splat_overlays = list()

/obj/effect/decal/cleanable/blood/splatter/stacking/Initialize(mapload, pixel_x, pixel_y)
	. = ..()
	if(!isnull(pixel_x))
		src.pixel_x = pixel_x
	if(!isnull(pixel_y))
		src.pixel_y = pixel_y
	var/mutable_appearance/our_appearance = generate_overlay()
	splat_overlays += our_appearance
	update_appearance(UPDATE_ICON)

/obj/effect/decal/cleanable/blood/splatter/stacking/Destroy()
	. = ..()
	splat_overlays = null

/obj/effect/decal/cleanable/blood/splatter/stacking/update_overlays()
	. = ..()
	var/splat_length = length(splat_overlays)
	if(splat_length > maximum_splats)
		splat_overlays = splat_overlays.Splice(splat_length  - maximum_splats, splat_length)
	. += splat_overlays

/obj/effect/decal/cleanable/blood/splatter/stacking/handle_merge_decal(obj/effect/decal/cleanable/merger)
	. = ..()
	if(istype(merger, /obj/effect/decal/cleanable/blood/splatter/stacking))
		var/obj/effect/decal/cleanable/blood/splatter/stacking/stacker = merger
		stacker.splat_overlays |= splat_overlays
		stacker.get_timer() //reset drying time, ripbozo
		stacker.update_appearance(UPDATE_ICON)

/// Used to generate the initial mutable appearance for the splatter that gets added to splat_overlays
/obj/effect/decal/cleanable/blood/splatter/stacking/proc/generate_overlay()
	var/mutable_appearance/gen_overlay = mutable_appearance(src.icon, src.icon_state)
	gen_overlay.alpha = src.alpha
	gen_overlay.color = src.color
	gen_overlay.pixel_x = src.pixel_x
	gen_overlay.pixel_y = src.pixel_y
	gen_overlay.transform = matrix(transform)

	icon_state = null
	color = null
	alpha = 255
	pixel_x = 0
	pixel_y = 0
	transform = null

	return gen_overlay

/// Called so that a spawning animation can be performed by blood particles, after that is done we merge with merger
/obj/effect/decal/cleanable/blood/splatter/stacking/proc/delayed_merge(obj/effect/decal/cleanable/blood/splatter/stacking/merger)
	if(QDELETED(merger))
		if(!QDELETED(src))
			qdel(src)
		return

	if(QDELETED(src))
		return

	if(merge_decal(merger))
		qdel(src)

/// Squirt subtype
/obj/effect/decal/cleanable/blood/splatter/stacking/squirt
	name = "blood squirt"
	desc = "Raining blood, from a lacerated sky, bleeding its horror!"
	icon_state = "squirt"
	random_icon_states = null
	dryname = "dried blood squirt"
	drydesc = "Creating my structure - Now I shall reign in blood!"

/obj/effect/decal/cleanable/blood/splatter/stacking/squirt/Initialize(mapload, pixel_x, pixel_y, angle)
	if(!isnull(angle))
		transform = transform.Turn(angle)
	return ..()
