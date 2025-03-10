/*
 * The 'fancy' path is for objects like donut boxes that show how many items are in the storage item on the sprite itself
 * .. Sorry for the shitty path name, I couldnt think of a better one.
 *
 * WARNING: var/icon_type is used for both examine text and sprite name. Please look at the procs below and adjust your sprite names accordingly
 *		TODO: Cigarette boxes should be ported to this standard
 *
 * Contains:
 *		Donut Box
 *		Egg Box
 *		Candle Box
 *		Crayon Box
 *		Cigarette Box
 *		Food Box
 *		Chicken Bucket
 *		Slider Box
 */

/obj/item/weapon/storage/fancy/
	icon = 'icons/obj/food_container.dmi'
	icon_state = "donutbox6"
	name = "donut box"
	var/icon_type = "donut"
	var/plural_type = "s" //Why does the english language have to be so complicated to work with ?
	var/empty = 0
	var/descriptive_type = "" //piece of, stick of, et cetera
	var/plural_descriptive_type = "" //pieces of, sticks of
	var/box_type = "box"
	autoignition_temperature = AUTOIGNITION_PAPER

	foldable = /obj/item/stack/sheet/cardboard

	//Note : Fancy storages generally collect one specific type of objects only due to their properties
	//As such, it would make sense that one click on a stack of the corresponding objects should shove everything in here

	allow_quick_gather = 1
	use_to_pickup = 1
	allow_quick_empty = 1

/obj/item/weapon/storage/fancy/update_icon(var/itemremoved = 0)
	var/total_contents = src.contents.len - itemremoved
	src.icon_state = "[src.icon_type]box[total_contents]"
	return

/obj/item/weapon/storage/fancy/examine(mob/user)
	..()
	if(contents.len <= 0)
		to_chat(user, "<span class='info'>There are no [plural_descriptive_type][src.icon_type][plural_type] left in the [box_type].</span>")
	else if(contents.len == 1)
		to_chat(user, "<span class='info'>There is one [descriptive_type][src.icon_type] left in the [box_type].</span>")
	else
		to_chat(user, "<span class='info'>There are [src.contents.len] [plural_descriptive_type][src.icon_type][plural_type] in the [box_type].</span>")


/*
 * Donut Box
 */

/obj/item/weapon/storage/fancy/donut_box
	icon = 'icons/obj/food_container.dmi'
	icon_state = "donutbox6"
	icon_type = "donut"
	name = "donut box"
	storage_slots = 6
	can_only_hold = list("/obj/item/weapon/reagent_containers/food/snacks/donut", \
					"/obj/item/weapon/reagent_containers/food/snacks/customizable/candy/donut", \
					"/obj/item/weapon/reagent_containers/food/snacks/donutiron", \
					"/obj/item/weapon/reagent_containers/food/snacks/riceball")

	foldable = /obj/item/stack/sheet/cardboard
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type = RECYK_MISC

/obj/item/weapon/storage/fancy/donut_box/empty
	empty = 1
	icon_state = "donutbox0"

/obj/item/weapon/storage/fancy/donut_box/New()
	..()
	if(empty)
		update_icon() //Make it look actually empty
		return
	for(var/i = 1; i <= storage_slots; i++)
		new /obj/item/weapon/reagent_containers/food/snacks/donut/normal(src)
	return

/*
 * Egg Box
 */

/obj/item/weapon/storage/fancy/egg_box
	icon = 'icons/obj/food_container.dmi'
	icon_state = "eggbox"
	icon_type = "egg"
	name = "egg box"
	storage_slots = 12
	can_only_hold = list("/obj/item/weapon/reagent_containers/food/snacks/egg")
	var/egg_type = /obj/item/weapon/reagent_containers/food/snacks/egg
	var/list/dangerEggs = list(			//Make this list empty to not have a chance to spawn any mistakes
		/obj/item/weapon/reagent_containers/food/snacks/egg/cockatrice,
		/obj/item/weapon/reagent_containers/food/snacks/egg/bigroach,
		/obj/item/weapon/reagent_containers/food/snacks/egg/parrot,
		/obj/item/weapon/reagent_containers/food/snacks/egg/chaos,
	)

	foldable = /obj/item/stack/sheet/cardboard
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type = RECYK_MISC

/obj/item/weapon/storage/fancy/egg_box/empty
	empty = 1
	icon_state = "eggbox0"

