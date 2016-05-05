local cocos_promise = import("..utils.cocos_promise")
local Localize = import("..utils.Localize")
local promise = import("..utils.promise")
local GameUIWatchTowerTroopDetail = import("..ui.GameUIWatchTowerTroopDetail")
local WidgetMoveHouse = import("..widget.WidgetMoveHouse")
local TutorialLayer = import("..ui.TutorialLayer")
local GameUINpc = import("..ui.GameUINpc")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
local WidgetFteMark = import("..widget.WidgetFteMark")
local Sprite = import("..sprites.Sprite")
local NotifyItem = import("..utils.NotifyItem")
local CityScene = import(".CityScene")
local MyCityScene = class("MyCityScene", CityScene)
local GameUIActivityRewardNew = import("..ui.GameUIActivityRewardNew")
local ipairs = ipairs

function MyCityScene:ctor(city,isFromLogin,operetion,callback)
    self.util_node = display.newNode():addTo(self)
    MyCityScene.super.ctor(self,city)
    if type(isFromLogin) == 'boolean' then
        self.isFromLogin = isFromLogin
    else
        self.isFromLogin = false
    end
    self.operetion = operetion
    self.callback = callback
end
function MyCityScene:onEnter()
    MyCityScene.super.onEnter(self)
    self.home_page = self:CreateHomePage()

    local alliance = Alliance_Manager:GetMyAlliance()
    self.firstJoinAllianceRewardGeted = DataManager:getUserData().countInfo.firstJoinAllianceRewardGeted
    if not UIKit:GetUIInstance('GameUIWarSummary') and alliance:LastAllianceFightReport() then
        UIKit:newGameUI("GameUIWarSummary"):AddToCurrentScene(true)
    end
    -- cc.ui.UIPushButton.new({normal = "lock_btn.png",pressed = "lock_btn.png"})
    -- :addTo(self, 1000000):align(display.RIGHT_TOP, display.width, display.height)
    -- :onButtonClicked(function(event)
    --     event.target:setButtonEnabled(false)
    --     app:ReloadGame()
    -- end):setOpacity(0)
    -- UIKit:ttfLabel({
    --     text = _("reload"),
    --     size = 30,
    --     color = 0xffedae,
    --     align = cc.TEXT_ALIGNMENT_CENTER,
    -- }):addTo(self, 1000000)
    -- :align(display.RIGHT_TOP, display.width, display.height)

    -- alliance:AddListenOnType(self, "operation")
    self:GetCity():GetUser():AddListenOnType(self, "soldierEvents")
    self:GetCity():GetUser():AddListenOnType(self, "houseEvents")
    self:GetCity():GetUser():AddListenOnType(self, "buildingEvents")

    if self.operetion == "twinkle_military" then
        self:GotoLogicPointInstant(22, 50)
        self:GetSceneLayer():ZoomTo(0.68)
        for i=17,20 do
            local tile = self.city:GetTileByLocationId(i)
            local b_x,b_y =tile.x,tile.y
            -- 建筑是否已解锁
            if self.city:IsUnLockedAtIndex(b_x,b_y) then
                local buildings = self:GetSceneLayer():GetBuildings(i)
                Sprite:PromiseOfFlash(unpack(buildings)):next(function()
                    Sprite:PromiseOfFlash(unpack(buildings)):next(function()
                        Sprite:PromiseOfFlash(unpack(buildings))
                    end)
                end)
            end
        end
    end
    -- showMemoryUsage()
end
function MyCityScene:onExit()
    self.home_page = nil
    MyCityScene.super.onExit(self)
