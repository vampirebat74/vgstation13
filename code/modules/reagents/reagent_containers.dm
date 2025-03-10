// Reagents to log when splashing non-mobs (all mob splashes are logged automatically)
var/list/LOGGED_SPLASH_REAGENTS = list(FUEL, THERMITE)

/obj/item/weapon/reagent_containers
	name = "Container"
	desc = "..."
	icon = 'icons/obj/chemical.dmi'
	icon_state = null
	w_class = W_CLASS_TINY
	heat_conductivity = 0.90
	var/amount_per_transfer_from_this = 5
	var/possible_transfer_amounts = list(5,10,15,25,30)
	var/volume = 30
	var/amount_per_imbibe = 5
	var/attack_mob_instead_of_feed //If true, the reagent container will be used as a melee weapon rather than as a vessel to feed another mob with (in attack()).

	var/image/ice_overlay = null
	var/ice_alpha = 64
	var/thermal_variation_from_environment = 0.055//how much of the environmental temperature do we want to match per entropy procs
	var/thermal_variation_modifier = 1//if set to 0, no entropy will occur in that container. More than 1 means it reaches room temperature quicker.

	var/controlled_splash = FALSE	//If true, splashing someone/something with the reagent container will only usr the current amount_per_transfer_from_this instead of all of it
									//Honestly we should try setting this to TRUE by default for all containers at some point, it's just convenient.

/obj/item/weapon/reagent_containers/verb/set_APTFT() //set amount_per_transfer_from_this
	set name = "Set transfer amount"
	set category = "Object"
	set src in range(0)
	if(usr.incapacitated())
		return
	var/N = input("Amount per transfer from this:","[src]") as null|anything in possible_transfer_amounts
	if (N)
		amount_per_transfer_from_this = N

/obj/item/weapon/reagent_containers/verb/empty_contents() //Just dump it out on the floor
	set name = "Dump contents"
	set category = "Object"
	set src in usr

	if(usr.incapacitated())
		to_chat(usr, "<span class='warning'>You can't do that while incapacitated.</span>")
		return
	if(!is_open_container(src))
		to_chat(usr, "<span class='warning'>You can't, \the [src] is closed.</span>")
		return
	if(src.is_empty())
		to_chat(usr, "<span class='warning'>\The [src] is empty.</span>")
		return
	if(isturf(usr.loc))
		if(reagents.total_volume > 10) //Beakersplashing only likes to do this sound when over 10 units
			playsound(src, 'sound/effects/slosh.ogg', 25, 1)
		usr.investigation_log(I_CHEMS, "has emptied \a [src] ([type]) containing [reagents.get_reagent_ids(1)] onto \the [usr.loc].")
		reagents.reaction(usr.loc)
		spawn()
			src.reagents.clear_reagents()
		usr.visible_message("<span class='warning'>[usr] splashes something onto the floor!</span>",
						 "<span class='notice'>You empty \the [src] onto the floor.</span>")

/obj/item/weapon/reagent_containers/proc/drain_into(mob/user, var/atom/where) //We're flushing our contents down the drain!
	if(usr.incapacitated())
		to_chat(usr, "<span class='warning'>You can't do that while incapacitated.</span>")
		return
	if(!is_open_container(src))
		to_chat(usr, "<span class='warning'>You can't, \the [src] is closed.</span>")
		return
	if(src.is_empty())
		to_chat(usr, "<span class='warning'>\The [src] is empty.</span>")
		return
	playsound(src, 'sound/effects/slosh.ogg', 25, 1)
	spawn()
		src.reagents.clear_reagents()
	to_chat(user, "<span class='notice'>You flush \the [src] down \the [where].</span>")


/obj/item/weapon/reagent_containers/AltClick()
	if(is_holder_of(usr, src) && possible_transfer_amounts)
		set_APTFT()
		return
	return ..()