/obj/item/weapon/storage/fancy/egg_box/vox
	egg_type = /obj/item/weapon/reagent_containers/food/snacks/egg/vox

/obj/item/weapon/storage/fancy/egg_box/New()
	..()
	if(empty)
		update_icon() //Make it look actually empty
		return
	for(var/i = 1; i <= storage_slots; i++)
		if(dangerEggs.len && prob(1))
			var/dEgg = pick(dangerEggs)
			new dEgg(src)
		else
			new egg_type(src)

/*
 * Candle Box
 */

/obj/item/weapon/storage/fancy/candle_box
	name = "Candle pack"
	desc = "A pack of candles."
	icon = 'icons/obj/candle.dmi'
	icon_state = "candlebox"
	item_state = "candlebox"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/candles.dmi', "right_hand" = 'icons/mob/in-hand/right/candles.dmi')
	foldable = /obj/item/stack/sheet/cardboard
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type = RECYK_MISC
	storage_slots = 14
	throwforce = 2
	flags = null
	slot_flags = SLOT_BELT
	var/obj/item/candle/waxtype = /obj/item/candle
	var/candlesprite = "candlebox_candle"

/obj/item/weapon/storage/fancy/candle_box/empty
	empty = TRUE
	icon_state = "candlebox"
	item_state = "candlebox" //i don't know what this does but it seems like this should go here

/obj/item/weapon/storage/fancy/candle_box/update_icon()
	overlays.len = 0

	for (var/i=0,i<contents.len,i++)
		var/obj/O = contents[i+1]
		var/image/I = image(icon, src, "[icon_state]_candle")
		I.color = O.color
		I.pixel_x = (i%5)*3
		overlays += I
	overlays += "[icon_state]_cover"
	update_blood_overlay()

	//dynamic in-hands
	var/inhand_candles = 0
	switch (contents.len)
		if (1 to 5)
			inhand_candles = 1
		if (6 to 10)
			inhand_candles = 2
		if (1 to 14)
			inhand_candles = 3
	if (inhand_candles)
		var/obj/O = contents[1]
		var/image/left_I = image(inhand_states["left_hand"], src, "[icon_state]_[inhand_candles]")
		left_I.color = O.color
		var/image/right_I = image(inhand_states["right_hand"], src, "[icon_state]_[inhand_candles]")
		right_I.color = O.color
		dynamic_overlay["[HAND_LAYER]-[GRASP_LEFT_HAND]"] = left_I
		dynamic_overlay["[HAND_LAYER]-[GRASP_RIGHT_HAND]"] = right_I

	if(iscarbon(loc))
		var/mob/living/carbon/M = loc
		M.update_inv_hands()


/obj/item/weapon/storage/fancy/candle_box/New()
	..()
	if(empty)
		return
	for(var/i=1; i <= storage_slots; i++)
		new waxtype(src)
	update_icon()

/obj/item/weapon/storage/fancy/candle_box/holo
	name = "Holo candle pack"
	desc = "A pack of holo candles."
	icon_state = "holocandlebox"
	item_state = "holocandlebox"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/candles.dmi', "right_hand" = 'icons/mob/in-hand/right/candles.dmi')
	waxtype = /obj/item/holocandle

/*
 * Crayon Box
 */

/obj/item/weapon/storage/fancy/crayons
	name = "box of crayons"
	desc = "A box of crayons for all your rune drawing needs."
	icon = 'icons/obj/crayons.dmi'
	icon_state = "crayonbox"
	foldable = /obj/item/stack/sheet/cardboard
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type=RECYK_MISC
	w_class = W_CLASS_SMALL
	storage_slots = 7
	icon_type = "crayon"
	can_only_hold = list(
		"/obj/item/toy/crayon"
	)

/obj/item/weapon/storage/fancy/crayons/empty
	empty = 1

/obj/item/weapon/storage/fancy/crayons/New()
	..()
	if (empty)
		return
	new /obj/item/toy/crayon/red(src)
	new /obj/item/toy/crayon/orange(src)
	new /obj/item/toy/crayon/yellow(src)
	new /obj/item/toy/crayon/green(src)
	new /obj/item/toy/crayon/blue(src)
	new /obj/item/toy/crayon/purple(src)
	new /obj/item/toy/crayon/black(src)
	update_icon()

