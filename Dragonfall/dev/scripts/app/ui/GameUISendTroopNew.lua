--
-- Author: Kenny Dai
-- Date: 2016-03-04 10:12:55
--
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetPushButton = import("..widget.WidgetPushButton")
local UIScrollView = import(".UIScrollView")
local StarBar = import(".StarBar")
local Localize = import("..utils.Localize")
local UIListView = import(".UIListView")
local WidgetSlider = import("..widget.WidgetSlider")
local WidgetSelectDragon = import("..widget.WidgetSelectDragon")
local DragonSprite = import("..sprites.DragonSprite")
local WidgetInput = import("..widget.WidgetInput")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local maxTroopPerDragon = GameDatas.AllianceInitData.intInit.maxTroopPerDragon.value


local Corps = import(".Corps")
local UILib = import(".UILib")
local window = import("..utils.window")
local normal = GameDatas.Soldiers.normal
local SPECIAL = GameDatas.Soldiers.special

local GameUISendTroopNew = UIKit:createUIClass("GameUISendTroopNew","GameUIWithCommonHeader")
GameUISendTroopNew.dragonType = nil

local soldier_arrange = {
    swordsman_1 = {row = 2, col = 2, x = -30, y = 10},
    swordsman_2 = {row = 2, col = 2, x = -30, y = 10},
    swordsman_3 = {row = 2, col = 2, x = -30, y = 10},
    ranger_1 = {row = 2, col = 2, x = -30, y = 10},
    ranger_2 = {row = 2, col = 2, x = -30, y = 10},
    ranger_3 = {row = 2, col = 2, x = -30, y = 10},
    lancer_1 = {row = 2, col = 1, x = -30, y = 10},
    lancer_2 = {row = 2, col = 1, x = -10, y = 10},
    lancer_3 = {row = 2, col = 1, x = -30, y = 10},
    catapult_1 = {row = 1, col = 1, x = -160, y = -20},
    catapult_2 = {row = 1, col = 1, x = -150, y = -20},
    catapult_3 = {row = 1, col = 1, x = -150, y = -20},

    horseArcher_1 = {row = 2, col = 1, x = -30, y = 10},
    horseArcher_2 = {row = 2, col = 1, x = -30, y = 10},
    horseArcher_3 = {row = 2, col = 1, x = -30, y = 10},
    ballista_1 = {row = 1, col = 1, x = -30, y = -20},
    ballista_2 = {row = 1, col = 1, x = -30, y = -20},
    ballista_3 = {row = 1, col = 1, x = -30, y = -20},
    skeletonWarrior = {row = 2, col = 2, x = -38, y = 10},
    skeletonArcher = {row = 2, col = 2, x = -38, y = 10},

    deathKnight = {row = 2, col = 1, x = -30, y = 10},
    meatWagon = {row = 1, col = 1, x = -150, y = -20},
    priest = {row = 2, col = 1, x = -30, y = 10},
    demonHunter = {row = 2, col = 1, x = -30, y = 10},

    paladin = {row = 2, col = 2, x = -30, y = 10},
    steamTank = {row = 1, col = 1, x = -30, y = 10},
    sentinel_1 = {row = 2, col = 2, x = -30, y = 10},
    sentinel_2 = {row = 2, col = 2, x = -30, y = 10},
    sentinel_3 = {row = 2, col = 2, x = -30, y = 10},
    crossbowman_1 = {row = 2, col = 2, x = -30, y = 10},
    crossbowman_2 = {row = 2, col = 2, x = -30, y = 10},
    crossbowman_3 = {row = 2, col = 2, x = -30, y = 10},
}

function GameUISendTroopNew:GetMyAlliance()
    return Alliance_Manager:GetMyAlliance()
end
function GameUISendTroopNew:GetMarchTime(soldier_show_table)
    local mapObject = self:GetMyAlliance():FindMapObjectById(self:GetMyAlliance():GetSelf():MapId())
    local fromLocation = mapObject.location
    local target_alliance = self.targetAlliance
    local time = DataUtils:getPlayerSoldiersMarchTime(soldier_show_table,self:GetMyAlliance(),fromLocation,target_alliance,self.toLocation)
    local buffTime = DataUtils:getPlayerMarchTimeBuffTime(time)
    return time,buffTime
