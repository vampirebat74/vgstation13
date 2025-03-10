
//Few global vars to track the blob
var/blob_tiles_grown_total = 0
var/list/blobs = list()
var/list/blob_cores = list()
var/list/blob_nodes = list()
var/list/blob_resources = list()
var/list/blob_overminds = list()


/obj/effect/blob
	name = "blob"
	icon = 'icons/mob/blob/blob_64x64.dmi'//HALLOWEEN
	icon_state = "center"
	luminosity = 2
	desc = "A part of a blob."
	density = 0 //Necessary for spore pathfinding
	opacity = 0
	anchored = 1
	penetration_dampening = 17
	mouse_opacity = 1
	pass_flags_self = PASSBLOB
	health = 20
	maxHealth = 20
	var/health_timestamp = 0
	var/brute_resist = 4
	var/fire_resist = 1
	pixel_x = -WORLD_ICON_SIZE/2
	pixel_y = -WORLD_ICON_SIZE/2
	layer = BLOB_BASE_LAYER
	plane = BLOB_PLANE
	var/spawning = 2
	var/dying = 0
	var/mob/camera/blob/overmind = null
	var/destroy_sound = "sound/effects/blobsplat.ogg"

	var/looks = "new"

	// A note to the beam processing shit.
	var/custom_process=0

	var/time_since_last_pulse

	var/icon_new = "center"
	var/icon_classic = "blob"

	var/manual_remove = 0
	var/icon_size = 64

	var/asleep = FALSE

	var/meat = /obj/item/weapon/reagent_containers/food/snacks/meat/blob
	var/meat_drop_factor = 1	// A weapon of force 8 and sharpness 0.5 will hack off meat with a probability of 4% at drop factor 1

/obj/effect/blob/blob_act()
	return


//obj/effect/blob/New(turf/loc,newlook = "new",no_morph = 0) HALLOWEEN
/obj/effect/blob/New(turf/loc,newlook = null,no_morph = 0)
	if(newlook)
		looks = newlook
	update_looks()
	blobs += src
	time_since_last_pulse = world.time

	if(icon_size == 64)
		if(!asleep && spawning && !no_morph && !istype(src, /obj/effect/blob/core))
			icon_state = initial(icon_state) + "_spawn"
			spawn(10)
				spawning = 0//for sprites
				icon_state = initial(icon_state)
				src.update_icon(1)
		else
			spawning = 0
			update_icon()
			for(var/obj/effect/blob/B in orange(src,1))
				B.update_icon()

	..(loc)
	for(var/atom/A in loc)
		A.blob_act(0,src)

	blob_tiles_grown_total++


/obj/effect/blob/Destroy()
	dying = 1
	blobs -= src

	if(icon_size == 64)
		for(var/atom/movable/overlay/O in loc)
			qdel(O)

		for(var/obj/effect/blob/B in orange(loc,1))
			B.update_icon()
			if(!spawning)
				anim(target = B.loc, a_icon = icon, flick_anim = "connect_die", sleeptime = 50, direction = get_dir(B,src), plane = src.plane, lay = layer+0.3, offX = -16, offY = -16, col = "red")

	if(!manual_remove)
		for(var/obj/effect/blob/core/C in range(loc,4))
			if((C != src) && C.overmind && (C.overmind.blob_warning <= world.time))
				C.overmind.blob_warning = world.time + (10 SECONDS)
				to_chat(C.overmind,"<span class='danger'>A blob died near your core!</span> <b><a href='?src=\ref[C.overmind];blobjump=\ref[loc]'>(JUMP)</a></b>")

	overmind = null
	..()

/obj/effect/blob/projectile_check()
	return PROJREACT_BLOB

/obj/effect/blob/Cross(atom/movable/mover, turf/target, height=1.5, air_group = 0)
	if(air_group || (height==0))
		return 1
	if(istype(mover) && mover.checkpass(pass_flags_self))
		return 1
	return 0

/obj/effect/blob/beam_connect(var/obj/effect/beam/B)
	..()
	last_beamchecks["\ref[B]"]=world.time+1
	apply_beam_damage(B) // Contact damage for larger beams (deals 1/10th second of damage)
	if(!custom_process && !(src in processing_objects))
		processing_objects.Add(src)