/obj/item/weapon/reagent_containers/MiddleAltClick(var/mob/living/user)
	if(!Adjacent(user, src))
		return
	if(!reagents || !reagents.total_volume)
		to_chat(user, "<span class='warning'>\The [src] is desperately empty.</span>")
		return
	if (ishuman(user))
		var/mob/living/carbon/human/H = user
		if (H.species && (H.species.flags & SPECIES_NO_MOUTH))
			to_chat(user, "<span class='warning'>You stare at \the [src] intently. Wishing you had a mouth to interact with it.</span>")
			return
	thermal_entropy()
	blow_act(user)
	playsound(user, 'sound/effects/blow.ogg', 5, 1, -2)
	var/can_it_burn = round(user.get_splash_burn_damage(amount_per_imbibe, reagents.chem_temp))
	if (can_it_burn)
		user.visible_message("[user] blows on \the [src].","You blow on \the [src], helping it reach room temperature faster. <span class='warning'>It feels quite hot still...</span>")
	else if (reagents.chem_temp <= T0C)
		user.visible_message("[user] blows on \the [src].","You blow on \the [src], helping it reach room temperature faster. <span class='warning'>It feels pretty cold still...</span>")
	else
		user.visible_message("[user] blows on \the [src].","You blow on \the [src], helping it reach room temperature faster. <span class='notice'>Temperature seems safe...</span>")

/obj/item/weapon/reagent_containers/proc/blow_act(var/mob/living/user)
	return

/obj/item/weapon/reagent_containers/New()
	..()
	create_reagents(volume)
	all_reagent_containers.Add(src)

	if(!is_open_container(src))
		src.verbs -= /obj/item/weapon/reagent_containers/verb/empty_contents
	if(!possible_transfer_amounts)
		src.verbs -= /obj/item/weapon/reagent_containers/verb/set_APTFT

/obj/item/weapon/reagent_containers/Destroy()
	if(istype(loc, /obj/machinery/iv_drip))
		var/obj/machinery/iv_drip/holder = loc
		holder.remove_container()
	thermal_entropy_containers.Remove(src)
	all_reagent_containers.Remove(src)
	. = ..()

/obj/item/weapon/reagent_containers/attack_self(mob/user as mob)
	return

/obj/item/weapon/reagent_containers/attack(mob/M as mob, mob/user as mob, def_zone)

	if(attack_mob_instead_of_feed)
		return ..()

	//If harm intent, splash it on em, else try to feed em it
	if(!M.reagents)
		return

	if(!is_open_container())
		to_chat(user, "<span class='warning'>You can't, \the [src] is closed.</span>")//Added this here and elsewhere to prevent drinking, etc. from closed drink containers. - Hinaichigo
		return

	if(!src.reagents.total_volume)
		if(user.a_intent == I_HELP)
			to_chat(user, "<span class='warning'>\The [src] is empty.<span>")
			return 0
		else
			return ..()//empty bottle? hit them with it!

	if(user.a_intent != I_HELP)
		if(src.reagents)
			var/transfer_result
			if (controlled_splash)
				transfer_result = transfer(M, user, splashable_units = amount_per_transfer_from_this)
			else
				transfer_result = transfer(M, user, splashable_units = -1)
			if (transfer_result)
				splash_special()
			if (transfer_result >= 10)
				playsound(M, 'sound/effects/slosh.ogg', 25, 1)
			return 1


	else if(M == user)
		imbibe(user)
		return 1

	else if(ishuman(M) || iscorgi(M))
		user.visible_message("<span class='danger'>[user] attempts to feed [M] \the [src].</span>", "<span class='danger'>You attempt to feed [M] \the [src].</span>")

		if(!do_mob(user, M, 30))
			return 1

		user.visible_message("<span class='danger'>[user] feeds [M] \the [src].</span>", "<span class='danger'>You feed [M] \the [src].</span>")

		add_attacklogs(user, M, "force-fed", src, "amount:[amount_per_imbibe], container containing [reagentlist(src)]", admin_warn = FALSE)
		/*M.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been fed [src.name] by [user.name] ([user.ckey]) Reagents: [reagentlist(src)]</font>")
		user.attack_log += text("\[[time_stamp()]\] <font color='red'>Fed [M.name] by [M.name] ([M.ckey]) Reagents: [reagentlist(src)]</font>")
		log_attack("<font color='red'>[user.name] ([user.ckey]) fed [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>")*/

		if(reagents.total_volume)
			imbibe(M)

			return 0

/obj/item/weapon/reagent_containers/proc/splash_special()
	return