end
function GameUISendTroopNew:RefreshMarchTimeAndBuff()
    if self.march_time then
        local soldier_show_table = {}
        local settingSoldiers = self:GetSettingSoldiers()
        for i,soldier in ipairs(settingSoldiers) do
            local config = UtilsForSoldier:GetSoldierConfig(User,soldier.name)
            table.insert(soldier_show_table, {soldier_citizen = config.citizen * soldier.count,soldier_march = config.march})
        end
        local time,buffTime = self:GetMarchTime(soldier_show_table)
        self.march_time:setString(GameUtils:formatTimeStyle1(time))
        self.buff_reduce_time:setString(string.format("-(%s)",GameUtils:formatTimeStyle1(buffTime)))
        self.total_march_time = time - buffTime
    end
end

function GameUISendTroopNew:ctor(march_callback,params)
    checktable(params)
    self.isPVE = type(params.isPVE) == 'boolean' and params.isPVE or false
    self.isMilitary = type(params.isMilitary) == 'boolean' and params.isMilitary or false -- 是否为驻防
    self.returnCloseAction = type(params.returnCloseAction) == 'boolean' and params.returnCloseAction or false
    self.toLocation = params.toLocation or cc.p(0,0)
    self.targetAlliance = params.targetAlliance
    self.terrain = params.terrain or User.basicInfo.terrain
    self.military_soldiers = params.military_soldiers -- 编辑驻防部队时传入当前驻防部队信息
    GameUISendTroopNew.super.ctor(self,City,params.title or _("准备进攻"))
    self.alliance = self:GetMyAlliance()

    self.march_callback = march_callback
    self.params = params

    -- 默认选中最强的并且可以出战的龙,如果都不能出战，则默认最强龙
    local fightPowerfulType = UtilsForDragon:GetCanFightPowerfulDragonType(User)
    local fightPowerfulDragon = UtilsForDragon:GetDragon(User, (self.isPVE and self.dragonType) or fightPowerfulType)

    local powerfulType = UtilsForDragon:GetPowerfulDragonType(User)
    local powerfulDragon = UtilsForDragon:GetDragon(User, powerfulType)

    self.dragon = params.dragon or fightPowerfulDragon or powerfulDragon
    if self.isPVE then
        GameUISendTroopNew.dragonType = self.dragon.type
    end
end

function GameUISendTroopNew:OnMoveInStage()
    GameUISendTroopNew.super.OnMoveInStage(self)
    if self.params.needTips then
        scheduleAt(self, function()
            self:CheckRate()
        end, 0.618)
    end
end
function GameUISendTroopNew:CreateBetweenBgAndTitle()
    GameUISendTroopNew.super.CreateBetweenBgAndTitle(self)
    self:CreateTerrainBackground()
    self:SelectDragonPart()
    self:SelectSoldiersPart()
    self:CreateBottomPart()
    self:RefreashDragon()
end
function GameUISendTroopNew:onExit()
    GameUISendTroopNew.super.onExit(self)
end
-- 创建城市地形背景
function GameUISendTroopNew:CreateTerrainBackground()
    local clip = display.newClippingRegionNode(cc.rect(16, 10, 612, 900))
        :align(display.LEFT_BOTTOM,window.left,window.bottom)
        :addTo(self:GetView())
    UIKit:CreateTerrainForNode(clip)
