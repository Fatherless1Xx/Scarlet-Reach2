/mob/living/carbon/human
	var/mob/stored_mob = null

/datum/antagonist/werewolf/on_life(mob/user)
	if(!user) return
	var/mob/living/carbon/human/H = user
	if(H.stat == DEAD) return
	if(H.advsetup) return
	if(HAS_TRAIT(H, TRAIT_SILVER_BLESSED)) return

	// Periodic healing and messaging for transformed werewolves
	if(transformed)
		// Check if it's time for periodic healing (every 3 minutes)
		if(!mob_timers["werewolf_healing"])
			mob_timers["werewolf_healing"] = world.time
		
		if(world.time >= mob_timers["werewolf_healing"] + 3 MINUTES)
			// Enhanced healing effect
			H.adjustBruteLoss(-25)
			H.adjustFireLoss(-25)
			
			// Heal bleeding wounds
			for(var/obj/item/bodypart/BP in H.bodyparts)
				if(BP.wounds)
					for(var/datum/wound/W in BP.wounds)
						if(istype(W, /datum/wound/slash) || istype(W, /datum/wound/puncture))
							W.heal_wound(50)
			
			// Repair natural armor
			var/obj/item/clothing/suit/roguetown/armor/skin_armor/werewolf_skin/skin = null
			for(var/obj/item/item in H.contents)
				if(istype(item, /obj/item/clothing/suit/roguetown/armor/skin_armor/werewolf_skin))
					skin = item
					break
			
			if(skin && skin.obj_integrity < skin.max_integrity)
				skin.obj_integrity = min(skin.obj_integrity + 50, skin.max_integrity)
				if(skin.obj_broken && skin.obj_integrity >= skin.max_integrity)
					skin.obj_fix()
			
			// Varied messages for the werewolf
			var/list/werewolf_messages = list(
				"I'M FULL OF HATRED AND WANT TO KILL!",
				"THE BEAST WITHIN DEMANDS BLOOD!",
				"I CAN SMELL THEIR FEAR... IT MAKES ME STRONGER!",
				"THE MOON'S POWER COURSES THROUGH MY VEINS!",
				"MY WOUNDS HEAL WITH THE FURY OF THE WOLF!",
				"I FEEL THE PRIMAL RAGE BUILDING INSIDE!",
				"THE HUNT CALLS TO ME... I MUST KILL!",
				"MY CLAWS ITCH FOR THE TASTE OF FLESH!",
				"THE WOLF SPIRIT MAKES ME INVINCIBLE!",
				"I AM THE NIGHT... I AM DEATH!"
			)
			to_chat(H, span_userdanger(pick(werewolf_messages)))
			
			// Varied messages for others nearby
			var/list/observer_messages = list(
				"You notice [H]'s fur knitting itself back together.",
				"[H]'s wounds seem to be closing up rapidly.",
				"The gashes on [H]'s body are healing before your eyes.",
				"[H]'s fur appears to be regenerating at an unnatural rate.",
				"You watch as [H]'s injuries fade away like magic.",
				"[H]'s body seems to be repairing itself with supernatural speed.",
				"The blood on [H]'s fur is disappearing as wounds close.",
				"[H]'s injuries are vanishing as if they were never there.",
				"You see [H]'s torn flesh mending itself back together.",
				"[H]'s body is healing with impossible speed.",
				"[H]'s natural armor appears to be mending itself.",
				"You see [H]'s toughened hide repairing damage.",
				"[H]'s thick fur seems to be regenerating its protective layers.",
				"[H]'s hide appears to be knitting back together stronger than before."
			)
			for(var/mob/living/L in view(7, H))
				if(L != H && L.client)
					to_chat(L, span_notice(pick(observer_messages)))
			
			// Reset timer
			mob_timers["werewolf_healing"] = world.time

	// Werewolf transforms at night AND under the sky
	if(!transformed && !transforming)
		if(GLOB.tod == "night")
			if(isturf(H.loc))
				var/turf/loc = H.loc
				if(loc.can_see_sky())
					to_chat(H, span_userdanger("The moonlight scorns me... It is too late."))
					owner.current.playsound_local(get_turf(owner.current), 'sound/music/wolfintro.ogg', 80, FALSE, pressure_affected = FALSE)
					H.flash_fullscreen("redflash3")
					transforming = world.time // timer

	// Begin transformation
	else if(transforming)
		if (world.time >= transforming + 35 SECONDS) // Stage 3
			H.werewolf_transform()
			transforming = FALSE
			transformed = TRUE // Mark as transformed

		else if (world.time >= transforming + 25 SECONDS) // Stage 2
			H.flash_fullscreen("redflash3")
			H.emote("agony", forced = TRUE)
			to_chat(H, span_userdanger("UNIMAGINABLE PAIN!"))
			H.Stun(30)
			H.Knockdown(30)

		else if (world.time >= transforming + 10 SECONDS) // Stage 1
			H.emote("")
			to_chat(H, span_warning("I can feel my muscles aching, it feels HORRIBLE..."))


	// Werewolf reverts to human form during the day
	else if(transformed)
		H.real_name = wolfname
		H.name = wolfname

		if(GLOB.tod != "night")
			if(!untransforming)
				untransforming = world.time // Start untransformation phase

			if (world.time >= untransforming + 30 SECONDS) // Untransform
				H.emote("rage", forced = TRUE)
				H.werewolf_untransform()
				transformed = FALSE
				untransforming = FALSE // Reset untransforming phase

			else if (world.time >= untransforming) // Alert player
				H.flash_fullscreen("redflash1")
				to_chat(H, span_warning("Daylight shines around me... the curse begins to fade."))