/obj/item/weapon/storage/fancy/crayons/update_icon()
	overlays = list() //resets list
	overlays += image('icons/obj/crayons.dmi',"crayonbox")
	for(var/obj/item/toy/crayon/crayon in contents)
		overlays += image('icons/obj/crayons.dmi',crayon.colourName)

/obj/item/weapon/storage/fancy/crayons/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/toy/crayon))
		switch(W:colourName)
			if("mime")
				to_chat(usr, "This crayon is too sad to be contained in this box.")
				return
			if("rainbow")
				to_chat(usr, "This crayon is too powerful to be contained in this box.")
				return
	. = ..()

/*
 * Match Box
 */

/obj/item/weapon/storage/fancy/matchbox
	name = "matchbox"
	desc = "A box of matches. Critical element of a survival kit and equally needed by chain smokers and pyromaniacs."
	icon = 'icons/obj/cigarettes.dmi'
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/cigs_lighters.dmi', "right_hand" = 'icons/mob/in-hand/right/cigs_lighters.dmi')
	icon_state = "matchbox"
	item_state = "matchbox"
	icon_type = "match"
	plural_type = "es"
	storage_slots = 21 //3 rows of 7 items
	max_combined_w_class = 21
	w_class = W_CLASS_TINY
	flags = 0
	var/matchtype = /obj/item/weapon/match
	can_only_hold = list("/obj/item/weapon/match", "/obj/item/weapon/p_folded/note_small", "/obj/item/weapon/coin", \
		"/obj/item/weapon/reagent_containers/food/snacks/customizable/candy/coin", "/obj/item/weapon/reagent_containers/food/snacks/chococoin")
	slot_flags = SLOT_BELT

/obj/item/weapon/storage/fancy/matchbox/empty
	empty = 1
	icon_state = "matchbox_e"

/obj/item/weapon/storage/fancy/matchbox/New()
	..()
	if(empty)
		update_icon() //Make it look actually empty
		return
	for(var/i = 1; i <= storage_slots; i++)
		new matchtype(src)
	update_icon()

/obj/item/weapon/storage/fancy/matchbox/update_icon()

	var/contentpercent = (contents.len/storage_slots)*100
	if(contentpercent < 33) //Looks empty, actually not a single row full because logic
		icon_state = "[initial(icon_state)]_e"
		return
	else if(contentpercent < 65) //1 row full, 1 row almost full
		icon_state = "[initial(icon_state)]_almostempty"
		return
	else if(contentpercent < 100) //At least one of the first row removed
		icon_state = "[initial(icon_state)]_almostfull"
		return
	else if(contentpercent == 100)
		icon_state = "[initial(icon_state)]"
		return

/obj/item/weapon/storage/fancy/matchbox/attackby(obj/item/weapon/match/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/match) && !W.lit)
		W.light()
		playsound(src, 'sound/items/lighter1.ogg', 50, 1)
		return
	return ..()

/obj/item/weapon/storage/fancy/matchbox/handle_item_insertion(obj/item/W as obj, prevent_warning = 0)
	. = ..()
	if(.)
		if(W.is_hot() >= src.autoignition_temperature)
			ignite(W.is_hot())

/obj/item/weapon/storage/fancy/matchbox/ignite(temperature)
	for(var/obj/item/weapon/match/ohno in src)
		ohno.light()
	. = ..()

/obj/item/weapon/storage/fancy/matchbox/strike_anywhere
	name = "strike-anywhere matchbox"
	desc = "A box of strike-anywhere matches. Critical element of a survival kit and equally needed by chain smokers and pyromaniacs. These ones can be lit against any surface."
	icon_type = "strike-anywhere match"
	matchtype = /obj/item/weapon/match/strike_anywhere

/obj/item/weapon/storage/fancy/matchbox/strike_anywhere/empty
	empty = 1

