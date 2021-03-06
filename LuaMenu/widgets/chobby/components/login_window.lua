LoginWindow = LCS.class{}

--TODO: make this a util function, maybe even add this support to chili as a whole?
function createTabGroup(ctrls)
	for i = 1, #ctrls do
		local ctrl1 = ctrls[i]
		local ctrl2 = ctrls[i + 1]
		if ctrl2 == nil then
			ctrl2 = ctrls[1]
		end

		if ctrl1.OnKeyPress == nil then
			ctrl1.OnKeyPress = {}
		end

		table.insert(ctrl1.OnKeyPress,
			function(obj, key, mods, ...)
				if key == Spring.GetKeyCode("tab") then
					screen0:FocusControl(ctrl2)
					if ctrl2.classname == "editbox" then
-- 						ctrl2:Select(1, #ctrl2.text + 1)
						-- HACK
						ctrl2.selStart = 1
						ctrl2.selStartPhysical = 1
						ctrl2.selEnd = #ctrl2.text + 1
						ctrl2.selEndPhysical = #ctrl2.text + 1
					end
				end
			end
		)
	end
end

local function GetLobbyName()
	return 'Chobby'
end

function LoginWindow:init(failFunction, cancelText, windowClassname)

	if WG.Chobby.lobbyInterfaceHolder:GetChildByName("loginWindow") then
		Log.Error("Tried to spawn duplicate login window")
		return
	end
	
	self.CancelFunc = function ()
		self.window:Dispose()
		if failFunction then
			failFunction()
		end
		self.window = nil
	end
	
	self.lblLoginInstructions = Label:New {
		x = 15,
		width = 170,
		y = 14,
		height = 35,
		caption = i18n("login_long"),
		font = Configuration:GetFont(3),
	}
	
	self.lblRegisterInstructions = Label:New {
		x = 15,
		width = 170,
		y = 14,
		height = 35,
		caption = i18n("register_long"),
		font = Configuration:GetFont(3),
	}
	
	self.txtUsername = TextBox:New {
		x = 15,
		width = 170,
		y = 60,
		height = 35,
		text = i18n("username") .. ":",
		fontsize = Configuration:GetFont(3).size,
	}
	self.ebUsername = EditBox:New {
		x = 135,
		width = 200,
		y = 51,
		height = 35,
		text = Configuration.userName or Configuration.suggestedNameFromSteam or "",
		font = Configuration:GetFont(3),
	}

	self.txtPassword = TextBox:New {
		x = 15,
		width = 170,
		y = 100,
		height = 35,
		text = i18n("password") .. ":",
		fontsize = Configuration:GetFont(3).size,
	}
	self.ebPassword = EditBox:New {
		x = 135,
		width = 200,
		y = 91,
		height = 35,
		text = Configuration.password or "",
		passwordInput = true,
		font = Configuration:GetFont(3),
		OnKeyPress = {
			function(obj, key, mods, ...)
				if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
					if self.tabPanel.tabBar:IsSelected("login") then
						self:tryLogin()
					else
						self:tryRegister()
					end
				end
			end
		},
	}
	
	self.cbAutoLogin = Checkbox:New {
		x = 15,
		width = 215,
		y = 135,
		height = 35,
		boxalign = "right",
		boxsize = 15,
		caption = i18n("autoLogin"),
		checked = Configuration.autoLogin,
		font = Configuration:GetFont(2),
		OnClick = {function (obj)
			Configuration:SetConfigValue("autoLogin", obj.checked)
		end},
	}
	
	self.txtError = TextBox:New {
		x = 15,
		right = 15,
		y = 198,
		height = 90,
		text = "",
		fontsize = Configuration:GetFont(3).size,
	}
	
	self.btnLogin = Button:New {
		right = 140,
		width = 130,
		y = 237,
		height = 70,
		caption = i18n("login_verb"),
		font = Configuration:GetFont(3),
		classname = "action_button",
		OnClick = {
			function()
				self:tryLogin()
			end
		},
	}

	self.btnRegister = Button:New {
		right = 140,
		width = 130,
		y = 237,
		height = 70,
		caption = i18n("register_verb"),
		font = Configuration:GetFont(3),
		classname = "option_button",
		OnClick = {
			function()
				self:tryRegister()
			end
		},
	}

	self.btnCancel = Button:New {
		right = 2,
		width = 130,
		y = 237,
		height = 70,
		caption = i18n(cancelText or "cancel"),
		font = Configuration:GetFont(3),
		classname = "negative_button",
		OnClick = {
			function()
				self.CancelFunc()
			end
		},
	}
	
	local ww, wh = Spring.GetWindowGeometry()
	local w, h = 430, 380
	if self.steamMode then
	
	end

	self.tabPanel = Chili.DetachableTabPanel:New {
		x = 0,
		right = 0,
		y = 0,
		minTabWidth = w/2 - 20,
		bottom = 0,
		padding = {0, 0, 0, 0},
		tabs = {
			[1] = { name = "login", caption = i18n("login"), children = {self.btnLogin, self.lblLoginInstructions}, font = Configuration:GetFont(2)},
			[2] = { name = "register", caption = i18n("register_verb"), children = {self.btnRegister, self.lblRegisterInstructions}, font = Configuration:GetFont(2)},
		},
	}
	
	self.tabBarHolder = Control:New {
		name = "tabBarHolder",
		x = 9,
		y = 0,
		right = 0,
		height = 30,
		resizable = false,
		draggable = false,
		padding = {0, 2, 0, 0},
		children = {
			self.tabPanel.tabBar
		}
	}
	
	-- Prompt user to register account if their account has not been registered.
	if Configuration.firstLoginEver then
		self.tabPanel.tabBar:Select("register")
	end
	
	self.contentsPanel = ScrollPanel:New {
		x = 5,
		right = 5,
		y = 30,
		bottom = 4,
		horizontalScrollbar = false,
		children = {
			self.tabPanel,
			self.txtUsername,
			self.txtPassword,
			self.ebUsername,
			self.ebPassword,
			self.txtError,
			self.cbAutoLogin,
			self.btnCancel
		}
	}
	
	self.window = Window:New {
		x = math.floor((ww - w) / 2),
		y = math.floor((wh - h) / 2),
		width = w,
		height = h,
		caption = "",
		resizable = false,
		draggable = false,
		classname = windowClassname,
		children = {
			self.tabBarHolder,
			self.contentsPanel,
		},
		parent = WG.Chobby.lobbyInterfaceHolder,
		OnDispose = {
			function()
				self:RemoveListeners()
			end
		},
		OnFocusUpdate = {
			function(obj)
				obj:BringToFront()
			end
		}
	}
	
	self.window:BringToFront()
	
	createTabGroup({self.ebUsername, self.ebPassword})
	screen0:FocusControl(self.ebUsername)
	-- FIXME: this should probably be moved to the lobby wrapper
	self.loginAttempts = 0
end

function LoginWindow:RemoveListeners()
	if self.onAgreementEnd then
		lobby:RemoveListener("OnAgreementEnd", self.onAgreementEnd)
		self.onAgreementEnd = nil
	end
	if self.onAgreement then
		lobby:RemoveListener("OnAgreement", self.onAgreement)
		self.onAgreement = nil
	end
	if self.onConnect then
		lobby:RemoveListener("OnConnect", self.onConnect)
		self.onConnect = nil
	end
	if self.onDisconnected then
		lobby:RemoveListener("OnDisconnected", self.onDisconnected)
		self.onDisconnected = nil
	end
end

function LoginWindow:tryLogin()
	self.txtError:SetText("")

	local username = self.ebUsername.text
	local password = (self.ebPassword.visible and self.ebPassword.text) or nil
	if username == '' then
		return
	end
	Configuration.userName = username
	Configuration.password = password

	if not lobby.connected or self.loginAttempts >= 3 then
		self.loginAttempts = 0
		self:RemoveListeners()

		self.onConnect = function(listener)
			lobby:RemoveListener("OnConnect", self.onConnect)
			self:OnConnected(listener)
		end
		lobby:AddListener("OnConnect", self.onConnect)

		self.onDisconnected = function(listener)
			lobby:RemoveListener("OnDisconnected", self.onDisconnected)
			self.txtError:SetText(Configuration:GetErrorColor() .. "Cannot reach server:\n" .. tostring(Configuration:GetServerAddress()) .. ":" .. tostring(Configuration:GetServerPort()))
		end
		lobby:AddListener("OnDisconnected", self.onDisconnected)

		lobby:Connect(Configuration:GetServerAddress(), Configuration:GetServerPort(), username, password, 3, nil, GetLobbyName())
	else
		lobby:Login(username, password, 3, nil, GetLobbyName())
	end

	self.loginAttempts = self.loginAttempts + 1
end

function LoginWindow:tryRegister()
	WG.Analytics.SendOnetimeEvent("lobby:try_register")
	self.txtError:SetText("")

	local username = self.ebUsername.text
	local password = (self.ebPassword.visible and self.ebPassword.text) or nil
	if username == '' then
		return
	end

	if not lobby.connected or self.loginAttempts >= 3 then
		self.loginAttempts = 0
		self:RemoveListeners()

		self.onConnectRegister = function(listener)
			lobby:RemoveListener("OnConnect", self.onConnectRegister)
			self:OnConnected(listener)
		end
		WG.LoginWindowHandler.QueueRegister(username, password)
		lobby:AddListener("OnConnect", self.onConnectRegister)

		lobby:Connect(Configuration:GetServerAddress(), Configuration:GetServerPort(), username, password, 3, nil, GetLobbyName())
	else
		lobby:Register(username, password, "name@email.com")
		lobby:Login(username, password, 3, nil, GetLobbyName())
	end

	self.loginAttempts = self.loginAttempts + 1
end

function LoginWindow:OnConnected()
	Spring.Echo("OnConnected")
	--self.txtError:SetText(Configuration:GetPartialColor() .. i18n("connecting"))

	self.onAgreement = function(listener, line)
		if self.agreementText == nil then
			self.agreementText = ""
		end
		self.agreementText = self.agreementText .. line .. "\n"
	end
	lobby:AddListener("OnAgreement", self.onAgreement)

	self.onAgreementEnd = function(listener)
		self:createAgreementWindow()
		lobby:RemoveListener("OnAgreementEnd", self.onAgreementEnd)
		lobby:RemoveListener("OnAgreement", self.onAgreement)
	end
	lobby:AddListener("OnAgreementEnd", self.onAgreementEnd)
end

function LoginWindow:createAgreementWindow()
	self.tbAgreement = TextBox:New {
		x = 1,
		right = 1,
		y = 1,
		height = "100%",
		text = self.agreementText,
		font = Configuration:GetFont(3),
	}
	self.btnYes = Button:New {
		x = 1,
		width = 135,
		bottom = 1,
		height = 70,
		caption = "Accept",
		font = Configuration:GetFont(3),
		OnClick = {
			function()
				self:acceptAgreement()
			end
		},
	}
	self.btnNo = Button:New {
		x = 240,
		width = 135,
		bottom = 1,
		height = 70,
		caption = "Decline",
		font = Configuration:GetFont(3),
		OnClick = {
			function()
				self:declineAgreement()
			end
		},
	}
	self.agreementWindow = Window:New {
		x = 600,
		y = 200,
		width = 350,
		height = 450,
		caption = "Use agreement",
		resizable = false,
		draggable = false,
		children = {
			ScrollPanel:New {
				x = 1,
				right = 7,
				y = 1,
				bottom = 42,
				children = {
					self.tbAgreement
				},
			},
			self.btnYes,
			self.btnNo,

		},
		parent = WG.Chobby.lobbyInterfaceHolder,
	}
end

function LoginWindow:acceptAgreement()
	lobby:ConfirmAgreement()
	self.agreementWindow:Dispose()
end

function LoginWindow:declineAgreement()
	lobby:Disconnect()
	self.agreementWindow:Dispose()
end