/obj/effect/blob/beam_disconnect(var/obj/effect/beam/B)
	..()
	apply_beam_damage(B)
	last_beamchecks.Remove("\ref[B]") // RIP
	update_health()
	update_icon()
	if(beams.len == 0)
		if(!custom_process)
			processing_objects.Remove(src)

/obj/effect/blob/apply_beam_damage(var/obj/effect/beam/B)
	var/lastcheck=last_beamchecks["\ref[B]"]

	// Standard damage formula / 2
	var/damage = ((world.time - lastcheck)/10)  * (B.get_damage() / 2)

	// Actually apply damage
	health -= damage

	// Update check time.
	last_beamchecks["\ref[B]"]=world.time

/obj/effect/blob/handle_beams()
	// New beam damage code (per-tick)
	for(var/obj/effect/beam/B in beams)
		apply_beam_damage(B)
	update_health()
	update_icon()

/obj/effect/blob/can_mech_drill()
	return TRUE

/obj/effect/blob/process()
	handle_beams()
	Life()

/obj/effect/blob/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	..()
	var/damage = clamp(0.01 * exposed_temperature / fire_resist, 0, 4 - fire_resist)
	if(damage)
		health -= damage
		update_health()
		update_icon()

/obj/effect/blob/ex_act(severity)
	var/damage = 150
	health -= ((damage/brute_resist) - (severity * 5))
	update_health()
	update_icon()

/obj/effect/blob/bullet_act(var/obj/item/projectile/Proj, var/def_zone, var/damage_override = null)
	. = ..()
	var/damage = isnull(damage_override) ? Proj.damage : damage_override
	switch(Proj.damage_type)
		if(BRUTE)
			health -= (damage/brute_resist)
		if(BURN)
			health -= (damage/fire_resist)

	update_health()
	update_icon()

/obj/effect/blob/attackby(var/obj/item/weapon/W, var/mob/living/user)
	user.do_attack_animation(src, W)
	user.delayNextAttack(10)
	playsound(src, 'sound/effects/attackblob.ogg', 50, 1)
	src.visible_message("<span class='warning'><B>The [src.name] has been attacked with \the [W][(user ? " by [user]." : ".")]</span>")
	var/damage = 0
	switch(W.damtype)
		if("fire")
			damage = (W.force / max(src.fire_resist,1))
			if(iswelder(W) || istype(W, /obj/item/weapon/pickaxe/plasmacutter))
				playsound(src, 'sound/effects/blobweld.ogg', 100, 1)
		if("brute")
			damage = (W.force / max(src.brute_resist,1))
			if(prob((W.sharpness * W.force) * meat_drop_factor))
				var/obj/item/I = new meat()
				I.forceMove(src.loc)
				if (!(src.looks in blob_diseases))
					CreateBlobDisease(src.looks)
				var/datum/disease2/disease/D = blob_diseases[src.looks]
				I.infect_disease2(D)
				I.throw_at(user, 1, 1)

	health -= damage
	update_health()
	update_icon()

/obj/effect/blob/bullet_act(var/obj/item/projectile/Proj, var/def_zone, var/damage_override = null)
	. = ..()
	var/damage = isnull(damage_override) ? Proj.damage : damage_override
	switch(Proj.damage_type)
		if(BRUTE)
			health -= (damage/brute_resist)
		if(BURN)
			health -= (damage/fire_resist)

	update_health()
	update_icon()

/obj/effect/blob/hitby(var/atom/movable/AM,var/speed = 5)
	if(isitem(AM))
		var/obj/item/I = AM
		var/damage = I.throwforce*speed/5
		switch(I.damtype)
			if(BRUTE)
				health -= (damage/brute_resist)
				playsound(src, 'sound/effects/attackblob.ogg', 50, 1)
			if(BURN)
				health -= (damage/fire_resist)
				playsound(src, 'sound/effects/blobweld.ogg', 100, 1)
		update_health()
		update_icon()