/**
 * This usually handles reagent transfer between containers and splashing the contents.
 * Please see `transfer()` for a general reusable proc for that.
 *
 * If you're wondering why you're splashing machinery that accepts beakers when
 * inserting them, it's because the machine is returning `FALSE` on `attackby()`,
 * which causes `afterattack()` to be called. Return 1 instead on those cases.
 *
 * If your container is splashing/transferring things at a distance, your `afterattack()`
 * isn't checking for adjacency. For that, check that `adjacency_flag` is `TRUE`.
 */
/obj/item/weapon/reagent_containers/afterattack(var/obj/target, var/mob/user, var/adjacency_flag, var/click_params)
	return

/**
 * Transfer reagents between reagent_containers/reagent_dispensers.
 */
/proc/transfer_sub(var/atom/source, var/atom/target, var/amount, var/mob/user, var/log_transfer = FALSE)
	// Typecheck shenanigans
	var/source_empty
	var/target_full

	if (istype(source, /obj/item/weapon/reagent_containers))
		var/obj/item/weapon/reagent_containers/S = source
		source_empty = S.is_empty()
	else if (istype(source, /obj/structure/reagent_dispensers))
		var/obj/structure/reagent_dispensers/S = source
		source_empty = S.is_empty()
	else
		//ASSERT(istype(source.reagents))
		source_empty = source.reagents.is_empty()
		//warning("Called transfer_sub() with a non-compatible source type ([source.type], [source], \ref[source])")
		//return


	if (istype(target, /obj/item/weapon/reagent_containers))
		var/obj/item/weapon/reagent_containers/T = target
		target_full = T.is_full()
	// Reagent dispensers can't be refilled (yet) through normal means (TODO?)
	/*else if (istype(target, /obj/structure/reagent_dispensers))
		var/obj/structure/reagent_dispensers/T = target
		target_full = T.is_full()*/
	else
		if(ismob(target))
			return null
		//ASSERT(istype(target.reagents))
		if(!istype(target.reagents))
			return
		target_full = target.reagents.is_full()
		//warning("Called transfer_sub() with a non-compatible target type ([target.type], [target], \ref[target])")
		//return

	// Actual transfer checks
	if (source_empty)
		to_chat(user, "<span class='warning'>\The [source] is empty.</span>")
		return -1

	if (target_full)
		to_chat(user, "<span class='warning'>\The [target] is full.</span>")
		return -1

	return source.reagents.trans_to(target, amount, log_transfer = log_transfer, whodunnit = user)

/**
 * Helper proc to handle reagent splashes. A negative `amount` will splash all the reagents.
 */