////////////
//CIG PACK//
////////////
/obj/item/weapon/storage/fancy/cigarettes
	name = "cigarette packet"
	desc = "The most popular brand of Space Cigarettes, sponsors of the Space Olympics."
	icon = 'icons/obj/cigarettes.dmi'
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/cigs_lighters.dmi', "right_hand" = 'icons/mob/in-hand/right/cigs_lighters.dmi')
	icon_state = "cigpacket"
	item_state = "cigpacket"
	w_class = W_CLASS_TINY
	throwforce = 2
	flags = 0
	slot_flags = SLOT_BELT
	storage_slots = 6
	can_only_hold = list("=/obj/item/clothing/mask/cigarette","/obj/item/clothing/mask/cigarette/goldencarp","/obj/item/clothing/mask/cigarette/starlight","/obj/item/clothing/mask/cigarette/bidi","/obj/item/clothing/mask/cigarette/lucky","/obj/item/clothing/mask/cigarette/redsuit","/obj/item/clothing/mask/cigarette/ntstandard","/obj/item/clothing/mask/cigarette/spaceport", "/obj/item/weapon/lighter", "/obj/item/weapon/p_folded/note_small")
	icon_type = "cigarette"
	starting_materials = list(MAT_CARDBOARD = 370)
	w_type=RECYK_MISC
	var/equip_from_box = TRUE
	var/cigtype = /obj/item/clothing/mask/cigarette

/obj/item/weapon/storage/fancy/cigarettes/New()
	..()
	flags |= NOREACT
	for(var/i = 1 to storage_slots)
		new cigtype(src)
	create_reagents(15 * storage_slots)//so people can inject cigarettes without opening a packet, now with being able to inject the whole one

/obj/item/weapon/storage/fancy/cigarettes/Destroy()
	QDEL_NULL(reagents)
	..()


/obj/item/weapon/storage/fancy/cigarettes/update_icon()
	icon_state = "[initial(icon_state)][contents.len]"
	desc = "There are [contents.len] cig\s left!"
	return

/obj/item/weapon/storage/fancy/cigarettes/remove_from_storage(obj/item/W as obj, atom/new_location, var/force = 0, var/refresh = 1)
	var/obj/item/clothing/mask/cigarette/C = W
	if(!istype(C))
		return ..() // what
	reagents.trans_to(C, (reagents.total_volume/contents.len))
	. = ..()

/obj/item/weapon/storage/fancy/cigarettes/attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
	if(!istype(M, /mob))
		return
	if(!equip_from_box)
		return ..()
	if (user.zone_sel.selecting != "mouth")
		return ..()
	var/list/cigs = list()
	for(var/obj/item/clothing/mask/cigarette/cig in contents)
		cigs.Add(cig)
	if(!cigs.len)
		to_chat(user, "<span class='notice'>There are no cigarettes left in the pack.</span>")
		return
	var/obj/item/clothing/mask/cigarette/mycig = cigs[cigs.len]
	if(M.wear_mask)
		to_chat(user, "<span class='notice'>There's no space for a cigarette.</span>")
		return
	if(M == user)
		if(user.equip_to_slot_if_possible(mycig, slot_wear_mask))
			to_chat(user, "<span class='notice'>You take a cigarette out of the pack.</span>")
			update_icon()
		return
	else
		to_chat(user, "<span class='notice'>You try to pass [M] a cigarette.</span>")
		pass(M,user,mycig)
		return

/obj/item/weapon/storage/fancy/cigarettes/proc/pass(mob/living/carbon/M as mob, mob/living/carbon/user as mob, var/obj/item/clothing/mask/cigarette/mycig) //appropriated from give_item()
	if(!istype(user))
		return
	if(M.stat == 2 || user.stat == 2 || M.client == null)
		to_chat(user, "<span class='warning'>That's not gonna work.</span>")
		return
	if(M.give_check)
		to_chat(user, "<span class='warning'>\The [M] is currently being passed something by somebody else.</span>")
		return
	if(!mycig)
		return
	M.give_check = TRUE
	switch(alert(M, "[user] wants to pass you \a [mycig]?", , "Yes", "No"))
		if("Yes")
			M.give_check = FALSE
			if(!mycig)
				return
			if(!user.Adjacent(M))
				to_chat(user, "<span class='warning'>You need to stay still while passing a smoke.</span>")
				to_chat(M, "<span class='warning'>[user] moved away.</span>")//What an asshole
				return
			if(user.get_active_hand() != src)
				to_chat(user, "<span class='warning'>You need to keep \the [src] in your hand.</span>")
				to_chat(M, "<span class='warning'>[user] has put \the [src] away!</span>")
				return
			if(M.equip_to_slot_if_possible(mycig, slot_wear_mask))
				user.visible_message("<span class='notice'>[user] passed \the [mycig] to [M].</span>")
				update_icon()
		if("No")
			M.give_check = FALSE
			M.visible_message("<span class='warning'>[user] tried to pass \the [mycig] to [M] but \he didn't want it.</span>")

