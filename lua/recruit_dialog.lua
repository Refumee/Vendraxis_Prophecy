local T = wml.tag
local W = wml.fire
local _ = wesnoth.textdomain 'wesnoth-help'

-- After preshow, this variable will hold the unit_types being shown in the listbox.
local listedZombies = {}
-- These two variables will be passed back to the WML engine.
local recruitedType
local recruitCost

local recruit = wml.variables.recruit
local zombies = wml.array_access.get(recruit)
local sides = wesnoth.sides.find{}

local zombie_recruit_dialog = wml.load "~add-ons/Vendraxis_Prophecy/gui/recruit_dialog.cfg"

local function preshow(dialog)

    local function select()
        -- TODO: why not use unit_preview_pane widget ?
        local index = listedZombies[dialog.unit_list.selected_index]
        local unit_type = wesnoth.unit_types[index]
        local race_set = unit_type.race
        dialog.large_unit_sprite.label = unit_type.image .. "~RC(magenta>".. wesnoth.sides[1].color .. ")~XBRZ(2)"
        dialog.unit_level.label = "Lvl " .. unit_type.level .. ""
		dialog.unit_alignment.label = "../../images/icons/alignments/alignment_" .. unit_type.alignment .. "_30.png"
		if unit_type.race == "desert-lizard" then
			dialog.unit_race_icon.label = "data/add-ons/Refumees_Saurian_Pack/images/icons/unit-groups/race_" .. unit_type.race .. "_30.png"
		elseif unit_type.race == "thief-lizard" then
			dialog.unit_race_icon.label = "data/add-ons/Refumees_Saurian_Pack/images/icons/unit-groups/race_" .. unit_type.race .. "_30.png"
		elseif unit_type.race == "deep-lizard" then
			dialog.unit_race_icon.label = "data/add-ons/Refumees_Saurian_Pack/images/icons/unit-groups/race_" .. unit_type.race .. "_30.png"
		else
			dialog.unit_race_icon.label = "../../images/icons/unit-groups/race_" .. unit_type.race .. "_30.png"
		end
        dialog.unit_race.label = "" .. wesnoth.races[race_set].plural_name  .. ""
        dialog.large_unit_type.label = "<span size='large'>" .. unit_type.name .. "</span>"
        dialog.unit_points.label     = "<span color='#20dc00'><b>".. _"HP: ".. "</b>" .. unit_type.max_hitpoints .. "</span> | <span color='#00a0e1'><b>".. _"XP: ".. "</b>" .. unit_type.max_experience .. "</span> | <b>".. _"MP: ".. "</b>" .. unit_type.max_moves

		local cfg = unit_type.__cfg

		-- find abilities table
		local abilities_table = nil
		for i, v in ipairs(cfg) do
			if v[1] == "abilities" and type(v[2]) == "table" then
				abilities_table = v[2]
				break
			end
		end

		-- collect abilities table names
		local ability_names = {}
		if abilities_table then
			for _, ab in ipairs(abilities_table) do
				if type(ab) == "string" then
					table.insert(ability_names, tostring(ab))
				elseif type(ab) == "table" then
					if ab[2] and ab[2].name then
						table.insert(ability_names, tostring(ab[2].name))
					elseif ab[1] then
						table.insert(ability_names, tostring(ab[1]))
					end
				end
			end
		end
		local ab_text = _ "Abilities"
		-- put it into gui
		if #ability_names > 0 then
			dialog.unit_attack_ability.label = "<span color='#f5e6c1'>     " .. table.concat(ability_names, ", ") .. "</span>"
			dialog.unit_attack_ability_title.label = "<b>" .. ab_text .. "</b>"
		else
			dialog.unit_attack_ability_title.label = ""
			dialog.unit_attack_ability.label = ""
		end
		
		dialog.unit_attack_range.label     ="../../images/icons/profiles/".. unit_type.attacks[1].range  .."_attack.png"
        dialog.unit_attack_icon.label     ="../../images/icons/profiles/".. unit_type.attacks[1].type  ..".png"
        dialog.unit_attack.label     = "<span color='#f5e6c1'> ".. unit_type.attacks[1].damage  .."x".. unit_type.attacks[1].number   .." " .. unit_type.attacks[1].description .. "</span>"
		
		if unit_type.attacks[2] then
			dialog.unit_attack_range2.label     ="../../images/icons/profiles/".. unit_type.attacks[2].range  .."_attack.png"
			dialog.unit_attack_icon2.label     ="../../images/icons/profiles/".. unit_type.attacks[2].type  ..".png"
			dialog.unit_attack2.label     = "<span color='#f5e6c1'> ".. unit_type.attacks[2].damage  .."x".. unit_type.attacks[2].number   .." " .. unit_type.attacks[2].description .. "</span>"
		else
			dialog.unit_attack_range2.label     =""
			dialog.unit_attack_icon2.label     =""
			dialog.unit_attack2.label     = ""
		end
		
		local specials = unit_type.attacks[1].specials

		if specials and #specials > 0 then
			for _,sp in ipairs(unit_type.attacks[1].specials) do
				if sp[1] then
					dialog.unit_attack_special.label     = "<span color='#f5e6c1'>     ".. sp[2].id .. "</span>"
				else
					dialog.unit_attack_special.label     = "0"
				end
			end
		else
			dialog.unit_attack_special.label     = ""
		end

		if unit_type.attacks[2] then
			local specials2 = unit_type.attacks[1].specials

			if specials2 and #specials2 > 0 then
				for _,sp in ipairs(unit_type.attacks[2].specials) do
					if sp[2] then
						dialog.unit_attack_special2.label     = "<span color='#f5e6c1'>     ".. sp[2].id .. "</span>"
					else
						dialog.unit_attack_special2.label     = ""
					end
				end
			else
				dialog.unit_attack_special2.label     =  ""
			end
		else
			dialog.unit_attack_special2.label     = ""
		end

    end

    dialog.unit_list.on_modified = select

    function dialog.help_button.on_button_click()
        W.open_help { topic="recruit_and_recall" }
    end

    function dialog.unit_help_button.on_button_click()
        W.open_help { topic="unit_" .. listedZombies[dialog.unit_list.selected_index] }
    end

    for i,z in ipairs(zombies) do
        if z.allow_recruit then
            local unit_type = wesnoth.unit_types[z.type]
            local afford_color_span_start = ""
            local afford_color_span_end = ""
            if sides[1].gold < unit_type.cost then
                afford_color_span_start = "<span color='red'>"
                afford_color_span_end = "</span>"
            end

            local list_item = dialog.unit_list:add_item()
            if z.sota_name_in_recruit_dialog then
                list_item.unit_type.label   = afford_color_span_start .. z.sota_name_in_recruit_dialog .. afford_color_span_end
            else
                -- the player started the campaign with 1.15.6 or earlier
                list_item.unit_type.label   = afford_color_span_start .. unit_type.name .. " " .. z.sota_variation .. afford_color_span_end
            end
            list_item.unit_sprite.label = unit_type.image .. "~RC(magenta>".. wesnoth.sides[1].color .. ")"
            list_item.unit_cost.label   = afford_color_span_start .. unit_type.cost .. afford_color_span_end

            print("dialog.unit_list.size", dialog.unit_list.item_count)
            listedZombies[ dialog.unit_list.item_count ] = z.type
        end
    end
    dialog.unit_list.selected_index = 1
    select()