/obj/effect/blob/attack_animal(var/mob/living/simple_animal/user)
	user.delayNextAttack(8)
	user.do_attack_animation(src, user)
	user.visible_message("<span class='danger'>\The [user] [user.attacktext] \the [src].</span>")
	switch(user.melee_damage_type)
		if (BRUTE)
			health -= (user.get_unarmed_damage(src)/brute_resist)
			playsound(src, 'sound/effects/attackblob.ogg', 50, 1)
		if (BURN)
			health -= (user.get_unarmed_damage(src)/fire_resist)
			playsound(src, 'sound/effects/blobweld.ogg', 100, 1)
	update_health()
	update_icon()

/obj/effect/blob/attack_hand(var/mob/living/carbon/human/user)
	if (user.a_intent == I_HURT)
		user.delayNextAttack(8)
		user.do_attack_animation(src, user)
		var/datum/species/S = user.get_organ_species(user.get_active_hand_organ())
		user.visible_message("<span class='danger'>\The [user] [S.attack_verb] \the [src].</span>")
		health -= (user.get_unarmed_damage(src)/brute_resist)
		playsound(src, 'sound/effects/attackblob.ogg', 50, 1)
		update_health()
		update_icon()

/obj/effect/blob/attack_paw(var/mob/living/carbon/monkey/user)
	if (user.a_intent == I_HURT)
		if(user.wear_mask?.is_muzzle)
			to_chat(user, "<span class='notice'>You can't do this with \the [user.wear_mask] on!</span>")
			return
		user.delayNextAttack(8)
		user.do_attack_animation(src, user)
		user.visible_message("<span class='danger'>\The [user] [user.attack_text] \the [src].</span>")
		health -= (user.get_unarmed_damage(src)/brute_resist)
		playsound(src, 'sound/effects/attackblob.ogg', 50, 1)
		update_health()
		update_icon()

/obj/effect/blob/attack_alien(var/mob/living/carbon/alien/humanoid/user)
	if(istype(user, /mob/living/carbon/alien/larva))
		return
	user.delayNextAttack(8)
	user.do_attack_animation(src, user)
	var/alienverb = pick(list("slam", "rip", "claw"))
	user.visible_message("<span class='warning'>[user] [alienverb]s \the [src].</span>")
	health -= (rand(15,30)/brute_resist)
	playsound(src, 'sound/effects/attackblob.ogg', 50, 1)
	update_health()
	update_icon()

/obj/effect/blob/update_icon(var/spawnend = 0)
	if(icon_size == 64)
		if(health < maxHealth)
			var/hurt_percentage = round((health * 100) / maxHealth)
			var/hurt_icon
			switch(hurt_percentage)
				if(0 to 25)
					hurt_icon = "hurt_100"
				if(26 to 50)
					hurt_icon = "hurt_75"
				if(51 to 75)
					hurt_icon = "hurt_50"
				else
					hurt_icon = "hurt_25"
			overlays += image(icon,hurt_icon)

/obj/effect/blob/proc/update_looks(var/right_now = 0)
	switch(blob_looks_admin[looks]) //blob_looks_admin should have every possible blob skin
		if(64)
			icon_state = icon_new
			icon_size = 64
			pixel_x = -WORLD_ICON_SIZE/2
			pixel_y = -WORLD_ICON_SIZE/2
			layer = initial(layer)
			if(right_now)
				spawning = 0
		if(32)
			icon_state = icon_classic
			icon_size = 32
			pixel_x = 0
			pixel_y = 0
			layer = OBJ_LAYER
			overlays.len = 0

	blob_looks(looks)

	if(right_now)
		update_icon()

/atom/proc/blob_looks(var/looks = "new")
	switch(looks)
		if("new")
			icon = 'icons/mob/blob/blob_64x64.dmi'
		if("classic")
			icon = 'icons/mob/blob/blob.dmi'
		if("adminbus")
			icon = adminblob_icon
		if("clownscape")
			icon = 'icons/mob/blob/blob_honkscape.dmi'
		if("AME")
			icon = 'icons/mob/blob/blob_AME.dmi'
		if("AME_new")
			icon = 'icons/mob/blob/blob_AME_64x64.dmi'
		if("skelleton")
			icon = 'icons/mob/blob/blob_skelleton_64x64.dmi'
		if("secblob")
			icon = 'icons/mob/blob/blob_sec.dmi'
		//<----------------------------------------------------------------------------DEAR SPRITERS, THIS IS WHERE YOU ADD YOUR NEW BLOB DMIs
		/*EXAMPLES
		if("fleshy")
			icon = 'icons/mob/blob_fleshy.dmi'
		if("machineblob")
			icon = 'icons/mob/blob_machine.dmi'
		*/