/obj/item/weapon/storage/fancy/cigarettes/dromedaryco
	name = "\improper DromedaryCo packet"
	desc = "A packet of six imported DromedaryCo cancer sticks. A label on the packaging reads, \"Wouldn't a slow death make a change?\""
	icon_state = "Dpacket"
	item_state = "Dpacket"

/obj/item/weapon/storage/fancy/cigarettes/goldencarp
	name = "\improper 'Golden Carp' packet"
	desc = "Fine imported cigarettes, claiming to be made with real gold dust. A favorite of triad bosses with expensive tastes."
	icon_state = "GCpacket"
	item_state = "GCpacket"
	cigtype = /obj/item/clothing/mask/cigarette/goldencarp

/obj/item/weapon/storage/fancy/cigarettes/shoalsticks
	name = "\improper 'Shoal Sticks' packet"
	desc = "A flimsy paper packet covered in unintelligible script, containing six acrid roll-ups."
	icon_state = "SSpacket"
	item_state = "SSpacket"
	cigtype = /obj/item/clothing/mask/cigarette/bidi

/obj/item/weapon/storage/fancy/cigarettes/spaceports
	name = "\improper Spaceports packet"
	desc = "A pack of suspiciously cheap smokes, perfect for the connoisseur on a tight budget."
	icon_state = "SPpacket"
	item_state = "SPpacket"
	cigtype = /obj/item/clothing/mask/cigarette/spaceport

/obj/item/weapon/storage/fancy/cigarettes/starlights
	name = "\improper Starlights packet"
	desc = "A glossy black packet of luxury cigarettes, emblazoned with the three stars of Starlight Cigarettes. The tagline reads, \"As cool as space itself.\""
	icon_state = "SLpacket"
	item_state = "SLpacket"
	cigtype = /obj/item/clothing/mask/cigarette/starlight

/obj/item/weapon/storage/fancy/cigarettes/luckystrike
	name = "\improper Lucky Strike packet"
	desc = "A white foil pack of plain, unfiltered cigs. 'L.S./M.F.T.' is emblazoned across the side of the package."
	icon_state = "LSpacket"
	item_state = "LSpacket"
	cigtype = /obj/item/clothing/mask/cigarette/lucky

/obj/item/weapon/storage/fancy/cigarettes/luckystrikedeluxe
	name = "\improper Lucky Strike Deluxe packet"
	desc = "A rich green-colored foil pack, containing the best unfiltered smokes this side of Andromeda. L.S./M.F.T."
	icon_state = "DLSpacket"
	item_state = "DLSpacket"
	cigtype = /obj/item/clothing/mask/cigarette/lucky

/obj/item/weapon/storage/fancy/cigarettes/ntstandard
	name = "\improper NT Standard packet"
	desc = "A stark, navy packet, lacking any markings besides a bold Nanotrasen Logo. You don't even have to be told to light these up."
	icon_state = "NTpacket"
	item_state = "NTpacket"
	cigtype = /obj/item/clothing/mask/cigarette/ntstandard

/obj/item/weapon/storage/fancy/cigarettes/redsuits
	name = "\improper Red Suits packet"
	desc = "Bold. Blood-red. The perfect cigarette for the ambitious individualist. It smells faintly metallic."
	icon_state = "RSpacket"
	item_state = "RSpacket"
	cigtype = /obj/item/clothing/mask/cigarette/redsuit

/*
 * Vial Box
 */

/obj/item/weapon/storage/fancy/vials
	name = "vial storage box"
	desc = "Designed to be used in an isolation centrifuge."
	icon = 'icons/obj/vialbox.dmi'
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/boxes_and_storage.dmi', "right_hand" = 'icons/mob/in-hand/right/boxes_and_storage.dmi')
	icon_state = "vialbox"
	item_state = "vialbox"
	icon_type = "vial"
	storage_slots = 6
	can_only_hold = list("/obj/item/weapon/reagent_containers/glass/beaker/vial")

	foldable = null


/obj/item/weapon/storage/fancy/vials/New()
	..()
	for(var/i=1; i <= storage_slots; i++)
		new /obj/item/weapon/reagent_containers/glass/beaker/vial(src)
	update_icon()

