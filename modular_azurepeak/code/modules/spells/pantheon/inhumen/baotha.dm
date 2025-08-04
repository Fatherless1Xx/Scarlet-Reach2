//Baotha's Blessings - T1, reverses overdose effect on a target + soothing moodlet. (Medieval narcan..... #BanNarcan)

/obj/effect/proc_holder/spell/invoked/baothablessings
	name = "Baotha's Blessings"
	overlay_state = "lesserheal"
	releasedrain = 30
	chargedrain = 0
	chargetime = 5
	range = 4
	warnie = "sydwarning"
	movement_interrupt = FALSE
	sound = 'sound/magic/heal.ogg'
	chargedloop = /datum/looping_sound/invokeholy
	invocation_type = "shout"
	invocation = "Praise Baotha! Grant us your divine indulgence!"
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = TRUE
	recharge_time = 30 SECONDS
	miracle = TRUE
	devotion_cost = 10

/obj/effect/proc_holder/spell/invoked/baothablessings/cast(list/targets, mob/living/user)
	if(isliving(targets[1]))
		var/mob/living/carbon/target = targets[1]
		if(HAS_TRAIT(target, TRAIT_PSYDONITE))
			target.visible_message(span_info("[target] stirs for a moment, the miracle dissipates."), span_notice("A dull warmth swells in your heart, only to fade as quickly as it arrived."))
			user.playsound_local(user, 'sound/magic/PSY.ogg', 100, FALSE, -1)
			playsound(target, 'sound/magic/PSY.ogg', 100, FALSE, -1)
			return FALSE
		if(target.has_status_effect(/datum/status_effect/buff/druqks/baotha))
			to_chat(user, span_warning("They're already blessed by these effects!"))
			revert_cast()
			return FALSE
		target.apply_status_effect(/datum/status_effect/buff/druqks/baotha) //Gets the trait temorarily, basically will just stop any active/upcoming ODs.
		
		// Fill hunger and thirst
		if(iscarbon(target))
			var/mob/living/carbon/C = target
			C.adjust_nutrition(500) // Fill to well-fed level
			C.adjust_hydration(500) // Fill to hydrated level
		
		// Restore stamina
		target.stamina_add(50)
		
		target.visible_message("<span class='info'>[target]'s eyes appear to gloss over!</span>", "<span class='notice'>I feel.. at ease.</span>")
		
		return TRUE

//Enrapturing Powder - T2, basically a crackhead blowing cocaine in your face.

/obj/effect/proc_holder/spell/invoked/projectile/blowingdust
	name = "Enrapturing Powder"
	desc = "Baotha's presence is always known, finding her blessings gathering on you like dust. With a good swipe, I could make others indulge in her fruits.."
	clothes_req = FALSE
	range = 3	//It's literally blowing coke in their face, basically.
	associated_skill = /datum/skill/magic/holy
	projectile_type = /obj/projectile/magic/blowingdust
	chargedloop = /datum/looping_sound/invokeholy
	releasedrain = 30
	chargedrain = 0
	chargetime = 15
	recharge_time = 10 SECONDS
	invocation = "Baotha's divine dust, embrace the ecstasy!"
	invocation_type = "shout"
	devotion_cost = 30

/obj/projectile/magic/blowingdust
	name = "unholy dust"
	icon_state = "spark"
	nodamage = FALSE
	damage = 1
	poisontype = /datum/reagent/herozium
	poisonfeel = "burning" //Would make sense for your eyes or nose to burn, I guess.
	poisonamount = 8 //Decent bit of high, three doses would be just above the overdose threshold if applied fast enough.