/mob/living/carbon/human/species/werewolf/death(gibbed, nocutscene = FALSE)
	werewolf_untransform(TRUE, gibbed)

/mob/living/carbon/human/proc/werewolf_transform()
	if(!mind)
		log_runtime("NO MIND ON [src.name] WHEN TRANSFORMING")
	Paralyze(1, ignore_canstun = TRUE)
	for(var/obj/item/W in src)
		dropItemToGround(W)
	regenerate_icons()
	icon = null
	var/oldinv = invisibility
	invisibility = INVISIBILITY_MAXIMUM
	cmode = FALSE
	if(client)
		SSdroning.play_area_sound(get_area(src), client)
//	stop_cmusic()

	src.fully_heal(FALSE)

	var/ww_path
	if(gender == MALE)
		ww_path = /mob/living/carbon/human/species/werewolf/male
	else
		ww_path = /mob/living/carbon/human/species/werewolf/female



	var/mob/living/carbon/human/species/werewolf/W = new ww_path(loc)


	W.set_patron(src.patron)
	W.gender = gender
	W.regenerate_icons()
	W.stored_mob = src
	W.limb_destroyer = TRUE
	W.ambushable = FALSE
	W.cmode_music = 'sound/music/combat_druid.ogg'
	W.skin_armor = new /obj/item/clothing/suit/roguetown/armor/skin_armor/werewolf_skin(W)
	playsound(W.loc, pick('sound/combat/gib (1).ogg','sound/combat/gib (2).ogg'), 200, FALSE, 3)
	W.spawn_gibs(FALSE)
	src.forceMove(W)

	W.after_creation()
	W.stored_language = new
	W.stored_language.copy_known_languages_from(src)
	W.stored_skills = ensure_skills().known_skills.Copy()
	W.stored_experience = ensure_skills().skill_experience.Copy()
	mind.transfer_to(W)
	skills?.known_skills = list()
	skills?.skill_experience = list()
	W.grant_language(/datum/language/beast)

	W.base_intents = list(INTENT_HELP, INTENT_DISARM, INTENT_GRAB)
	W.update_a_intents()

	to_chat(W, span_userdanger("I transform into a horrible beast!"))
	W.emote("rage")


	W.adjust_skillrank(/datum/skill/combat/wrestling, 5, TRUE)
	W.adjust_skillrank(/datum/skill/combat/unarmed, 5, TRUE)
	W.adjust_skillrank(/datum/skill/misc/climbing, 6, TRUE)
	W.adjust_skillrank(/datum/skill/misc/swimming, 5, TRUE)
	
	W.STASTR = src.STASTR +5
	W.STACON = src.STACON +5
	W.STAEND = src.STAEND +5
	W.STAINT = src.STAINT -3
	W.STAPER = src.STAPER
	W.STASPD = src.STASPD
	W.STALUC = src.STALUC


	W.AddSpell(new /obj/effect/proc_holder/spell/self/howl/call_of_the_moon)
	W.AddSpell(new /obj/effect/proc_holder/spell/self/claws)

	ADD_TRAIT(src, TRAIT_NOSLEEP, TRAIT_GENERIC)

	ADD_TRAIT(W, TRAIT_STRONGBITE, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_ZJUMP, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_NOFALLDAMAGE1, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_INFINITE_STAMINA, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_BASHDOORS, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_SHOCKIMMUNE, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_STEELHEARTED, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_BREADY, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_TOXIMMUNE, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_ORGAN_EATER, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_NASTY_EATER, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_NOSTINK, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_CRITICAL_RESISTANCE, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_IGNOREDAMAGESLOWDOWN, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_IGNORESLOWDOWN, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_HARDDISMEMBER, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_PIERCEIMMUNE, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_SPELLCOCKBLOCK, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_LONGSTRIDER, TRAIT_GENERIC)
	ADD_TRAIT(W, TRAIT_STRENGTH_UNCAPPED, TRAIT_GENERIC)

	invisibility = oldinv


/mob/living/carbon/human/proc/werewolf_untransform(dead,gibbed)
	if(!stored_mob)
		return
	if(!mind)
		log_runtime("NO MIND ON [src.name] WHEN UNTRANSFORMING")
	Paralyze(1, ignore_canstun = TRUE)
	for(var/obj/item/W in src)
		dropItemToGround(W)
	icon = null
	invisibility = INVISIBILITY_MAXIMUM

	var/mob/living/carbon/human/W = stored_mob
	stored_mob = null
	REMOVE_TRAIT(W, TRAIT_NOSLEEP, TRAIT_GENERIC)
	if(dead)
		W.death(gibbed)

	W.forceMove(get_turf(src))

	REMOVE_TRAIT(W, TRAIT_NOMOOD, TRAIT_GENERIC)

	mind.transfer_to(W)

	var/mob/living/carbon/human/species/werewolf/WA = src
	W.copy_known_languages_from(WA.stored_language)
	skills?.known_skills = WA.stored_skills.Copy()
	skills?.skill_experience = WA.stored_experience.Copy()

	W.RemoveSpell(new /obj/effect/proc_holder/spell/self/howl/call_of_the_moon)
	W.RemoveSpell(new /obj/effect/proc_holder/spell/self/claws)

	W.regenerate_icons()

	to_chat(W, span_userdanger("I return to my facade."))
	playsound(W.loc, pick('sound/combat/gib (1).ogg','sound/combat/gib (2).ogg'), 200, FALSE, 3)
	W.spawn_gibs(FALSE)
	W.Knockdown(30)
	W.Stun(30)

	qdel(src)