var/list/blob_looks_admin = list(//Options available to admins
	"new" = 64,
	"classic" = 32,
	"adminbus" = adminblob_size,
	"clownscape" = 32,
	"AME" = 32,
	"AME_new" = 64,
	"skelleton" = 64,
	"secblob" = 32,
	)

var/list/blob_looks_player = list(//Options available to players
	"new" = 64,
	"classic" = 32,
	)
	//<---------------------------------------ALSO ADD THE NAME OF YOUR BLOB LOOKS HERE, AS WELL AS THE RESOLUTION OF THE DMIS (64 or 32)

/obj/effect/blob/proc/Life()
	return

/obj/effect/blob/proc/aftermove()
	for(var/obj/effect/blob/B in loc)
		if(B != src)
			manual_remove = 1
			qdel(src)
			return
	update_icon()
	for(var/obj/effect/blob/B in orange(src,1))
		B.update_icon()

/obj/effect/blob/proc/Pulse(var/pulse = 0, var/origin_dir = 0, var/mob/camera/blob/source = null)

	time_since_last_pulse = world.time

	//set background = 1
	VisiblePulse(pulse)

	for(var/mob/M in loc)
		M.blob_act(0,src)
	for(var/obj/O in loc)
		for(var/i in 1 to max(1,(4-pulse)))
			O.blob_act(TRUE) //Hits up to 4 times if adjacent to a core
	if(run_action())//If we can do something here then we dont need to pulse more
		return

	if(pulse > 30)
		return//Inf loop check

	//Looking for another blob to pulse
	var/list/dirs = cardinal.Copy()
	dirs.Remove(origin_dir)//Dont pulse the guy who pulsed us
	for(var/i in 1 to 4)
		if(!dirs.len)
			break
		var/dirn = pick_n_take(dirs)
		var/turf/T = get_step(src, dirn)
		var/obj/effect/blob/B = locate() in T
		if(!B)
			expand(T,TRUE,source)//No blob here so try and expand
			return
		spawn(2)
			B.Pulse((pulse+1),get_dir(src.loc,T),source)
		return


/obj/effect/blob/proc/VisiblePulse(var/pulse = 0)
	var/pulse_strength = 0.5 / max(1,pulse/2)
	animate(src, color = list(1+pulse_strength,0,0,0,0,1+pulse_strength,0,0,0,0,1+pulse_strength,0,0,0,0,1,0,0,0,0), time = 4, easing = SINE_EASING|EASE_OUT)
	animate(color = list(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0), time = 4, easing = SINE_EASING)

/obj/effect/blob/proc/run_action()
	return 0

/obj/effect/blob/proc/expand(var/turf/T = null, var/prob = 1, var/mob/camera/blob/source, var/manual = FALSE)
	if(prob && !prob(health))
		return
	if(!manual) //Manually-expanded blobs don't care about 50% chance to not expand in space.
		if(istype(T, /turf/space) && prob(50))
			return
	if(!T)
		var/list/dirs = cardinal.Copy()
		for(var/i in 1 to 4)
			var/dirn = pick_n_take(dirs)
			T = get_step(src, dirn)
			if(!(locate(/obj/effect/blob) in T))
				break
			else
				T = null

	if(!T)
		return 0
	var/obj/effect/blob/normal/B = new(src.loc, newlook = looks)
	B.setDensity(TRUE)

	if(icon_size == 64)
		if(istype(src,/obj/effect/blob/normal))
			var/num = rand(1,100)
			num /= 10000
			B.layer = layer - num

	if(T.Enter(B, loc, TRUE))//Attempt to move into the tile //This should probably just actually call Move() instead
		B.setDensity(initial(B.density))
		if(icon_size == 64)
			spawn(1)
				B.dir = get_dir(loc,T)
				B.forceMove(T)
				B.aftermove()
				if(B.spawning > 1)
					B.spawning = 1
				if(istype(T,/turf/simulated/floor))
					var/turf/simulated/floor/F = T
					F.burn_tile()
		else
			B.forceMove(T)
			if(istype(T,/turf/simulated/floor))
				var/turf/simulated/floor/F = T
				F.burn_tile()
	else //If we cant move in hit the turf
		if(!source || !source.restrain_blob)
			T.blob_act(0,src) //Don't attack the turf if our source mind has that turned off.
		B.manual_remove = 1
		B.Delete()

	for(var/atom/A in T)//Hit everything in the turf
		A.blob_act(0,src)
	return 1