/obj/projectile/magic/blowingdust/on_hit(target)
	. = ..()
	if(!istype(target, /mob/living))
		return
		
	var/mob/living/M = target
	to_chat(M, span_warning("Gah! Something.. got in my - eyes.."))
	M.blur_eyes(2)
	
	if(iscarbon(M))
		var/mob/living/carbon/C = M
		
		// Debug message to confirm the projectile hit
		to_chat(C, span_notice("DEBUG: Enrapturing Powder hit! Applying effects..."))
		
		// Apply emberwine reagent (like drinking it)
		C.reagents.add_reagent(/datum/reagent/consumable/ethanol/beer/emberwine, 12)
		to_chat(C, span_notice("DEBUG: Added emberwine reagent"))
		
		// Apply emberwine status effect immediately for spell effect
		C.apply_status_effect(/datum/status_effect/debuff/emberwine)
		to_chat(C, span_notice("DEBUG: Applied emberwine status effect immediately"))
		
		// Apply drunk effects
		C.drunkenness = 15
		C.apply_status_effect(/datum/status_effect/buff/drunk)
		C.Dizzy(25)
		to_chat(C, span_notice("DEBUG: Applied drunk effects"))
		
		// Apply confusion for drunk walking (like flash effects)
		if(C.flash_act(2))
			C.confused += 30 // Higher confusion for more noticeable drunk walking
			to_chat(C, span_notice("DEBUG: Applied flash and confusion"))
		else
			to_chat(C, span_notice("DEBUG: Flash failed, applying confusion anyway"))
			C.confused += 30
		
		to_chat(C, span_notice("You feel the warmth of Baotha's divine dust coursing through your veins..."))

//Numbing Pleasure - T3, removes all pain from self for a period of time. (Similar to Ravox's without any blood-clotting and better pain suppression + good mood buff.)
/obj/effect/proc_holder/spell/invoked/painkiller
	name = "Numbing Pleasure"
	overlay_state = "astrata"
	releasedrain = 30
	chargedrain = 0
	chargetime = 0
	range = 7
	warnie = "sydwarning"
	sound = 'sound/magic/timestop.ogg'
	invocation = "By Baotha's grace, let pain become pleasure!"
	invocation_type = "shout"
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = TRUE
	recharge_time = 90 SECONDS
	miracle = TRUE
	devotion_cost = 75

/obj/effect/proc_holder/spell/invoked/painkiller/cast(list/targets, mob/living/user)
	if(isliving(targets[1]))
		var/mob/living/target = targets[1]
		var/mob/living/carbon/human/human_target = target
		var/datum/physiology/phy = human_target.physiology
		if(target.mob_biotypes & MOB_UNDEAD)
			return FALSE	//No, you don't get to feel good. You're a undead mob. Feel bad.
		target.visible_message(span_info("[target] begins to twitch as warmth radiates from them!"), span_notice("The pain from my wounds fade, every new one being a mere, pleasent warmth!"))
		phy.pain_mod *= 0.5	//Literally halves your pain modifier.
		addtimer(VARSET_CALLBACK(phy, pain_mod, phy.pain_mod /= 0.5), 1 MINUTES)	//Adds back the 0.5 of pain, basically setting it back to 1.
		target.apply_status_effect(/datum/status_effect/buff/vitae)					//Basically lowers fortune by 2 but +3 speed, it's powerful. Drugs cus Baotha.
		
		// Apply divine protection - no blood loss, no  uncon, no death.
		// Apply divine protection status effect
		target.apply_status_effect(/datum/status_effect/buff/divine_protection, 1 MINUTES)
		
		// Send message about feeling invincible
		to_chat(target, span_notice("I feel invincible! Nothing can harm me while Baotha's grace protects me!"))
		
		return TRUE

//T0 that tells the user the person's vice.
/obj/effect/proc_holder/spell/invoked/baothavice
	name = "Tell Vice"
	overlay_state = "baotha_vice"
	releasedrain = 10
	chargedrain = 0
	chargetime = 0
	range = 3
	warnie = "sydwarning"
	movement_interrupt = FALSE
	invocation_type = "none"
	associated_skill = /datum/skill/magic/holy
	antimagic_allowed = TRUE
	recharge_time = 5 SECONDS 
	miracle = TRUE
	devotion_cost = 10
	var/list/fake_vices = list()

/obj/effect/proc_holder/spell/invoked/baothavice/cast(list/targets, mob/living/user)
	if(ishuman(targets[1]))
		var/vice_found
		var/mob/living/carbon/human/H = targets[1]
		if(HAS_TRAIT(H, TRAIT_DECEIVING_MEEKNESS) && user.get_skill_level(/datum/skill/magic/holy) > SKILL_LEVEL_NOVICE)
			if(!(H in fake_vices))
				fake_vices[H] = pick(GLOB.character_flaws)
				vice_found = fake_vices[H]
			else
				vice_found = fake_vices[H]
		if(!vice_found)
			vice_found = H.charflaw.name
		to_chat(user, span_info("They are... [span_warning("a [vice_found]")]"))
		return TRUE
	revert_cast()
	return FALSE
