/obj/effect/proc_holder/spell/invoked/projectile/lightningbolt/sacred_flame_rogue
	name = "Sacred Flame"
	overlay_state = "sacredflame"
	sound = 'sound/magic/bless.ogg'
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	invocation = null
	invocation_type = "shout"
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = TRUE
	recharge_time = 15 SECONDS
	miracle = TRUE
	devotion_cost = 100
	projectile_type = /obj/projectile/magic/astratablast


/obj/projectile/magic/astratablast
	damage = 10
	name = "ray of holy fire"
	nodamage = FALSE
	damage_type = BURN
	speed = 0.3
	muzzle_type = null
	impact_type = null
	hitscan = TRUE
	flag = "magic"
	light_color = "#a98107"
	light_outer_range = 7
	tracer_type = /obj/effect/projectile/tracer/solar_beam
	var/fuck_that_guy_multiplier = 2.5
	var/biotype_we_look_for = MOB_UNDEAD

/obj/projectile/magic/astratablast/on_hit(target)
	. = ..()
	if(ismob(target))
		var/mob/living/M = target
		if(M.anti_magic_check())
			visible_message(span_warning("[src] fizzles on contact with [target]!"))
			playsound(get_turf(target), 'sound/magic/magic_nulled.ogg', 100)
			qdel(src)
			return BULLET_ACT_BLOCK
		if(M.mob_biotypes & biotype_we_look_for || istype(M, /mob/living/simple_animal/hostile/rogue/skeleton))
			damage *= fuck_that_guy_multiplier
			M.adjust_fire_stacks(10) //4 pats to put it out
			visible_message(span_warning("[target] erupts in flame upon being struck by [src]!"))
			M.IgniteMob()
		else
			M.adjust_fire_stacks(4) //2 pats to put it out
			visible_message(span_warning("[src] ignites [target]!"))
			M.IgniteMob()
	return FALSE

/obj/effect/proc_holder/spell/invoked/ignition
	name = "Ignite"
	overlay_state = "sacredflame"
	releasedrain = 30
	chargedrain = 0
	chargetime = 0
	range = 15
	warnie = "sydwarning"
	movement_interrupt = FALSE
	chargedloop = null
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	sound = 'sound/magic/heal.ogg'
	invocation = "Cleansing flames, kindle!"
	invocation_type = "shout"
	recharge_time = 5 SECONDS
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = TRUE
	miracle = TRUE
	devotion_cost = 50

/obj/effect/proc_holder/spell/invoked/ignition/cast(list/targets, mob/user = usr)
	. = ..()
	if(isliving(targets[1]))
		var/mob/living/L = targets[1]
		user.visible_message("<font color='yellow'>[user] points at [L]!</font>")
		if(L.anti_magic_check(TRUE, TRUE))
			return FALSE
		L.adjust_fire_stacks(5)
		L.IgniteMob()
		addtimer(CALLBACK(L, TYPE_PROC_REF(/mob/living, ExtinguishMob)), 5 SECONDS)
		return TRUE

	// Spell interaction with ignitable objects (burn wooden things, light torches up)
	else if(isobj(targets[1]))
		var/obj/O = targets[1]
		if(O.fire_act())
			user.visible_message("<font color='yellow'>[user] points at [O], igniting it with sacred flames!</font>")
			return TRUE
		else
			to_chat(user, span_warning("You point at [O], but it fails to catch fire."))
			return FALSE
	revert_cast()
	return FALSE

/obj/effect/proc_holder/spell/invoked/revive
	name = "Anastasis"
	overlay_state = "revive"
	releasedrain = 90
	chargedrain = 0
	chargetime = 50
	range = 1
	warnie = "sydwarning"
	no_early_release = TRUE
	movement_interrupt = TRUE
	chargedloop = /datum/looping_sound/invokeholy
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	sound = 'sound/magic/revive.ogg'
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = TRUE
	recharge_time = 2 MINUTES
	miracle = TRUE
	devotion_cost = 80
	/// Amount of PQ gained for reviving people
	var/revive_pq = PQ_GAIN_REVIVE