/obj/item/weapon/storage/fancy/vials/update_icon()
	overlays.len = 0

	var/i = 0
	for (var/obj/item/weapon/reagent_containers/glass/beaker/vial/vial in contents)
		var/image/vial_image = image('icons/obj/vialbox.dmi',src,"vial")
		if(vial.reagents.total_volume)
			var/image/filling = image('icons/obj/vialbox.dmi',src, "vial_reagents")
			filling.icon += mix_color_from_reagents(vial.reagents.reagent_list)
			filling.alpha = mix_alpha_from_reagents(vial.reagents.reagent_list)
			vial_image.overlays += filling
		if (i < 6)
			vial_image.pixel_x += (i % 3) * 4
			if (i > 2)
				vial_image.pixel_x -= 2
				vial_image.pixel_y -= 2
		else
			qdel(vial_image)
			continue
		overlays += vial_image
		i++

/obj/item/weapon/storage/fancy/vials/handle_item_insertion(obj/item/W as obj, prevent_warning = 0)
	.=..()
	if (.)
		playsound(src, 'sound/effects/pop.ogg', 100, 1, -6)

//I know vial storage is just above, but it really shouldn't be there
//Furthermore, this can lead to confusion with fancy items now having quick gather and quick empty
/obj/item/weapon/storage/lockbox/vials
	name = "secure vial storage box"
	desc = "A locked box for keeping things away from children."
	icon = 'icons/obj/vialbox.dmi'
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/boxes_and_storage.dmi', "right_hand" = 'icons/mob/in-hand/right/boxes_and_storage.dmi')
	icon_state = "vialbox"
	item_state = "vialbox_secure"
	can_only_hold = list("/obj/item/weapon/reagent_containers/glass/beaker/vial")
	fits_max_w_class = 3
	w_class = W_CLASS_MEDIUM
	max_combined_w_class = 14 //The sum of the w_classes of all the items in this storage item.
	storage_slots = 6
	req_one_access = list(access_virology) //Obj was inheriting from obj/storage/lockbox which requires armory access.  This behavior is overridden here.

/obj/item/weapon/storage/lockbox/vials/New()
	..()
	update_icon()

/obj/item/weapon/storage/lockbox/vials/update_icon()
	overlays.len = 0
	icon_state = "vialbox"
	item_state = "vialbox"
	if (!broken && !locked)
		overlays += image('icons/obj/vialbox.dmi',src,"cover_open")

	var/i = 0
	for (var/obj/item/weapon/reagent_containers/glass/beaker/vial/vial in contents)
		var/image/vial_image = image('icons/obj/vialbox.dmi',src,"vial")
		if(vial.reagents.total_volume)
			var/image/filling = image('icons/obj/vialbox.dmi',src, "vial_reagents")
			filling.icon += mix_color_from_reagents(vial.reagents.reagent_list)
			filling.alpha = mix_alpha_from_reagents(vial.reagents.reagent_list)
			vial_image.overlays += filling
		if (i < 6)
			vial_image.pixel_x += (i % 3) * 4
			if (i > 2)
				vial_image.pixel_x -= 2
				vial_image.pixel_y -= 2
		else
			qdel(vial_image)
			continue
		overlays += vial_image
		i++

	if (!broken)
		overlays += image(icon, src, "led[locked]")
		if(locked)
			overlays += image(icon, src, "cover")
	else
		overlays += image(icon, src, "ledb")

/obj/item/weapon/storage/lockbox/vials/attackby(obj/item/weapon/W as obj, mob/user as mob)
	. = ..()
	if (istype(W,/obj/item/weapon/card))
		playsound(src, get_sfx("card_swipe"), 60, 1, -5)
	update_icon()

/obj/item/weapon/storage/lockbox/vials/handle_item_insertion(obj/item/W as obj, prevent_warning = 0)
	.=..()
	if (.)
		playsound(src, 'sound/effects/pop.ogg', 100, 1, -6)

/obj/item/weapon/storage/lockbox/vials/toggle(var/mob/user, var/id_name)
    ..()
    update_icon()

//FLARE BOX
//Useful for lots of things, this box has 6 flares in it. Only takes unused and unlight flares.
//Great for emergency crates/closets etc.