end
function MyCityScene:EnterEditMode()
    self:GetTopLayer():hide()
    self:GetHomePage():DisplayOff()
    local label = UIKit:ttfLabel(
        {
            text = _("选择一个空地,将小屋移动到这里"),
            size = 22,
            color = 0xffedae,
        })
    self.move_house_tip = display.newScale9Sprite("fte_label_background.png",display.cx,display.top-100,cc.size(label:getContentSize().width+60,label:getContentSize().height+20),cc.rect(20,20,330,28))
        :addTo(self)
    label:align(display.CENTER, self.move_house_tip:getContentSize().width/2, self.move_house_tip:getContentSize().height/2):addTo(self.move_house_tip)
    MyCityScene.super.EnterEditMode(self)
end
function MyCityScene:LeaveEditMode()
    self:GetTopLayer():show()
    self:GetHomePage():DisplayOn()
    self.move_house_tip:removeFromParent(true)
    MyCityScene.super.LeaveEditMode(self)
    self:GetSceneUILayer():removeChildByTag(WidgetMoveHouse.ADD_TAG, true)
end
function MyCityScene:CreateSceneUILayer()
    local scene_node = self
    local city = self.city
    local scene_layer = self:GetSceneLayer()
    local scene_ui_layer = display.newLayer()
    scene_ui_layer:setTouchEnabled(true)
    scene_ui_layer:setTouchSwallowEnabled(false)
    scene_ui_layer.action_node = display.newNode():addTo(scene_ui_layer)
    -- function scene_ui_layer:ShowIndicatorOnBuilding(building_sprite)
    --     if not self.indicator then
    --         self.building__ = building_sprite
    --         self.indicator = display.newNode():addTo(self):zorder(1001)
    --         local r = 30
    --         local len = 50
    --         local x = math.sin(math.rad(r)) * len
    --         local y = math.sin(math.rad(90 - r)) * len
    --         display.newSprite("arrow_home.png")
    --             :addTo(self.indicator)
    --             :align(display.BOTTOM_CENTER, 10, 10)
    --             :rotation(r)
    --             :runAction(cc.RepeatForever:create(transition.sequence{
    --                 cc.MoveBy:create(0.4, cc.p(-x, -y)),
    --                 cc.MoveBy:create(0.4, cc.p(x, y)),
    --             }))
    --         self.action_node:stopAllActions()
    --         self.action_node:performWithDelay(function()
    --             self:HideIndicator()
    --         end, 4.0)
    --     end
    -- end
    -- function scene_ui_layer:HideIndicator()
    --     if self.indicator then
    --         self.action_node:stopAllActions()
    --         self.indicator:removeFromParent()
    --         self.indicator = nil
    --     end
    -- end
    function scene_ui_layer:Schedule()
        display.newNode():addTo(self):schedule(function()
            scene_node:RefreshLockBtnStatus()
            scene_node:RefreshStrenth()
        end, 1)
        display.newNode():addTo(self):schedule(function()
            -- 检查缩放比
            if scene_layer:getScale() < (scene_layer:GetScaleRange()) * 1.3 then
                if self.is_show == nil or self.is_show == true then
                    scene_layer:HideLevelUpNode()
                    -- scene_node:GetTopLayer():stopAllActions()
                    -- transition.fadeOut(scene_node:GetTopLayer(), {
                    --     time = 0.5,
                    --     onComplete = function()
                    --         scene_node:GetTopLayer():hide()
                    --     end,
                    -- })
                    self.is_show = false
                end
            else
                if self.is_show == nil or self.is_show == false then
                    scene_layer:ShowLevelUpNode()
                    -- scene_node:GetTopLayer():stopAllActions()
                    -- scene_node:GetTopLayer():show()
                    -- transition.fadeIn(scene_node:GetTopLayer(), {
                    --     time = 0.5,
                    -- })
                    self.is_show = true
                end
            end
        end, 0.5)
        display.newNode():addTo(self):schedule(function()
            -- local building = self.building__
            -- if self.indicator and building then
            --     local wp = building:convertToWorldSpace(cc.p(building:GetSpriteTopPosition()))
            --     local lp = self.indicator:getParent():convertToNodeSpace(wp)
            --     self.indicator:pos(lp.x, lp.y)
            -- end
            local widget = self:getChildByTag(WidgetMoveHouse.ADD_TAG)
            if widget and widget.move_to_ruins then
                local wp = widget.move_to_ruins:GetWorldPosition()
                widget:pos(wp.x, wp.y)
                widget.building_image:scale(scene_layer:getScale())
            end
        end, 0.0001)
    end
    scene_ui_layer:Schedule()
    return scene_ui_layer