/obj/effect/proc_holder/spell/invoked/revive/cast(list/targets, mob/living/user)
	. = ..()
	if(isliving(targets[1]))
		testing("revived1")
		var/mob/living/target = targets[1]
		// Block if excommunicated and caster is divine pantheon
		if(istype(user, /mob/living)) {
			var/mob/living/LU = user
			var/excomm_found = FALSE
			for(var/excomm_name in GLOB.excommunicated_players)
				var/clean_excomm = lowertext(trim(excomm_name))
				var/clean_target = lowertext(trim(target.real_name))
				if(clean_excomm == clean_target)
					excomm_found = TRUE
					break
			if(ispath(LU.patron?.type, /datum/patron/divine) && excomm_found) {
				to_chat(user, span_danger("The gods recoil from [target]! Divine fire scorches your hands as your plea is rejected!"))
				target.visible_message(span_danger("[target] is seared by divine wrath! The gods hate them!"), span_userdanger("I am seared by divine wrath! The gods hate me!"))
				revert_cast()
				return FALSE
			}
		}
		if(!target.mind)
			revert_cast()
			return FALSE
		if(HAS_TRAIT(target, TRAIT_NECRAS_VOW))
			to_chat(user, "This one has pledged themselves whole to Necra. They are Hers.")
			revert_cast()
			return FALSE
		if(!target.mind.active)
			to_chat(user, "Astrata is not done with [target], yet.")
			revert_cast()
			return FALSE
		if(target == user)
			revert_cast()
			return FALSE
		if(target.stat < DEAD)
			to_chat(user, span_warning("Nothing happens."))
			revert_cast()
			return FALSE
		if(GLOB.tod == "night")
			to_chat(user, span_warning("Let there be light."))
		for(var/obj/structure/fluff/psycross/S in oview(5, user))
			S.AOE_flash(user, range = 8)
		if(target.mob_biotypes & MOB_UNDEAD) //positive energy harms the undead
			target.visible_message(span_danger("[target] is unmade by holy light!"), span_userdanger("I'm unmade by holy light!"))
			target.gib()
			return TRUE
		if(alert(target, "They are calling for you. Are you ready?", "Revival", "I need to wake up", "Don't let me go") != "I need to wake up")
			target.visible_message(span_notice("Nothing happens. They are not being let go."))
			return FALSE
		target.adjustOxyLoss(-target.getOxyLoss()) //Ye Olde CPR
		if(!target.revive(full_heal = FALSE))
			to_chat(user, span_warning("Nothing happens."))
			revert_cast()
			return FALSE
		testing("revived2")
		var/mob/living/carbon/spirit/underworld_spirit = target.get_spirit()
		//GET OVER HERE!
		if(underworld_spirit)
			var/mob/dead/observer/ghost = underworld_spirit.ghostize()
			qdel(underworld_spirit)
			ghost.mind.transfer_to(target, TRUE)
		target.grab_ghost(force = TRUE) // even suicides
		target.emote("breathgasp")
		target.Jitter(100)
		GLOB.scarlet_round_stats[STATS_ASTRATA_REVIVALS]++
		target.update_body()
		target.visible_message(span_notice("[target] is revived by holy light!"), span_green("I awake from the void."))
		if(revive_pq && !HAS_TRAIT(target, TRAIT_IWASREVIVED) && user?.ckey)
			adjust_playerquality(revive_pq, user.ckey)
			ADD_TRAIT(target, TRAIT_IWASREVIVED, "[type]")
		target.mind.remove_antag_datum(/datum/antagonist/zombie)
		target.remove_status_effect(/datum/status_effect/debuff/rotted_zombie)	//Removes the rotted-zombie debuff if they have it - Failsafe for it.
		target.apply_status_effect(/datum/status_effect/debuff/revived)	//Temp debuff on revive, your stats get hit temporarily. Doubly so if having rotted.
		return TRUE
	revert_cast()
	return FALSE

/obj/effect/proc_holder/spell/invoked/revive/cast_check(skipcharge = 0,mob/user = usr)
	if(!..())
		return FALSE
	var/found = null
	for(var/obj/structure/fluff/psycross/S in oview(5, user))
		found = S
	if(!found)
		to_chat(user, span_warning("I need a holy cross."))
		return FALSE
	return TRUE