/obj/item/weapon/storage/fancy/flares
	icon = 'icons/obj/lighting.dmi'
	icon_state = "flarebox6"
	icon_type = "flare"
	name = "box of flares"
	storage_slots = 6
	can_only_hold = list("/obj/item/device/flashlight/flare")

	foldable = /obj/item/stack/sheet/cardboard
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type=RECYK_MISC

/obj/item/weapon/storage/fancy/flares/empty
	empty = 1
	icon_state = "flarebox0"

/obj/item/weapon/storage/fancy/flares/New()
	..()
	if(empty)
		update_icon() //Make it look actually empty
		return
	for(var/i=1; i <= storage_slots; i++)
		new /obj/item/device/flashlight/flare(src)
	return

/obj/item/weapon/storage/fancy/flares/attackby(var/obj/item/device/flashlight/flare/F, var/user as mob) //if it's on or empty, we don't want it
	if(!istype(F))
		return
	if(F.on)
		to_chat(user, "You can't put a lit flare in the box!")
		return
	if(!F.fuel)
		to_chat(user, "This flare is empty!")
		return
	. = ..()

/obj/item/weapon/storage/fancy/flares/update_icon()
	..()

/obj/item/weapon/storage/fancy/food_box/chicken_bucket
	name = "chicken bucket"
	desc = "Now we're doing it!"
	icon_state = "kfc_drumsticks"
	item_state = "kfc_bucket"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/food.dmi', "right_hand" = 'icons/mob/in-hand/right/food.dmi')
	icon_type = "drumstick"
	can_only_hold = list("/obj/item/weapon/reagent_containers/food/snacks/chicken_drumstick")
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type=RECYK_MISC

/obj/item/weapon/storage/fancy/food_box/chicken_bucket/New()
	..()
	for(var/i=1; i <= storage_slots; i++)
		new /obj/item/weapon/reagent_containers/food/snacks/chicken_drumstick(src)

/obj/item/weapon/storage/fancy/food_box/chicken_bucket/remove_from_storage(obj/item/W as obj, atom/new_location, var/force = 0, var/refresh = 1)
	. = ..()
	if(!contents.len)
		new/obj/item/trash/chicken_bucket(get_turf(src.loc))
		qdel(src)

/obj/item/weapon/storage/fancy/food_box/chicken_bucket/update_icon(var/itemremoved = 0)
	return


/obj/item/weapon/storage/fancy/food_box/vox_chicken_bucket
	name = "vox chicken bucket"
	desc = "I’ll have two number 9s, a number 9 large, a number 6 with extra dip, a number 7, two number 45s, one with cheese, and a large soda."
	icon_state = "vox_drumstick_bucket"
	item_state = "kfc_bucket"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/food.dmi', "right_hand" = 'icons/mob/in-hand/right/food.dmi')
	icon_type = "drumstick"
	can_only_hold = list("/obj/item/weapon/reagent_containers/food/snacks/vox_chicken_drumstick")
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type=RECYK_MISC

/obj/item/weapon/storage/fancy/food_box/vox_chicken_bucket/New()
	..()
	for(var/i=1; i <= storage_slots; i++)
		new /obj/item/weapon/reagent_containers/food/snacks/vox_chicken_drumstick(src)

/obj/item/weapon/storage/fancy/food_box/vox_chicken_bucket/remove_from_storage(obj/item/W as obj, atom/new_location, var/force = 0, var/refresh = 1)
	. = ..()
	if(!contents.len)
		new/obj/item/trash/chicken_bucket(get_turf(src.loc))
		qdel(src)

/obj/item/weapon/storage/fancy/food_box/vox_chicken_bucket/update_icon(var/itemremoved = 0)
	return


/obj/item/weapon/storage/fancy/food_box
	name = "food box"
	desc = "Holds food."
	icon = 'icons/obj/food.dmi'
	icon_state = "slider_box"
	storage_slots = 6
	can_only_hold = list("/obj/item/weapon/reagent_containers/food/snacks")

/obj/item/weapon/storage/fancy/food_box/update_icon(var/itemremoved = 0) //this is so that your box doesn't turn into a donut box, see line 29
	return

//SLIDER BOXES

/obj/item/weapon/storage/fancy/food_box/slider_box
	name = "slider box"
	desc = "I wonder what's inside."
	icon_type = "slider"
	storage_slots = 4
	can_only_hold = list("/obj/item/weapon/reagent_containers/food/snacks/slider")
	var/slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider//set this as the spawn path of your slider
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type=RECYK_MISC