end
function MyCityScene:NewLockButtonFromBuildingSprite(building_sprite)
    local wp = building_sprite:GetWorldPosition()
    local lp = self:GetTopLayer():convertToNodeSpace(wp)
    local btn_png = "tmp_lock_btn.png"
    if UtilsForBuilding:GetFreeUnlockPoint(self.city:GetUser()) > 0 then
        btn_png = "tmp_unlock_btn.png"
    end
    local button = cc.ui.UIPushButton.new({normal = btn_png, pressed = btn_png})
        :addTo(self:GetTopLayer()):pos(lp.x,lp.y)
        :onButtonClicked(function()
            UIKit:newGameUI("GameUIUnlockBuilding", self.city, building_sprite:GetEntity()):AddToCurrentScene(true)
        end):onButtonPressed(function(event)
        event.target:runAction(cc.ScaleTo:create(0.1, 1.2))
        end):onButtonRelease(function(event)
        event.target:runAction(cc.ScaleTo:create(0.1, 1))
        end)

    button.sprite = building_sprite
    return button
end
function MyCityScene:RefreshLockBtnStatus()
    local btn_png = "tmp_lock_btn.png"
    if UtilsForBuilding:GetFreeUnlockPoint(self.city:GetUser()) > 0 then
        btn_png = "tmp_unlock_btn.png"
    end
    self:IteratorLockButtons(function(btn)
        btn:setButtonImage(cc.ui.UIPushButton.NORMAL, btn_png, true)
        btn:setButtonImage(cc.ui.UIPushButton.PRESSED, btn_png, true)
    end)
end
function MyCityScene:IteratorLockButtons(func)
    for i,v in ipairs(self:GetTopLayer():getChildren()) do
        if func(v) then
            return
        end
    end
end
-- 给对应建筑添加指示动画
function MyCityScene:AddIndicateForBuilding(building_sprite, build_name)
    Sprite:PromiseOfFlash(unpack(self:CollectBuildings(building_sprite))):next(function()
        self:OpenUI(building_sprite, "upgrade", true, build_name)
    end)
end
function MyCityScene:GetHomePage()
    return self.home_page
end
-- function MyCityScene:OnAllianceDataChanged_operation(alliance, op)
--     -- if op == "join" and
--     --     Alliance_Manager:HasBeenJoinedAlliance() and
--     --     not self.firstJoinAllianceRewardGeted
--     -- then
--     --     -- self:GetHomePage():PromiseOfFteAllianceMap()
--     -- end
-- end
function MyCityScene:onEnterTransitionFinish()
    MyCityScene.super.onEnterTransitionFinish(self)
    if ext.registereForRemoteNotifications then
        display.newNode():addTo(self):performWithDelay(function()
            ext.registereForRemoteNotifications()
        end, 1.5)
    end
    app:sendPlayerLanguageCodeIf()
    app:sendApnIdIf()
    if self.isFromLogin then

        local isFinished_fte = DataManager:getUserData().countInfo.isFTEFinished
        local not_buy_any_gems = DataManager:getUserData().countInfo.iapCount == 0
        if isFinished_fte and not_buy_any_gems then
            UIKit:newGameUI("GameUIActivityRewardNew",GameUIActivityRewardNew.REWARD_TYPE.FIRST_IN_PURGURE):AddToScene(self, true)
        end
        --开启屏幕锁定定时器(前面已经关闭)
        -- if ext.disableIdleTimer then
        --     ext.disableIdleTimer(false)
        -- end
        -- gamecenter 初始化
        if ext.gamecenter.isGameCenterEnabled() and not ext.gamecenter.isAuthenticated() then
            ext.gamecenter.authenticate(false)
        end
        -- facebook 初始化
        if ext.facebook then
            ext.facebook.initialize()
        end

    end
    app:GetChatManager():FetMessageFirstStartGame()
    self:RunFteIfNeeded()

    if type(self.callback) == "function" then
        self:callback()
    end