//T0. Removes cone vision for a dynamic duration.
/obj/effect/proc_holder/spell/self/astrata_gaze
	name = "Astratan Gaze"
	overlay_state = "astrata_gaze"
	releasedrain = 10
	chargedrain = 0
	chargetime = 0
	chargedloop = /datum/looping_sound/invokeholy
	sound = 'sound/magic/astrata_choir.ogg'
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = FALSE
	invocation = "Astrata show me true."
	invocation_type = "shout"
	recharge_time = 120 SECONDS
	devotion_cost = 30
	miracle = TRUE

/obj/effect/proc_holder/spell/self/astrata_gaze/cast(list/targets, mob/user)
	if(!ishuman(user))
		revert_cast()
		return FALSE
	var/mob/living/carbon/human/H = user
	H.apply_status_effect(/datum/status_effect/buff/astrata_gaze, user.get_skill_level(associated_skill))
	return TRUE

/atom/movable/screen/alert/status_effect/buff/astrata_gaze
	name = "Astratan's Gaze"
	desc = "She shines through me, illuminating all injustice."
	icon_state = "astrata_gaze"

/datum/status_effect/buff/astrata_gaze
	id = "astratagaze"
	alert_type = /atom/movable/screen/alert/status_effect/buff/astrata_gaze
	duration = 20 SECONDS

/datum/status_effect/buff/astrata_gaze/on_apply(assocskill)
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.viewcone_override = TRUE
		H.hide_cone()
		H.update_cone_show()
	var/per_bonus = 0
	if(assocskill)
		if(assocskill > SKILL_LEVEL_NOVICE)
			per_bonus++
		duration *= assocskill
	if(GLOB.tod == "day" || GLOB.tod == "dawn")
		per_bonus++
		duration *= 2
	if(per_bonus > 0)
		effectedstats = list("perception" = per_bonus)
	to_chat(owner, span_info("She shines through me! I can perceive all clear as dae!"))
	. = ..()

/datum/status_effect/buff/astrata_gaze/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.viewcone_override = FALSE
		H.hide_cone()
		H.update_cone_show()

//T4 Miracle - Divine Flame Armor
/obj/effect/proc_holder/spell/invoked/divine_flame_armor
	name = "Flame Armor"
	desc = "Astrata's sacred flames wrap around the target as protective armor."
	overlay_state = "divinearmor"
	releasedrain = 120
	chargedrain = 0
	chargetime = 10 SECONDS
	chargedloop = null
	req_items = list(/obj/item/clothing/neck/roguetown/psicross)
	sound = 'sound/magic/bless.ogg'
	invocation = "Astrata's light, protect us!"
	invocation_type = "shout"
	recharge_time = 5 MINUTES
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = TRUE
	miracle = TRUE
	devotion_cost = 150
	range = 7

/obj/effect/proc_holder/spell/invoked/divine_flame_armor/cast(list/targets, mob/user)
	var/atom/A = targets[1]
	if(!ishuman(A))
		revert_cast()
		return FALSE
	
	var/mob/living/carbon/human/H = A
	
	// Check if it's day time
	if(GLOB.tod != "day" && GLOB.tod != "dawn")
		to_chat(user, span_warning("Astrata's blessing only works during the day!"))
		revert_cast()
		return FALSE
	
	// Apply the divine flame armor effect
	H.apply_status_effect(/datum/status_effect/buff/divine_flame_armor)
	
	if(H != user)
		user.visible_message(span_warning("[user] surrounds [H] with divine flames that form protective armor!"), 
							span_green("I surround [H] with Astrata's sacred flames as protective armor!"))
		to_chat(H, span_green("[user] surrounds me with Astrata's sacred flames as protective armor!"))
	else
		user.visible_message(span_warning("[user] is surrounded by divine flames that form protective armor!"), 
							span_green("Astrata's sacred flames wrap around me as protective armor!"))
	
	playsound(get_turf(H), 'sound/magic/bless.ogg', 100, FALSE)
	
	return TRUE

/atom/movable/screen/alert/status_effect/buff/divine_flame_armor
	name = "Divine Flame Armor"
	desc = "Sacred flames protect me from harm, reducing damage taken and converting it to firestack reduction. I am immune to fire damage."
	icon_state = "divinearmor"

/datum/status_effect/buff/divine_flame_armor
	id = "divine_flame_armor"
	alert_type = /atom/movable/screen/alert/status_effect/buff/divine_flame_armor
	duration = 30 SECONDS
	var/original_fire_stacks = 0
	var/armor_applied = FALSE
	var/check_timer