end
function GameUISendTroopNew:SelectDragonPart()
    if not self.dragon then return end
    local dragon = self.dragon
    local dragon_box = display.newSprite("box_send_troop_204x192.png")
        :align(display.CENTER, window.cx + 120,window.top - 300)
        :addTo(self:GetView())

    WidgetPushButton.new()
        :addTo(self:GetView()):align(display.CENTER, window.cx + 120,window.top - 300)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SelectDragon()
            end
        end):setContentSize(cc.size(204,192))
    -- 龙动画
    self.dragon_armature = DragonSprite.new(display.getRunningScene():GetSceneLayer(),dragon.type)
        :addTo(dragon_box)
        :pos(dragon_box:getContentSize().width/2,dragon_box:getContentSize().height/2)
        :scale(0.65)
        :setRotationSkewY(180)
    -- 龙信息
    local dragon_frame = display.newScale9Sprite("background_notice_128x128_1.png", 0, 0,cc.size(364,432),cc.rect(30,30,68,68))
        :align(display.RIGHT_BOTTOM, window.right - 20,window.bottom + 100)
        :addTo(self:GetView())

    local dragon_name_bg = display.newSprite("background_red_558x42.png")
        :align(display.CENTER, dragon_frame:getContentSize().width/2,dragon_frame:getContentSize().height - 30)
        :addTo(dragon_frame)

    -- 龙，等级
    self.dragon_name = UIKit:ttfLabel({
        text = Localize.dragon[dragon.type].."（LV ".. dragon.level..")",
        size = 24,
        color = 0xfed36c,
    }):align(display.CENTER,dragon_name_bg:getContentSize().width/2,dragon_name_bg:getContentSize().height/2)
        :addTo(dragon_name_bg)
    -- 状态
    UIKit:ttfLabel({
        text = _("状态"),
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER,30,dragon_name_bg:getPositionY() - 40)
        :addTo(dragon_frame)

    local isfree = UtilsForDragon:IsDragonFree(User, dragon.type)
    local isdead = UtilsForDragon:IsDragonDead(User, dragon.type)
    local desc = UtilsForDragon:GetDragonStatusDesc(UtilsForDragon:GetDragon(User, dragon.type))
    self.dragon_status = UIKit:ttfLabel({
        text = desc,
        size = 22,
        color = isfree and not isdead and 0xffedae or 0xff3c00,
    }):align(display.RIGHT_CENTER,330,dragon_name_bg:getPositionY() - 40)
        :addTo(dragon_frame)
    -- 龙生命值
    UIKit:ttfLabel({
        text = _("生命值"),
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER,30,self.dragon_status:getPositionY() - 40)
        :addTo(dragon_frame)

    local hp = UtilsForDragon:GetDragonHp(User, dragon.type)
    local hpMax = UtilsForDragon:GetDragonMaxHp(User.dragons[dragon.type])
    self.dragon_hp = UIKit:ttfLabel({
        text = string.formatnumberthousands(hp).."/"..string.formatnumberthousands(hpMax),
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER,330,self.dragon_status:getPositionY() - 40)
        :addTo(dragon_frame)
    -- 龙攻击力
    UIKit:ttfLabel({
        text = _("攻击力"),
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER,30,self.dragon_hp:getPositionY() - 40)
        :addTo(dragon_frame)

    local strength = UtilsForDragon:GetDragonStrength(User.dragons[dragon.type])
    self.dragon_strength = UIKit:ttfLabel({
        text = string.formatnumberthousands(strength),
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER,330,self.dragon_hp:getPositionY() - 40)
        :addTo(dragon_frame)

    local send_troops_btn = WidgetPushButton.new({normal = 'tmp_button_battle_up_234x82.png',pressed = 'tmp_button_battle_down_234x82.png'},{scale9 = true})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("选择"),
            size = 22,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SelectDragon()
            end
        end):align(display.CENTER,dragon_frame:getContentSize().width/2,dragon_frame:getContentSize().height/2):addTo(dragon_frame)
        :setButtonSize(188,66)

    local bottom_info_bg = display.newScale9Sprite("background_notice_128x128_2.png", 0, 0,cc.size(328,146),cc.rect(15,15,98,98))
        :align(display.CENTER_BOTTOM,dragon_frame:getContentSize().width/2,20)
        :addTo(dragon_frame)

    -- 士兵总战斗力
    local soldier_power = UIKit:ttfLabel({
        text = _("战斗力"),
        size = 22,
        color = 0xbbae80,
    }):align(display.LEFT_CENTER,20,108)
        :addTo(bottom_info_bg)
    self.soldier_power = UIKit:ttfLabel({
        text = "0",
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER,310,108)
        :addTo(bottom_info_bg)

    local dragon_lead = UIKit:ttfLabel({
        text = _("带兵量"),
        size = 22,
        color = 0xbbae80,
    }):align(display.LEFT_CENTER,20,68)
        :addTo(bottom_info_bg)

    local leadCitizen = UtilsForDragon:GetLeadershipByCitizen(User,dragon.type)
    self.lead_citizen = UIKit:ttfLabel({
        text = "0/"..string.formatnumberthousands(leadCitizen),
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER,310,68)
        :addTo(bottom_info_bg)

    -- 龙负重
    local load = UIKit:ttfLabel({
        text = _("负重"),
        size = 22,
        color = 0xbbae80,
    }):align(display.LEFT_CENTER,20,28)
        :addTo(bottom_info_bg)
    self.soldier_load = UIKit:ttfLabel({
        text = "0",
        size = 22,
        color = 0xffedae,
    }):align(display.RIGHT_CENTER,310,28)
        :addTo(bottom_info_bg)
end
function GameUISendTroopNew:SelectDragon()
    WidgetSelectDragon.new(
        {
            title = _("选中出战的巨龙"),
            btns = {
                {
                    btn_label = _("确定"),
                    btn_callback = function (selectDragon)
                        if selectDragon ~= self.dragon then
                            self:ResetSoldierNode()
                            self:RefreashDragon(selectDragon)
                            self.isMax = false
                            self.max_btn:setButtonLabel(UIKit:ttfLabel({
                                text = _("最大"),
                                size = 24,
                                color = 0xffedae,
                                shadow= true
                            }))
                        end
                    end,
                },
            },

        }
    ):addTo(self,1000)
end
function GameUISendTroopNew:RefreashDragon(dragon)
    local dragon = dragon or self.dragon
    local dragonType = dragon.type
    self.dragon_armature:ReloadSpriteCauseTerrainChanged(dragonType)
    self.dragon_name:setString(Localize.dragon[dragonType].."（LV ".. dragon.level..")")
    local desc = UtilsForDragon:GetDragonStatusDesc(UtilsForDragon:GetDragon(User, dragonType))
    self.dragon_status:setString(desc)

    local isfree = UtilsForDragon:IsDragonFree(User, dragonType)
    local isdead = UtilsForDragon:IsDragonDead(User, dragonType)
    self.dragon_status:setColor(UIKit:hex2c3b(isfree and not isdead and 0xffedae or 0xff3c00))

    local hp = UtilsForDragon:GetDragonHp(User, dragonType)
    local hpMax = UtilsForDragon:GetDragonMaxHp(User.dragons[dragonType])
    self.dragon_hp:setString(string.formatnumberthousands(hp).."/"..string.formatnumberthousands(hpMax))

    local strength = UtilsForDragon:GetDragonStrength(User.dragons[dragonType])
    self.dragon_strength:setString(string.formatnumberthousands(strength))
    local power,load,citizen = self:GetTotalSoldierInfo()
    self.soldier_power:setString(string.formatnumberthousands(power))
    local leadCitizen = UtilsForDragon:GetLeadershipByCitizen(User,dragonType)
    self.lead_citizen:setString(string.formatnumberthousands(citizen).."/"..string.formatnumberthousands(leadCitizen))
    self.soldier_load:setString(string.formatnumberthousands(load))
    self.dragon = dragon
    if self.isPVE then
        GameUISendTroopNew.dragonType = dragonType
    end
end
-- 单个格子最大带兵量
function GameUISendTroopNew:GetUnitMaxCitizen()
    local leadCitizen = UtilsForDragon:GetLeadershipByCitizen(User,self.dragon.type)
    return math.floor(leadCitizen/maxTroopPerDragon)
end
function GameUISendTroopNew:SelectSoldiersPart()
    -- 每种龙无论等级和星级都有最大六个士兵格子可以配置士兵，每个格子最多派出选择的龙的带兵力的六分之一
    local origin_x,origin_y,gap_y = window.left + 30 , window.top_bottom - 30 ,125
    local soldier_node_table = {}
    for i=1,6 do
        local soldier_node = self:CreateSoldierNode():SetStatus(i==1 and 1 or 3):SetIndex(i):align(display.LEFT_TOP, origin_x, origin_y - (i-1) * gap_y):addTo(self:GetView())
        if self.military_soldiers and self.military_soldiers[i] then
            soldier_node:SetSoldier(self.military_soldiers[i].name,self.military_soldiers[i].count):SetStatus(2)
        end
        table.insert(soldier_node_table,soldier_node)
    end
    self.soldier_node_table = soldier_node_table
end
-- 士兵节点
function GameUISendTroopNew:CreateSoldierNode()
    local soldier_node = display.newNode()
    local s_size = cc.size(126,124)
    soldier_node:setContentSize(s_size)
    -- 配置士兵按钮
    local setSoldierBtn = WidgetPushButton.new()
        :align(display.CENTER,s_size.width/2,s_size.height/2)
        :addTo(soldier_node)
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                UIKit:newWidgetUI("WidgetSelectSoldiers", self:GetUnitMaxCitizen(),self.isMilitary,function (soldier_type,soldier_count)
                    if soldier_type and soldier_count then
                        if soldier_count == 0 then
                            soldier_node:SetStatus(1)
                        else
                            soldier_node:SetSoldier(soldier_type,soldier_count):SetStatus(2)
                        end
                    else
                        soldier_node:SetStatus(1)
                    end
                    self:RefreshSoldierNodes()
                end,self:GetSettingSoldiers(),self:GetSettingSoldiersByIndex(soldier_node:GetIndex()),soldier_node:GetIndex()):AddToCurrentScene()
            end
        end)
    setSoldierBtn:setContentSize(s_size)

    local add_sprite = display.newSprite("icon_plus_66x72.png")
        :align(display.CENTER,s_size.width/2,s_size.height/2)
        :addTo(soldier_node)
        :setVisible(configurable)
    add_sprite:runAction(
        cc.RepeatForever:create(
            transition.sequence{
                cc.ScaleTo:create(0.5/2, 1.2),
                cc.ScaleTo:create(0.5/2, 1.0),
            }
        )
    )

    -- 状态图标
    local status_icon = display.newSprite("box_send_troop_124x116.png")
        :align(display.CENTER,s_size.width/2,s_size.height/2)
        :addTo(soldier_node)
    -- 士兵战斗力框
    local power_bg = display.newSprite("background_100x40.png")
        :align(display.LEFT_BOTTOM,s_size.width,-10)
        :addTo(soldier_node)
    local index_label = UIKit:ttfLabel({
        text = "1",
        size = 16,
        color = 0xfed36d,
    }):align(display.CENTER,16,26)
        :addTo(power_bg)
    local power_label = UIKit:ttfLabel({
        text = "1",
        size = 16,
        color = 0xfed36d,
    }):align(display.CENTER,60,26)
        :addTo(power_bg)
    -- 设置士兵
    function soldier_node:SetSoldier(soldier_type,soldier_count)
        if self:getChildByTag(110) then
            self:removeChildByTag(110, true)
        end
        local arrange = soldier_arrange[soldier_type]
        local star = UtilsForSoldier:SoldierStarByName(User,soldier_type)
        local corp = Corps.new(soldier_type, star , arrange.row, arrange.col,120,120):align(display.CENTER, s_size.width + arrange.x,s_size.height + arrange.y):addTo(self):setTag(110)
        if not string.find(soldier_type , "catapult") and not string.find(soldier_type , "ballista") and not string.find(soldier_type , "meatWagon") then
            corp:PlayAnimation("idle_90")
        else
            corp:PlayAnimation("move_90")
        end
        power_label:setString(string.formatnumberthousands(soldier_count))
        self.soldier_type = soldier_type
        self.soldier_count = soldier_count
        return self
    end
    function soldier_node:SetIndex(index)
        index_label:setString(index)
        self.index = index
        return self
    end
    function soldier_node:GetIndex()
        return self.index
    end
    -- 设置当前状态 1:可编辑士兵 2:已有士兵 3:不能编辑
    function soldier_node:SetStatus(status)
        if status == 1 then
            add_sprite:show()
            status_icon:setTexture("box_send_troop_126x124.png")
            setSoldierBtn:setButtonEnabled(true)
            power_bg:hide()
            if self:getChildByTag(110) then
                self:removeChildByTag(110, true)
            end
        elseif status == 2 then
            add_sprite:hide()
            status_icon:setTexture("box_send_troop_124x116.png")
            setSoldierBtn:setButtonEnabled(true)
            power_bg:show()
        elseif status == 3 then
            add_sprite:hide()
            status_icon:setTexture("box_send_troop_124x116.png")
            setSoldierBtn:setButtonEnabled(fasle)
            power_bg:hide()
            if self:getChildByTag(110) then
                self:removeChildByTag(110, true)
            end
        end
        self.status = status
        return self
    end
    function soldier_node:GetStatus()
        return self.status
    end
    function soldier_node:GetSoldiers()
        return self.soldier_type,self.soldier_count
    end
    return soldier_node
end
function GameUISendTroopNew:RefreshSoldierNodes()
    local soldier_node_table = self.soldier_node_table
    -- 首先取出所有已经设置的士兵信息
    local current_soldiers = self:GetSettingSoldiers()
    local has_soldiers = false
    for i,soldier_node in ipairs(soldier_node_table) do
        if current_soldiers[i] then
            soldier_node:SetSoldier(current_soldiers[i].name,current_soldiers[i].count):SetStatus(2)
            has_soldiers = true
        else
            if i == 1 or current_soldiers[i-1] then
                soldier_node:SetStatus(1)
            else
                soldier_node:SetStatus(3)
            end
        end
    end
    self:RefreashDragon()
    self:RefreshMarchTimeAndBuff()
    if has_soldiers then
        self.isMax = true
        self.max_btn:setButtonLabel(UIKit:ttfLabel({
            text = _("最小"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
    end
end
function GameUISendTroopNew:ResetSoldierNode()
    for i,soldier_node in ipairs(self.soldier_node_table) do
        if i == 1 then
            soldier_node:SetStatus(1)
        else
            soldier_node:SetStatus(3)
        end
    end
end
function GameUISendTroopNew:GetSettingSoldiers()
    local current_soldiers = {}
    for i,soldier_node in ipairs(self.soldier_node_table) do
        if soldier_node:GetStatus() == 2 then
            local soldier_type,soldier_count = soldier_node:GetSoldiers()

            table.insert(current_soldiers, {name = soldier_type,count = soldier_count})
        end
    end
    return current_soldiers
end
function GameUISendTroopNew:GetSettingSoldiersByIndex(index)
    local soldiers_index = {}
    for i,soldier_node in ipairs(self.soldier_node_table) do
        if soldier_node:GetStatus() == 2 and index == i then
            local soldier_type,soldier_count = soldier_node:GetSoldiers()
            soldiers_index.name = soldier_type
            soldiers_index.count = soldier_count
        end
    end
    return soldiers_index
end
function GameUISendTroopNew:GetTotalSoldierInfo()
    local current_soldiers = self:GetSettingSoldiers()
    local power,load,citizen = 0,0,0
    for i,soldier in ipairs(current_soldiers) do
        local config = UtilsForSoldier:GetSoldierConfig(User,soldier.name)
        power = power + config.power * soldier.count
        load = load + config.load * soldier.count
        citizen = citizen + config.citizen * soldier.count
    end
    return power,load,citizen
end
function GameUISendTroopNew:CreateBottomPart()
    local bottom_bg = display.newScale9Sprite("back_ground_619x52.png", 0, 0,cc.size(620,80),cc.rect(30,20,559,12))
        :align(display.BOTTOM_CENTER, window.cx,window.bottom)
        :addTo(self:GetView())
    self.isMax = self.military_soldiers ~= nil
    local max_btn = WidgetPushButton.new({normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = self.military_soldiers and _("最小") or _("最大"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                self:SetMaxSoldier()
            end
        end):align(display.LEFT_CENTER,30,bottom_bg:getContentSize().height/2):addTo(bottom_bg)
    self.max_btn = max_btn

    if self.params.needTips and UtilsForTask:NeedTips(User) then
        UIKit:FingerAni():addTo(self.max_btn,11,111):rotation(-80):pos(170,30)
        self.max_btn:onButtonClicked(function()
            self.max_btn:removeChildByTag(111)
            UIKit:FingerAni():addTo(self.march_btn,11,111):rotation(80):pos(-170,30):setScaleX(-1)
            self.march_btn:onButtonClicked(function()
                self.march_btn:removeChildByTag(111)
            end)
        end)
    end
    local march_btn = WidgetPushButton.new({normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"},nil,nil)
        :setButtonLabel(UIKit:ttfLabel({
            text = self.isMilitary and _("驻防") or _("行军"),
            size = 24,
            color = 0xffedae,
            shadow= true
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                assert(tolua.type(self.march_callback)=="function")
                if not self.dragon then
                    UIKit:showMessageDialog(_("提示"),_("您还没有龙,快去孵化一只巨龙吧"))
                    return
                end
                local dragonType = self.dragon.type
                local soldiers = self:GetSettingSoldiers()

                local isfree = UtilsForDragon:IsDragonFree(User, dragonType)
                local isdefn = UtilsForDragon:IsDragonDefenced(User, dragonType)
                local isdead = UtilsForDragon:IsDragonDead(User, dragonType)
                if not isfree and not isdefn then
                    UIKit:showMessageDialog(_("提示"),_("龙未处于空闲状态"))
                    return
                elseif isdead then
                    UIKit:showMessageDialog(_("提示"),_("选择的龙已经死亡")):CreateCancelButton(
                        {
                            listener = function ()
                                UIKit:newGameUI("GameUIDragonEyrieMain", City, City:GetFirstBuildingByType("dragonEyrie"), "dragon", false, dragonType):AddToCurrentScene(true)
                                self:LeftButtonClicked()
                            end,
                            btn_name= _("复活"),
                            btn_images = {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"}
                        }
                    )
                    return
                elseif #soldiers == 0 then
                    UIKit:showMessageDialog(_("提示"),_("请选择要派遣的部队"))
                    return
                elseif self.alliance:IsReachEventLimit() and not self.isMilitary and not self.isPVE then
                    local dialog = UIKit:showMessageDialog(_("提示"),_("没有空闲的行军队列"))
                    if User.basicInfo.marchQueue < 2 then
                        dialog:CreateOKButton(
                            {
                                listener = function ()
                                    UIKit:newGameUI("GameUIWatchTower", City, "march"):AddToCurrentScene(true)
                                    self:LeftButtonClicked()
                                end,
                                btn_name= _("前往解锁")
                            }
                        )
                    end
                    return
                end
                if self.dragon.status == 'defence' and not self.military_soldiers and not self.isPVE then
                    UIKit:showMessageDialog(_("提示"),_("当前选择的龙处于驻防状态，是否取消驻防将这条龙派出")):CreateOKButton(
                        {
                            listener = function ()
                                NetManager:getCancelDefenceTroopPromise():done(function()
                                    self:CallFuncMarch_Callback(dragonType,soldiers)
                                    self:LeftButtonClicked()
                                end)
                            end,
                            btn_name= _("派出"),
                            btn_images = {normal = "red_btn_up_148x58.png",pressed = "red_btn_down_148x58.png"}
                        }
                    ):CreateCancelButton({
                        listener = function ()
                        end,
                        btn_name= _("取消"),
                        btn_images = {normal = "yellow_btn_up_148x58.png",pressed = "yellow_btn_down_148x58.png"}
                    })

                else
                    self:CallFuncMarch_Callback(dragonType,soldiers)
                end
            end

        end):align(display.RIGHT_CENTER,bottom_bg:getContentSize().width-30,bottom_bg:getContentSize().height/2):addTo(bottom_bg)
    self.march_btn = march_btn
    if not self.isPVE and not self.isMilitary then
        --行军所需时间
        self.march_time = UIKit:ttfLabel({
            text = "00:00:00",
            size = 18,
            color = 0xffedae
        }):align(display.RIGHT_CENTER,march_btn:getPositionX() - march_btn:getCascadeBoundingBox().size.width - 10,50):addTo(bottom_bg)

        -- 科技减少行军时间
        self.buff_reduce_time = UIKit:ttfLabel({
            text = "-(00:00:00)",
            size = 18,
            color = 0x7eff00
        }):align(display.RIGHT_CENTER,march_btn:getPositionX() - march_btn:getCascadeBoundingBox().size.width - 10,30):addTo(bottom_bg)
        display.newSprite("hourglass_30x38.png", self.buff_reduce_time:getPositionX() - self.buff_reduce_time:getContentSize().width - 20, bottom_bg:getContentSize().height/2)
            :addTo(bottom_bg):scale(0.8)
    end
end
function GameUISendTroopNew:SetMaxSoldier()
    local isMax = self.isMax
    if isMax then
        self:ResetSoldierNode()
        self:RefreshSoldierNodes()
    else
        local sort_soldiers = self:GetSortSoldierMax()
        for i,soldier_node in ipairs(self.soldier_node_table) do
            if sort_soldiers[i] then
                soldier_node:SetSoldier(sort_soldiers[i].name,sort_soldiers[i].count):SetStatus(2)
            end
        end
        self:RefreshSoldierNodes()
    end
    self.isMax = not isMax
    self.max_btn:setButtonLabel(UIKit:ttfLabel({
        text = self.isMax and _("最小") or _("最大"),
        size = 24,
        color = 0xffedae,
        shadow= true
    }))
    self:CheckRate()
end
-- 根据一格最大带兵量获取按战斗力排序的士兵列表
function GameUISendTroopNew:GetSortSoldierMax()
    local max_citizen = self:GetUnitMaxCitizen()
    local sort_soldiers = {}
    local own_soldiers = {}
    for i, soldier_type in ipairs({
        "swordsman_1", "ranger_1", "lancer_1", "catapult_1",
        "sentinel_1", "crossbowman_1", "horseArcher_1", "ballista_1",
        "swordsman_2", "ranger_2", "lancer_2", "catapult_2",
        "sentinel_2", "crossbowman_2", "horseArcher_2", "ballista_2",
        "swordsman_3", "ranger_3", "lancer_3", "catapult_3",
        "sentinel_3", "crossbowman_3", "horseArcher_3", "ballista_3",
        "skeletonWarrior", "skeletonArcher", "deathKnight", "meatWagon"
    }) do
        local config = UtilsForSoldier:GetSoldierConfig(User,soldier_type)
        local soldier_count = User.soldiers[soldier_type]
        if self.isMilitary and User.defenceTroop and User.defenceTroop ~= json.null then
            for i,v in ipairs(User.defenceTroop.soldiers) do
                if v.name == soldier_type then
                    soldier_count = soldier_count + v.count
                end
            end
        end
        if soldier_count > 0 then
            table.insert(own_soldiers, {name = soldier_type,count = soldier_count})
        end
    end
    while #sort_soldiers < 6 and #own_soldiers > 0 do
        -- 按兵钟总战斗力排序
        table.sort( own_soldiers, function ( a,b )
            local a_config = UtilsForSoldier:GetSoldierConfig(User,a.name)
            local b_config = UtilsForSoldier:GetSoldierConfig(User,b.name)
            local a_curren_max_citizen = a_config.citizen * a.count
            local b_curren_max_citizen = b_config.citizen * b.count
            local a_max_soldier = a_curren_max_citizen > max_citizen and math.floor(max_citizen/a_config.citizen) or a.count
            local b_max_soldier = b_curren_max_citizen > max_citizen and math.floor(max_citizen/b_config.citizen) or b.count
            local a_total_power = a_max_soldier * a_config.power
            local b_total_power = b_max_soldier * b_config.power
            if a_total_power > b_total_power then
                return true
            elseif a_total_power == b_total_power then
                return a_config.power > b_config.power
            else
                return false
            end
        end )
        for i,soldier in ipairs(own_soldiers) do
            local config = UtilsForSoldier:GetSoldierConfig(User,soldier.name)
            local soldier_unit_citizen = config.citizen
            local curren_max_citizen = soldier_unit_citizen * soldier.count
            local max_soldier = curren_max_citizen > max_citizen and math.floor(max_citizen/soldier_unit_citizen) or soldier.count
            table.insert(sort_soldiers, {name = soldier.name,count = max_soldier,power = max_soldier * config.power})
            own_soldiers[i].count = soldier.count - max_soldier
            if own_soldiers[i].count == 0 then
                table.remove(own_soldiers,i)
            end
            break
        end
    end
    return sort_soldiers
end
function GameUISendTroopNew:CallFuncMarch_Callback(dragonType,soldiers)
    if not self.returnCloseAction then
        self.march_callback(dragonType,soldiers,self.total_march_time)
        self:LeftButtonClicked()
    else
        self.march_callback(dragonType,soldiers,self.total_march_time,self)
    end
end



-- fte
local promise = import("..utils.promise")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUISendTroopNew:PromiseOfFte()
    return self:PromiseOfAttack()
end
function GameUISendTroopNew:PromiseOfMax()
    local r = self.max_btn:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.max_btn)

    WidgetFteArrow.new(_("点击最大")):addTo(self:GetFteLayer()):TurnLeft()
        :align(display.LEFT_CENTER, r.x + r.width, r.y + r.height/2)

    local p = promise.new()
    self.max_btn:onButtonClicked(function()
        self:GetFteLayer():removeFromParent()
        p:resolve()
    end)
    return p
end
function GameUISendTroopNew:PromiseOfAttack()
    local r = self.march_btn:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.march_btn)

    local r = self.march_btn:getCascadeBoundingBox()
    self:GetFteLayer():SetTouchObject(self.march_btn)
    WidgetFteArrow.new(_("点击按钮：驻防")):addTo(self:GetFteLayer())
    :TurnRight():align(display.RIGHT_CENTER, r.x - 10, r.y + r.height/2)
end
function GameUISendTroopNew:CheckRate()
    if not self.params.needTips then return end
    local showTips = false
    local _,_,citizen = self:GetTotalSoldierInfo()
    local rate = citizen / UtilsForDragon:GetLeadershipByCitizen(User,self.dragon.type)
    if self.__rate then
        if math.abs(self.__rate - rate) <= 0.1 and rate > 0 then
            showTips = true
        end
    else
        showTips = rate > 0.5
    end
    self.__rate = rate
    if not self.march_btn:getChildByTag(111) and showTips then
        UIKit:FingerAni():addTo(self.march_btn,10,111):pos(-15,-40)
    end
end



return GameUISendTroopNew
