end
function MyCityScene:CreateHomePage()
    if UIKit:GetUIInstance("GameUIHome") then
        UIKit:GetUIInstance("GameUIHome"):removeFromParent()
    end
    local home = UIKit:newGameUI('GameUIHome', self:GetCity()):AddToScene(self)
    home:setLocalZOrder(10)
    home:setTouchSwallowEnabled(false)
    return home
end
function MyCityScene:GetLockButtonsByBuildingType(building_type)
    local lock_button
    local location_id = self:GetCity():GetLocationIdByBuildingType(building_type)
    self:IteratorLockButtons(function(v)
        if v.sprite:GetEntity().location_id == location_id then
            lock_button = v
            return true
        end
    end)
    assert(lock_button, building_type)
    return lock_button
end
function MyCityScene:OnUserDataChanged_houseEvents(userData, deltaData)
    if deltaData("houseEvents.add") then
        self:GetSceneLayer():CheckCanUpgrade()
    end
    if deltaData("houseEvents.remove") then
        self:GetSceneLayer():CheckCanUpgrade()
    end
end
function MyCityScene:OnUserDataChanged_buildingEvents(userData, deltaData)
    if deltaData("buildingEvents.add") then
        self:GetSceneLayer():CheckCanUpgrade()
    end
    local ok, value = deltaData("buildingEvents.remove")
    if ok then
        for i,v in ipairs(value) do
            if v.location == 21 then
                self:GetSceneLayer():UpdateWallsWithCity(self:GetCity())
            end
        end
        self:GetSceneLayer():CheckCanUpgrade()
    end
end
function MyCityScene:OnUserDataChanged_soldierEvents(userData, deltaData)
    if deltaData("soldierEvents.add") then
        self:GetHomePage():OnUserDataChanged_growUpTasks()
    end
    local ok, value = deltaData("soldierEvents.remove")
    if ok then
        local event = value[1]
        self:GetHomePage():OnUserDataChanged_growUpTasks()
        self:GetSceneLayer():MoveBarracksSoldiers(event.name)
    end
end
function MyCityScene:OnUserDataChanged_basicInfo(userData, deltaData)
    MyCityScene.super.OnUserDataChanged_basicInfo(self, userData, deltaData)
    if deltaData("basicInfo.terrain") then
        self:ChangeTerrain(userData.basicInfo.terrain)
    end
    if deltaData("basicInfo.power") then
        self:GetHomePage():ShowPowerAni(cc.p(display.cx, display.cy), userData.basicInfo.power)
    end
end
function MyCityScene:OnTilesChanged(tiles)
    self:GetTopLayer():removeAllChildren()
    local city = self:GetCity()
    table.foreach(tiles, function(_, tile)
        local tile_entity = tile:GetEntity()
        if (city:IsTileCanbeUnlockAt(tile_entity.x, tile_entity.y)) then
            local building = city:GetBuildingByLocationId(tile_entity.location_id)
            if building and not building:IsUpgrading() then
                self:NewLockButtonFromBuildingSprite(tile)
            end
        end
    end)
end
function MyCityScene:OnTouchClicked(pre_x, pre_y, x, y)
    if self.event_manager:TouchCounts() ~= 0 or
        self.util_node:getNumberOfRunningActions() > 0 then return end

    local building = self:GetSceneLayer():GetClickedObject(x, y)
    if building then
        app:lockInput(true);self.util_node:performWithDelay(function()app:lockInput()end,0.3)
        Sprite:PromiseOfFlash(unpack(self:CollectBuildings(building))):next(function()
            if self:IsEditMode() then
                self:GetSceneUILayer():getChildByTag(WidgetMoveHouse.ADD_TAG):SetMoveToRuins(building)
                return
            end
            self:CheckClickPromise(building, function()
                self:OpenUI(building)
            end)
        end)
    elseif self:IsEditMode() then
        self:LeaveEditMode()
    end