/obj/effect/blob/proc/change_to(var/type, var/mob/camera/blob/M = null, var/special = FALSE)
	if(!ispath(type))
		error("[type] is an invalid type for the blob.")
	if(special) //Send additional information to the New()
		new type(src.loc, 200, null, 1, 1, newlook = looks)
	else
		var/obj/effect/blob/B = new type(src.loc, newlook = looks)
		B.dir = dir
	spawning = 1//so we don't show red severed connections
	manual_remove = 1
	Delete()
	return

/obj/effect/blob/proc/Delete()
	qdel(src)

/obj/effect/blob/proc/update_health()
	if(asleep && (health < maxHealth))
		for (var/obj/effect/blob/B in range(7,src))
			B.asleep = FALSE
	if(!dying && (health <= 0))
		dying = 1
		if(get_turf(src))
			playsound(src, destroy_sound, 50, 1)
		Delete()

//////////////////NORMAL BLOBS/////////////////////////////////
/obj/effect/blob/normal
	luminosity = 2
	health = 21
	layer = BLOB_BASE_LAYER

/obj/effect/blob/normal/New(turf/loc,newlook = null,no_morph = 0)
	if (!asleep)
		dir = pick(cardinal)
	..()

/obj/effect/blob/normal/Delete()
	..()

/obj/effect/blob/normal/update_icon(var/spawnend = 0)
	if(icon_size == 64)
		spawn(1)
			overlays.len = 0
			underlays.len = 0

			underlays += image(icon,"roots")

			if(!spawning)
				for(var/obj/effect/blob/B in orange(src,1))
					if(B.spawning == 1)
						anim(target = loc, a_icon = icon, flick_anim = "connect_spawn", sleeptime = 15, direction = get_dir(src,B), lay = layer, offX = -16, offY = -16,plane = plane)
						spawn(8)
							update_icon()
					else if(!B.dying && !B.spawning)
						if(spawnend)
							anim(target = loc, a_icon = icon, flick_anim = "connect_spawn", sleeptime = 15, direction = get_dir(src,B), lay = layer, offX = -16, offY = -16,plane = plane)
						else
							if(istype(B,/obj/effect/blob/core))
								overlays += image(icon,"connect",dir = get_dir(src,B))
							else
								overlays += image(icon,"connect",dir = get_dir(src,B))

			if(spawnend)
				spawn(10)
					update_icon()

			..()
	else
		if(health <= 15)
			icon_state = "blob_damaged"

///////////////////////BLOB SPORE DISEASE//////////////////////////////////
var/list/blob_diseases = list()

/proc/CreateBlobDisease(var/looks)
	var/datum/disease2/disease/S = new
	S.form = "Spores"
	S.infectionchance = 95
	S.infectionchance_base = 95
	S.stageprob = 0//single-stage
	S.stage_variance = 0
	S.max_stage = 1
	S.can_kill = list()

	var/datum/disease2/effect/blob_spores/E = new /datum/disease2/effect/blob_spores
	E.looks = looks
	S.effects += E

	S.antigen = list(pick(antigen_family(pick(ANTIGEN_RARE,ANTIGEN_ALIEN))))
	S.antigen |= pick(antigen_family(pick(ANTIGEN_RARE,ANTIGEN_ALIEN)))

	S.spread = SPREAD_BLOOD
	S.uniqueID = rand(0,9999)
	S.subID = rand(0,9999)

	S.strength = rand(70,100)
	S.robustness = 100

	S.color = "#99CB99"
	S.pattern = 2
	S.pattern_color = "#FFC977"

	log_debug("Creating Spores #[S.uniqueID]-[S.subID].")
	S.log += "<br />[timestamp()] Created<br>"

	S.origin = "Blob ([looks])"

	S.mutation_modifier = 0

	S.update_global_log()

	blob_diseases[looks] = S

///////////////////////////////////////////////////////////////////////////
