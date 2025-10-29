-- original code credits to fluffbeast
-- modified by Lord-Knightmare to accomodate lvl 1 and lvl 0 units

function wesnoth.wml_actions.adjust_recall_costs(cfg)
    -- currently revised recall costs
    -- | Unit Level | Recall Cost |
    -- | ---------- | ----------- |
    -- |     0      |     5      |
    -- |     1      |     15      |
    -- |     2      |     20      |
    -- |     3      |     20      |
    -- |     4      |     20      |
    -- |     5+     |     20      |
    -- | ---------- | ----------- |
    for _, unit in ipairs(wesnoth.units.find_on_recall {}) do
        if unit.level == 0 then
            unit.recall_cost = 5
        elseif unit.level == 1 then
            unit.recall_cost = 15
        elseif unit.level == 2 then
            unit.recall_cost = 20
        else 
            unit.recall_cost = 20
        end
    end
end