end
local ui_map = setmetatable({
    ruins          = {"GameUIBuild"               ,                           },
    keep           = {"GameUIKeep"                ,        "upgrade",         },
    warehouse      = {"GameUIWarehouse"           ,        "upgrade",         },
    dragonEyrie    = {"GameUIDragonEyrieMain"     ,         "dragon",         },
    barracks       = {"GameUIBarracks"            ,        "recruit",         },
    hospital       = {"GameUIHospital"            ,           "heal",         },
    academy        = {"GameUIAcademy"             ,     "technology",         },
    materialDepot  = {"GameUIMaterialDepot"       ,           "info",         },
    blackSmith     = {"GameUIBlackSmith"          ,},
    foundry        = {"GameUIPResourceBuilding"   ,},
    stoneMason     = {"GameUIPResourceBuilding"   ,},
    lumbermill     = {"GameUIPResourceBuilding"   ,},
    mill           = {"GameUIPResourceBuilding"   ,},
    tradeGuild     = {"GameUITradeGuild"          ,            "buy",         },
    townHall       = {"GameUITownHall"            , "administration",         },
    toolShop       = {"GameUIToolShop"            ,    "manufacture",         },
    trainingGround = {"GameUIMilitaryTechBuilding",           "tech",         },
    hunterHall     = {"GameUIMilitaryTechBuilding",           "tech",         },
    stable         = {"GameUIMilitaryTechBuilding",           "tech",         },
    workshop       = {"GameUIMilitaryTechBuilding",           "tech",         },
    dwelling       = {"GameUIDwelling"            ,        "upgrade",         },
    farmer         = {"GameUIResource"            ,},
    woodcutter     = {"GameUIResource"            ,},
    quarrier       = {"GameUIResource"            ,},
    miner          = {"GameUIResource"            ,},
    wall           = {"GameUIWall"                ,       "upgrade",          },
    tower          = {"GameUITower"               ,},
    watchTower     = {"GameUIWatchTower"          ,         "march",          },
    airship        = {},
    FairGround     = {},
    square         = {},
}, {__index = function() assert(false) end})
function MyCityScene:OpenUI(building, default_tab, need_tips, build_name)
    local city = self:GetCity()
    local User = city:GetUser()
    if iskindof(building, "HelpedTroopsSprite") then
        local helped = User.helpedByTroop
        local user = self.city:GetUser()
        NetManager:getHelpDefenceTroopDetailPromise(user:Id()):done(function(response)
            UIKit:newGameUI("GameUIHelpDefence",self.city, helped ,response.msg.troopDetail):AddToCurrentScene(true)
        end)
        return
    end
    local entity = building:GetEntity()
    if entity:GetType() == "wall" then
        entity = city:GetGate()
    elseif entity:GetType() == "tower" then
        entity = city:GetTower()
    end
    local type_ = entity:GetType()
    local uiarrays = ui_map[type_]
    if type_ == "ruins" and not self:IsEditMode() then
        UIKit:newGameUI(uiarrays[1], city, entity, uiarrays[2], uiarrays[3], need_tips, build_name):AddToScene(self, true)
    elseif type_ == "airship" then
        local dragon_manger = city:GetDragonEyrie():GetDragonManager()
        local dragon_type = dragon_manger:GetCanFightPowerfulDragonType()
        if #dragon_type > 0 or UtilsForDragon:GetDefenceDragon(User) then
            app:EnterPVEScene(city:GetUser():GetLatestPveIndex(), need_tips)
        else
            UIKit:showMessageDialog(_("主人"),_("需要一条空闲状态的魔龙才能探险"))
        end
        app:GetAudioManager():PlayeEffectSoundWithKey("AIRSHIP")
    elseif type_ == "FairGround" then
        UIKit:newGameUI("GameUIGacha", self.city):AddToScene(self, true)
    elseif type_ == "square" then
        UIKit:newGameUI("GameUISquare", self.city):AddToScene(self, true)
    elseif type_ == "watchTower" then
        UIKit:newGameUI(uiarrays[1], city, uiarrays[2]):AddToScene(self, true)
    else
        if entity:IsUnlocked() then
            local ui = UIKit:newGameUI(uiarrays[1], city, entity, default_tab or uiarrays[2], uiarrays[3]):AddToScene(self, true)
            if need_tips then
                ui.needTips = UtilsForTask:NeedTips(self:GetCity():GetUser())
            end
        else
            local ui = UIKit:newGameUI("GameUIUnlockBuilding", city, city:GetTileWhichBuildingBelongs(entity), need_tips):AddToScene(self, true)
        end
    end