/proc/splash_sub(var/datum/reagents/reagents, var/atom/target, var/amount, var/mob/user = null)
	if (amount == 0 || reagents.is_empty())
		if(user)
			to_chat(user, "<span class='warning'>There's nothing to splash with!</span>")
		return -1

	var/datum/organ/external/affecting = user && user.zone_sel ? user.zone_sel.selecting : null //Find what the player is aiming at

	reagents.reaction(target, TOUCH, amount_override = max(0,amount), zone_sels = affecting ? list(affecting) : ALL_LIMBS)

	if(user)
		user.investigation_log(I_CHEMS, "has splashed [amount > 0 ? "[amount]u of [reagents.get_reagent_ids()]" : "[reagents.get_reagent_ids(1)]"] from \a [reagents.my_atom] \ref[reagents.my_atom] onto \the [target][ishuman(target) ? "'s [parse_zone(affecting)]" : ""].")
	if(amount > 0)
		reagents.remove_any(amount)
	else
		reagents.clear_reagents()
	if(user)
		if(user.Adjacent(target))
			user.visible_message("<span class='warning'>\The [target] has been splashed with something by [user]!</span>",
			                     "<span class='notice'>You splash the solution onto \the [target].</span>")

//Define this wrapper as well to allow for proc overrides eg. for frying pan
/obj/item/weapon/reagent_containers/proc/container_splash_sub(var/datum/reagents/reagents, var/atom/target, var/amount, var/mob/user = null)
	return splash_sub(reagents, target, amount, user)

/**
 * Transfers reagents to other containers/from dispensers. Handles splashing as well.
 *
 * Use this to avoid having duplicate code on every container. Note that this procedure doesn't check for
 * adjacency between the source and the target.
 *
 * @param target What to check for transferring/splashing.
 * @param user The mob performing the transfer.
 * @param can_send Whether we are allowed to transfer our reagents to the target.
 * @param can_receive Whether we are allowed to transfer from `reagent_dispensers`
 * @param splashable_units How many units of reagents should be splashed. -1 for all of them, 0 to disable splashing.
 *
 * @return If we have transferred reagents, the amount transferred; otherwise, -1 if the transfer has failed, 0 if was a splash.
 */
/obj/item/weapon/reagent_containers/proc/transfer(var/atom/target, var/mob/user, var/can_send = TRUE, var/can_receive = TRUE, var/splashable_units = 0)
	if (!istype(target) || !is_open_container())
		return -1

	var/success
	// Transfer from dispenser or cooking machine
	if (can_receive)
		if(istype(target, /obj/structure/reagent_dispensers))
			var/obj/structure/reagent_dispensers/S = target
			if(S.can_transfer(src, user))
				var/tx_amount = transfer_sub(target, src, S.amount_per_transfer_from_this, user)
				if (tx_amount > 0)
					to_chat(user, "<span class='notice'>You fill \the [src][src.is_full() ? " to the brim" : ""] with [tx_amount] units of the contents of \the [target].</span>")
				return tx_amount
		if(reagents && reagents.is_empty() && istype(target, /obj/machinery/cooking/deepfryer))
			var/tx_amount = transfer_sub(target, src, reagents.maximum_volume, user)
			if (tx_amount > 0)
				to_chat(user, "<span class='notice'>You fill \the [src][src.is_full() ? " to the brim" : ""] with [tx_amount] units of the contents of \the [target].</span>")
				var/obj/machinery/cooking/deepfryer/F = target
				F.empty_icon()
			return tx_amount
	// Transfer to container
	if (can_send /*&& target.reagents**/)
		var/obj/container = target
		if (!container.is_open_container() && istype(container,/obj/item/weapon/reagent_containers) && !istype(container,/obj/item/weapon/reagent_containers/food/snacks))
			return -1
		if(target.is_open_container())
			success = transfer_sub(src, target, amount_per_transfer_from_this, user, log_transfer = TRUE)

		if(success)
			if (success > 0)
				to_chat(user, "<span class='notice'>You transfer [success] units of the solution to \the [target].</span>")

			return (success)
	if(!success)
		// Mob splashing
		if(splashable_units != 0)
			var/to_splash = reagents.total_volume
			if(ismob(target))
				if (src.is_empty() || !target.reagents)
					return -1

				var/mob/living/M = target

				// Log the 'attack'
				var/list/splashed_reagents = english_list(get_reagent_names())
				add_logs(user, M, "splashed", admin = TRUE, object = src, addition = "Reagents: [splashed_reagents]")

				// Splash the target
				container_splash_sub(reagents, M, splashable_units, user)
				return (to_splash)
			// Non-mob splashing
			else
				if(!src.is_empty())
					for (var/reagent_id in LOGGED_SPLASH_REAGENTS)
						if (reagents.has_reagent(reagent_id))
							add_gamelogs(user, "poured '[reagent_id]' onto \the [target]", admin = TRUE, tp_link = TRUE, tp_link_short = FALSE, span_class = "danger")

					// Splash the thing
					container_splash_sub(reagents, target, splashable_units, user)
					return (to_splash)
	return 0

/obj/item/weapon/reagent_containers/proc/is_empty()
	if(!reagents)
		return TRUE
	return reagents.total_volume <= 0

/obj/item/weapon/reagent_containers/proc/is_full()
	if(!reagents)
		return FALSE
	return reagents.total_volume >= reagents.maximum_volume

/obj/item/weapon/reagent_containers/proc/can_transfer_an_APTFT()
	return reagents.total_volume >= amount_per_transfer_from_this

/obj/item/weapon/reagent_containers/proc/get_reagent_names()
	var/list/reagent_names = list()
	for (var/datum/reagent/R in reagents.reagent_list)
		reagent_names += R.name

	return reagent_names

/obj/item/weapon/reagent_containers/proc/get_reagent_ids()
	var/list/reagent_ids = list()
	for (var/datum/reagent/R in reagents.reagent_list)
		reagent_ids += R.id

	return reagent_ids

/obj/item/weapon/reagent_containers/proc/reagentlist(var/obj/item/weapon/reagent_containers/snack) //Attack logs for regents in pills
	var/data
	if(snack.reagents.reagent_list && snack.reagents.reagent_list.len) //find a reagent list if there is and check if it has entries
		for (var/datum/reagent/R in snack.reagents.reagent_list) //no reagents will be left behind
			data += "[R.id]([R.volume] unit\s); " //Using IDs because SOME chemicals(I'm looking at you, chlorhydrate-beer) have the same names as other chemicals.
		return data
	else
		return "No reagents"

/obj/item/weapon/reagent_containers/proc/fits_in_iv_drip()
	return FALSE

/obj/item/weapon/reagent_containers/proc/should_qdel_if_empty()
	return FALSE

/obj/item/weapon/reagent_containers/proc/imbibe(mob/user) //Drink the liquid within
	if(!can_drink(user))
		return 0
	to_chat(user, "<span  class='notice'>You swallow a gulp of \the [src].</span>")
	playsound(user.loc,'sound/items/drink.ogg', rand(10,50), 1)

	if(isrobot(user))
		reagents.remove_any(amount_per_imbibe)
		reagents.reaction(user, TOUCH)
		return 1
	if(reagents.total_volume)
		reagents.reaction(user, INGEST, amount_override = min(reagents.total_volume,amount_per_imbibe)/(reagents.reagent_list.len))
		spawn(5)
			if(reagents)
				reagents.adjust_consumed_reagents_temp()
				reagents.trans_to(user, amount_per_imbibe)
				reagents.reset_consumed_reagents_temp()

	return 1

/obj/item/weapon/reagent_containers/proc/can_drink(mob/user)
	if (ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.species.flags & SPECIES_NO_MOUTH)
			H.visible_message("<span class='warning'>[H] can't drink without a mouth!</span>","<span class='warning'>You can't drink without a mouth!</span>")
			return 0
		if(H.species.chem_flags & NO_DRINK)
			reagents.reaction(get_turf(H), TOUCH)
			H.visible_message("<span class='warning'>The contents in [src] fall through and splash onto the ground, what a mess!</span>")
			reagents.remove_any(amount_per_imbibe) //Should this really be here?
			return 0


	return 1

/obj/item/weapon/reagent_containers/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	reagents.heating(1000, exposed_temperature)
	..()
	process_temperature()

/obj/item/weapon/reagent_containers/attackby(obj/item/I, mob/user, params)
	..()
	attempt_heating(I, user)
	process_temperature()

/obj/item/weapon/reagent_containers/attempt_heating(atom/A, mob/user)
	var/temperature = A.is_hot()
	if(temperature && reagents)
		reagents.heating(A.thermal_energy_transfer(), temperature)
		if(user)
			to_chat(user, "<span class='notice'>You heat \the [src] with \the [A].</span>")

/obj/item/weapon/reagent_containers/Hear(var/datum/speech/speech, var/rendered_speech="")
	. = ..()
	for(var/datum/reagent/temp_hearer/R in reagents.reagent_list)
		R.parent_heard(speech, rendered_speech)
	//We have to check for a /mob/virtualhearer/one_time here, and kill it ourselves. This is fairly bad OOP.
	if(virtualhearer && istype(virtualhearer, /mob/virtualhearer/one_time))
		removeHear()

/obj/item/weapon/reagent_containers/on_reagent_change()
	. = ..()
	process_temperature()

////////////THERMAL ENTROPY///////////////////////////////////////////////////////////////////////////////////////////////////

//an overly simple thermal entropy proc that lets food match the temperature of their environnement over time
//we don't send the temperature difference back to the environnement because frankly it's not gonna matter in 99.999% of the cases.
//furthermore, we stop looping once the temperature is less than a degree away from the environment, until we get moved or picked up.
//won't resume on passive temperature changes in a room, but we can always add a subsystem later that checks for additional temperature changes every minute or so I guess
/obj/item/weapon/reagent_containers/process_temperature()
	thermal_entropy_containers |= src

/obj/item/weapon/reagent_containers/proc/thermal_entropy()
	set waitfor = FALSE

	if (!reagents || !reagents.total_volume)
		thermal_entropy_containers.Remove(src)
		update_temperature_overlays()
		return

	var/datum/gas_mixture/air = return_air()

	if (!air)
		thermal_entropy_containers.Remove(src)
		return

	var/diff = air.temperature - reagents.chem_temp

	if (!isturf(loc) && (air.pressure < 100))//low pressure environments slow down entropy, unless the item is laid directly onto the floor so space meat remains frozen until brought in
		diff *= air.pressure/100

	//we only bother if there's less than a 1 degree difference
	if (abs(diff) < 2)
		thermal_entropy_containers.Remove(src)

	//based on newton's law of cooling
	reagents.chem_temp = reagents.chem_temp + diff * thermal_variation_from_environment * thermal_variation_modifier

	if(!(reagents.skip_flags & SKIP_RXN_CHECK_ON_HEATING))
		reagents.handle_reactions()

	update_icon()

/obj/item/weapon/reagent_containers/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, var/glide_size_override = 0)
	..()
	process_temperature()

