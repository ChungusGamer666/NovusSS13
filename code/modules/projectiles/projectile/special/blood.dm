/obj/projectile/blood
	name = "blood splatter"
	icon = 'icons/effects/blood.dmi'
	icon_state = "hitsplatter1"
	base_icon_state = "hitsplatter"
	pass_flags = PASSTABLE
	damage = 0
	speed = 1
	hitsound = null
	range = 3
	set_dir_on_move = FALSE

/obj/projectile/blood/Initialize(mapload, list/blood_dna)
	. = ..()
	dir = NORTH
	icon_state = "[base_icon_state][rand(1,3)]"
	if(LAZYLEN(blood_dna))
		add_blood_DNA(blood_dna)


/obj/projectile/blood/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(!.)
		return

	if(iswallturf(target))
		//Adjust pixel offset to make splatters appear on the wall
		var/obj/effect/decal/cleanable/blood/splatter/over_window/final_splatter = new(loc)
		final_splatter.add_blood_DNA(GET_ATOM_BLOOD_DNA(src))
		var/dir_to_wall = get_dir(src, target)
		final_splatter.pixel_x = (dir_to_wall & EAST ? world.icon_size : (dir_to_wall & WEST ? -world.icon_size : 0))
		final_splatter.pixel_y = (dir_to_wall & NORTH ? world.icon_size : (dir_to_wall & SOUTH ? -world.icon_size : 0))
		final_splatter.alpha = 0
		animate(final_splatter, alpha = initial(final_splatter.alpha), time = 2)
	else if(istype(target, /obj/structure/window))
		var/obj/structure/window/bumped_window = target
		bumped_window.become_bloodied()
	else
		target.add_blood_DNA(GET_ATOM_BLOOD_DNA(src))

/obj/projectile/blood/proc/do_squirt(angle = rand(0,360), range = 3)
	src.range = range
	INVOKE_ASYNC(src, PROC_REF(fire), angle)
	return TRUE