end



-- fte

function MyCityScene:RunFteIfNeeded()
    local p = cocos_promise.defer()
    if (not UtilsForFte:IsHatedAnyDragon(self:GetCity():GetUser())
    or not UtilsForFte:IsStudyAnyDragonSkill(self:GetCity():GetUser())
    or not UtilsForFte:IsDefencedWithTroops(self:GetCity():GetUser()))
    -- and not self:GetCity():GetUser().countInfo.isFTEFinished
     then
        p:next(function()
            return self:PromiseOfHateDragonAndDefence()
        end)
    end

    if not self:GetCity():GetUser().countInfo.isFTEFinished then
        p:next(function()
            self:FteEditName(function()
                self:FteAlliance()
            end)
        end)
    end
end
function MyCityScene:PromiseOfHateDragonAndDefence()
    return GameUINpc:PromiseOfSay(
        {words = _("我们到了。。。现在你的伤也恢复的差不多了，让我们来测试一下你觉醒者的能力吧。。。"), brow = "smile"}
    ):next(function()
        return GameUINpc:PromiseOfLeave()
    end):next(function()
        return self:PromiseOfClickBuilding(18, 8)
    end):next(function()
        return UIKit:PromiseOfOpen("GameUIDragonEyrieMain")
    end):next(function(ui)
        return ui:PromiseOfFte()
    end)
end
function MyCityScene:FteEditName(func)
    if DataManager:getUserData().countInfo.isFTEFinished then
        if type(func) == "function" then
            func()
        end
    else
        if User:GetItemCount("changePlayerName") == 0 then
            if type(func) == "function" then
                func()
            end
        else
            UIKit:newGameUI("GameUIEditName", func):AddToCurrentScene(true)
        end
    end
end
function MyCityScene:FteAlliance()
    if Alliance_Manager:GetMyAlliance():IsDefault() then
        app:lockInput(true)
        cocos_promise.defer(function()app:lockInput(false);end)
            :next(function()
                return GameUINpc:PromiseOfSay(
                    {words = string.format(_("%s 领主大人，这个世界上的觉醒者并不只有你一人。介入他们或者创建联盟邀请他们加入，会让我们发展得更顺利"), User.basicInfo.name)}
                )
            end):next(function()
                return GameUINpc:PromiseOfLeave()
            end):next(function()
                self:GetHomePage():PromiseOfFteAlliance()
            end):next(function()
                self:GetHomePage():CheckFinger()
            end)
    else
        self:GetHomePage():PromiseOfFteAlliance()
    end
end