/obj/item/weapon/reagent_containers/forceMove(atom/destination, step_x = 0, step_y = 0, no_tp = FALSE, harderforce = FALSE, glide_size_override = 0)
	..()
	process_temperature()

/obj/item/weapon/reagent_containers/dropped(var/mob/user)
	..()
	process_temperature()

/obj/item/weapon/reagent_containers/pickup(var/mob/user)
	..()
	process_temperature()

/obj/item/weapon/reagent_containers/update_temperature_overlays()
	if(reagents && reagents.total_volume)
		if (reagents.chem_temp <= (T0C+2))
			ice_alpha = 96 + clamp((-64*((reagents.chem_temp-T0C)/80)),0,64)
			if(!ice_overlays["[type][icon_state]"])
				set_ice_overlay()
			else
				update_ice_overlay()
		steam_spawn_adjust(reagents.chem_temp)
	else
		remove_particles("Steam")

///////////ICE OVERLAY///////////////////////////////////////////////////////////////////////////////////////////////////////////
//appears when the food item's reagents' temperature falls to 0°C or below
//based on how blood overlays are generated

var/global/list/image/ice_overlays = list()
/obj/item/weapon/reagent_containers/proc/set_ice_overlay()
	if(update_ice_overlay())
		return

	var/icon/I = new /icon(icon, icon_state)
	//fills the icon_state with white (except where it's transparent)
	I.Blend(rgb(255,255,255),ICON_ADD)
	//inspired by urist's old cult rune drawing method, will let us add a 1px ice border around the object
	var/list/border_pixels = list()
	for(var/x = 1, x <= 32, x++)
		for(var/y = 1, y <= 32, y++)
			var/p = I.GetPixel(x, y)

			if(p == null)
				var/n = I.GetPixel(x, y + 1)
				var/s = I.GetPixel(x, y - 1)
				var/e = I.GetPixel(x + 1, y)
				var/w = I.GetPixel(x - 1, y)

				if(n == "#ffffff" || s == "#ffffff" || e == "#ffffff" || w == "#ffffff")
					border_pixels += list(list(x,y))
	for (var/list/L in border_pixels)
		I.DrawBox(rgb(255, 255, 255), L[1], L[2])
	//adds the ice texture
	I.Blend(new /icon('icons/effects/effects.dmi', "ice"),ICON_MULTIPLY)

	var/image/img = image(I)
	img.name = "ice_overlay"
	ice_overlays["[type][icon_state]"] = img
	update_ice_overlay()

/obj/item/weapon/reagent_containers/proc/update_ice_overlay()
	if(ice_overlays["[type][icon_state]"])
		if (ice_overlay)
			overlays -= ice_overlay
		ice_overlay = image(ice_overlays["[type][icon_state]"])
		ice_overlay.appearance_flags = RESET_COLOR|RESET_ALPHA
		ice_overlay.alpha = ice_alpha
		overlays += ice_overlay
		return 1

///////////STEAM PARTICLES/////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/weapon/reagent_containers/proc/steam_spawn_adjust(var/_temp)
	if (!("Steam" in particle_systems))
		add_particles("Steam")
	var/obj/abstract/particles_holder/steam_holder = particle_systems["Steam"]
	if (_temp < STEAMTEMP)
		steam_holder.particles.spawning = 0
	else
		steam_holder.particles.spawning = clamp(0.1 + 0.002 * (_temp - STEAMTEMP),0.1,0.5)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