/obj/item/weapon/storage/fancy/food_box/slider_box/New()
	..()
	for(var/i=1, i <= storage_slots; i++)
		new slider_type(src)

/obj/item/weapon/storage/fancy/food_box/slider_box/synth
	name = "synth slider box"
	icon_type = "synth slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/synth

/obj/item/weapon/storage/fancy/food_box/slider_box/xeno
	name = "xeno slider box"
	icon_type = "xeno slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/xeno

/obj/item/weapon/storage/fancy/food_box/slider_box/chicken
	name = "chicken slider box"
	icon_type = "chicken slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/chicken

/obj/item/weapon/storage/fancy/food_box/slider_box/toxiccarp
	name = "carp slider box"
	icon_type = "carp slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/toxiccarp
	storage_slots = 2

/obj/item/weapon/storage/fancy/food_box/slider_box/carp
	name = "carp slider box"
	icon_type = "carp slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/carp
	storage_slots = 2

/obj/item/weapon/storage/fancy/food_box/slider_box/spider
	name = "spidey slidey box"
	icon_type = "spider slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/spider

/obj/item/weapon/storage/fancy/food_box/slider_box/clown
	name = "honky slider box"
	icon_type = "honky slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/clown

/obj/item/weapon/storage/fancy/food_box/slider_box/mime
	name = "quiet slider box"
	icon_type = "quiet slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/mime

/obj/item/weapon/storage/fancy/food_box/slider_box/slippery
	name = "slippery slider box"
	icon_type = "slippery slider"
	slider_type = /obj/item/weapon/reagent_containers/food/snacks/slider/slippery
	storage_slots = 2

//SLIDER BOXES END

////////////
//GUM PACK//
////////////
/obj/item/weapon/storage/fancy/cigarettes/gum
	name = "pack of chewing gum"
	desc = "Guaranteed extra chewy."
	icon = 'icons/obj/items.dmi'
	icon_state = "gum_pack"
	item_state = null
	storage_slots = 10
	can_only_hold = list("/obj/item/gum") // Strict type check.
	icon_type = "gum"
	plural_type = ""
	descriptive_type = "stick of "
	plural_descriptive_type = "sticks of "
	box_type = "pack"
	equip_from_box = FALSE
	cigtype = /obj/item/gum

/obj/item/weapon/storage/fancy/cigarettes/gum/update_icon()
	return

/obj/item/weapon/storage/fancy/cigarettes/gum/remove_from_storage(obj/item/gum/G, atom/new_location, var/force = 0, var/refresh = 1)
	if(istype(G))
		if(reagents.total_volume)
			G.transfer_some_reagents(src, reagents.total_volume/contents.len)
	. = ..()

////////////////////
//COLLECTION PLATE//
////////////////////
/obj/item/weapon/storage/fancy/collection_plate
	icon = 'icons/obj/tithe.dmi'
	icon_state = "donationbox0"
	icon_type = "donation"
	name = "collection plate"
	foldable = 0
	box_type = "plate"
	storage_slots = 10
	can_only_hold = list("/obj/item/weapon/spacecash", "/obj/item/weapon/coin")

	starting_materials = list(MAT_GOLD = 2*CC_PER_SHEET_GOLD) // Recipe requires 2 sheets
	w_type = RECYK_METAL

/*
 * Beer Box
 */

/obj/item/weapon/storage/fancy/beer_box
	icon = 'icons/obj/food_container.dmi'
	icon_state = "beerbox6"
	icon_type = "beer"
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/boxes_and_storage.dmi', "right_hand" = 'icons/mob/in-hand/right/boxes_and_storage.dmi')
	item_state = "beerbox"
	name = "beer box"
	storage_slots = 6
	can_only_hold = list("/obj/item/weapon/reagent_containers/food/drinks/beer")

	foldable = /obj/item/stack/sheet/cardboard
	starting_materials = list(MAT_CARDBOARD = 3750)
	w_type = RECYK_MISC

/obj/item/weapon/storage/fancy/beer_box/empty
	empty = 1
	icon_state = "beerbox0"

/obj/item/weapon/storage/fancy/beer_box/New()
	..()
	if(empty)
		update_icon()
		return
	for(var/i in 1 to storage_slots)
		new /obj/item/weapon/reagent_containers/food/drinks/beer(src)