/datum/status_effect/buff/divine_flame_armor/on_apply()
	. = ..()
	if(!ishuman(owner))
		return FALSE
	
	var/mob/living/carbon/human/H = owner
	
	// Store original divine fire stacks
	original_fire_stacks = H.divine_fire_stacks
	
	// Apply 100 divine firestacks as armor
	H.adjust_divine_fire_stacks(100)
	
	// We'll handle all damage through our signal interception instead of using temporary armor
	armor_applied = FALSE
	
	// Add fire immunity traits
	ADD_TRAIT(H, TRAIT_NOFIRE, "divine_flame_armor")
	ADD_TRAIT(H, TRAIT_RESISTHEAT, "divine_flame_armor")
	
	// Add visual fire effect - make them actually appear to be on fire
	H.add_filter("divine_flame_armor", 2, list("type" = "outline", "color" = "#ffa500", "alpha" = 150, "size" = 3))
	
	// Make them appear to be on fire
	H.on_fire = TRUE
	H.update_fire()
	
	// Register damage interception
	RegisterSignal(H, COMSIG_MOB_APPLY_DAMGE, PROC_REF(intercept_damage))
	
	// Override damage application methods to ensure complete protection
	H.physiology.brute_mod = 0
	H.physiology.burn_mod = 0
	
	// Start checking for armor depletion
	check_timer = addtimer(CALLBACK(src, PROC_REF(check_armor_depletion)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)
	
	to_chat(owner, span_green("Divine flames wrap around me, providing immense protection and fire immunity!"))
	
	return TRUE

/datum/status_effect/buff/divine_flame_armor/proc/intercept_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER

	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/H = owner

	// Consume divine fire stacks for any damage that gets through
	var/divine_firestack_reduction = damage

	// Use INVOKE_ASYNC to defer consumption operations
	INVOKE_ASYNC(src, PROC_REF(apply_damage_block), H, divine_firestack_reduction)



/datum/status_effect/buff/divine_flame_armor/proc/apply_damage_block(mob/living/carbon/human/H, divine_firestack_reduction)
	// Reduce divine firestacks more efficiently - only consume 10% of the damage as fire stacks
	var/actual_consumption = max(1, round(divine_firestack_reduction * 0.1)) // Only consume 10% of damage, minimum 1
	H.adjust_divine_fire_stacks(-actual_consumption)
	H.visible_message(span_notice("The divine flames absorb the damage!"), span_notice("The divine flames absorb the damage!"))

/datum/status_effect/buff/divine_flame_armor/proc/check_armor_depletion()
	if(!ishuman(owner))
		return
	
	var/mob/living/carbon/human/H = owner
	
	// Check if divine fire stacks are depleted
	if(H.divine_fire_stacks <= 0)
		H.visible_message(span_warning("The divine flames have been completely consumed!"), span_userdanger("The divine flames have been completely consumed!"))
		qdel(src)
		return

/datum/status_effect/buff/divine_flame_armor/on_remove()
	. = ..()
	if(!ishuman(owner))
		return
	
	var/mob/living/carbon/human/H = owner
	
	// Stop the check timer
	if(check_timer)
		deltimer(check_timer)
	
	// No temporary armor to remove - we handled everything through signal interception
	
	// Remove fire immunity traits
	REMOVE_TRAIT(H, TRAIT_NOFIRE, "divine_flame_armor")
	REMOVE_TRAIT(H, TRAIT_RESISTHEAT, "divine_flame_armor")
	
	// Restore original physiology modifiers
	H.physiology.brute_mod = 1
	H.physiology.burn_mod = 1
	
	// Restore original divine fire stacks
	H.divine_fire_stacks = original_fire_stacks
	
	// Remove visual effect
	H.remove_filter("divine_flame_armor")
	
	// Unregister damage interception
	UnregisterSignal(H, COMSIG_MOB_APPLY_DAMGE)
	
	// Extinguish the divine fire effect
	H.on_fire = FALSE
	H.update_fire()
	
	to_chat(owner, span_warning("The divine flames extinguish, leaving me vulnerable once more."))
	
	// Play astratascream  when armor evaporates
	H.playsound_local(get_turf(H), 'sound/misc/astratascream.ogg', 100, FALSE, pressure_affected = FALSE)
	
	// Extinguish any remaining fire
	H.ExtinguishMob()