local ARROW_TAG = 11901
function MyCityScene:PromiseOfClickBuilding(x, y, for_build, msg, arrow_param)
    self:BeginClickFte()
    self:GetSceneLayer()
        :FindBuildingBy(x, y)
        :next(function(building)
            local __,top = building:GetWorldPosition()
            local info_layer = self:GetSceneLayer():GetInfoLayer()
            local top_point = info_layer:convertToNodeSpace(top)

            local str
            if not msg then
                if building:GetEntity():GetType() == "ruins" then
                    str = string.format(_("点击空地：建造%s"), Localize.building_name[for_build])
                else
                    str = string.format(_("点击建筑：%s"), Localize.building_name[building:GetEntity():GetType()])
                end
            end

            info_layer:removeAllChildren()
            local arrow = WidgetFteArrow.new(msg or str)
                :addTo(info_layer, 1, ARROW_TAG):TurnDown():pos(top_point.x, top_point.y + 50)
            if arrow_param then
                if arrow_param.direction == "up" then
                    arrow:TurnUp()
                end
                arrow:pos(top_point.x + (arrow_param.x or 0), top_point.y + (arrow_param.y or -300))
            end


            local mx, my = building:GetEntity():GetMidLogicPosition()
            self:GotoLogicPoint(mx, my, 5)
                :next(function()
                    info_layer:removeAllChildren()

                    local __,top = building:GetWorldPosition()
                    local tp = self:GetFteLayer():convertToNodeSpace(top)
                    local arrow = WidgetFteArrow.new(msg or str)
                        :addTo(self:GetFteLayer(), 1, ARROW_TAG)
                        :TurnDown():pos(tp.x, tp.y + 50)
                    if arrow_param then
                        if arrow_param.direction == "up" then
                            arrow:TurnUp()
                        end
                        arrow:pos(tp.x + (arrow_param.x or 0), tp.y + (arrow_param.y or -300))
                    end
                    local rect = building:GetSprite():getBoundingBox()
                    local x,y,x1,y1 = rect.x,rect.y,rect.x + rect.width,rect.y + rect.height
                    if building:GetEntity():GetType() == "keep" then
                        x1 = x1 - 50
                    elseif building:GetEntity():GetType() == "barracks" then
                        x1 = x1 - 40
                    elseif building:GetEntity():GetType() == "hospital" then
                        x1 = x1 - 60
                    elseif building:GetEntity():GetType() == "academy" then
                        x1 = x1 - 20
                    elseif building:GetEntity():GetType() == "materialDepot" then
                        x1 = x1 - 20
                    elseif building:GetEntity():GetType() == "airship" then
                        y = y + 80
                        x = x - 50
                    end

                    local lp = building:GetSprite():getParent():convertToWorldSpace(cc.p(x,y))
                    local rp = building:GetSprite():getParent():convertToWorldSpace(cc.p(x1,y1))

                    self:GetFteLayer():FocusOnRect(cc.rect(lp.x, lp.y, rp.x - lp.x, rp.y - lp.y))
                end)

        end)

    local p = promise.new()
    table.insert(self.clicked_callbacks, function(building)
        local x_, y_ = building:GetEntity():GetLogicPosition()
        if x == x_ and y == y_ then
            p:resolve()
            return true
        end
    end)
    return p
end
function MyCityScene:BeginClickFte()
    self.clicked_callbacks = {}
    self:GetFteLayer():removeChildByTag(ARROW_TAG, true)
    self:GetFteLayer():FocusOnRect()
    self:GetFteLayer():Enable()
    self:GetSceneLayer():GetInfoLayer():removeAllChildren()
end
function MyCityScene:EndClickFte()
    self.clicked_callbacks = {}
    self:GetFteLayer():removeChildByTag(ARROW_TAG, true)
    self:GetFteLayer():FocusOnRect()
    self:GetFteLayer():Disable()
    self:GetSceneLayer():GetInfoLayer():removeAllChildren()
end
function MyCityScene:CheckClickPromise(building, func)
    if self.clicked_callbacks and 
        #self.clicked_callbacks > 0 then
        if self.clicked_callbacks[1](building) then
            table.remove(self.clicked_callbacks, 1)
            func()
            self:EndClickFte()
        end
    else
        func()
    end
end

return MyCityScene