end

local function postshow(dialog)
    recruitedType = listedZombies[dialog.unit_list.selected_index]
    recruitCost = wesnoth.unit_types[ recruitedType ].cost
end

-- Start execution --

-- Find out if there is at least one zombie in the list box.
-- This will only be necessary if the WML changes, but it could, so we'll check.
local zArrayIndex = 1  -- Start index of the WML array in lua.
local zExists = false
while zombies[zArrayIndex] and zExists == false do
    local z=zombies[zArrayIndex]
    if z.allow_recruit then
        zExists=true
    end
    zArrayIndex = zArrayIndex + 1
end

wml.variables["recruitedZombieType"] = "cancel" -- default value

if zExists==false then
    gui.show_prompt("", _ "There are no corpses available.", "")
else
    local result = wesnoth.sync.evaluate_single(function()
        local res = gui.show_dialog(wml.get_child(zombie_recruit_dialog, 'resolution'), preshow, postshow)
        if res == -2 then
            return {recruitCost = 0, recruitedType = "cancel"}
        end
        if sides[1].gold  < recruitCost then
            gui.show_prompt("", _ "You do not have enough gold to recruit that unit", "")
            return {recruitCost = 0, recruitedType = "cancel"}
        end
        return {recruitCost = recruitCost, recruitedType = recruitedType}
    end)
    wml.variables["recruitedZombieType"] = result.recruitedType
    wml.variables["recruitedZombieCost"] = result.recruitCost
end
