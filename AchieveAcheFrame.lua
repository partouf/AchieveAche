-- Author      : patrick
-- Create Date : 11/12/2011 3:55:28 PM

AchieveAche_Ready = false;
AchieveAche_Categories = {};
AchieveAche_CompletedAchievements = {};
AchieveAche_UncompletedAchievements = {};
AchieveAche_Labels = {};
AchieveAche_CurLabelIndex = 1;
AchieveAche_CurLabelY = 0;

CONST_VARSLOADED = "VARIABLES_LOADED";
CONST_MOUSEOVERUNIT = "UPDATE_MOUSEOVER_UNIT";

function AchieveAche_OnLoad(obj)
	obj:RegisterEvent( CONST_VARSLOADED );

	if obj.SetBackdrop then
		obj:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileEdge = true, tileSize = 32, edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		});
	end
	if ScrollFrame1 and ScrollFrame1.SetBackdrop then
		ScrollFrame1:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			tile = true, tileEdge = true, tileSize = 32, edgeSize = 0,
		});
	end

	SLASH_ACHACHE1 = "/achieveache";
	SLASH_ACHACHE2 = "/aa";
	SlashCmdList["ACHACHE"] = AchieveAche_SlashFunc;
end

function AchieveAche_SlashFunc()
	AchieveAcheFrame:Show();

	AchieveAche_LoadAchievementsFromApi();
	Button3_OnClick();
end

function AchieveAche_LoadAchievementsFromApi()
	AchieveAche_Categories = {};
	AchieveAche_CompletedAchievements = {};
	AchieveAche_UncompletedAchievements = {};

	if type(GetCategoryList) ~= "function" then
		AchieveAche_MessageSelf("AchieveAche: GetCategoryList() not available on this client.");
		return;
	end

	local list = GetCategoryList();
	if type(list) ~= "table" then
		AchieveAche_MessageSelf("AchieveAche: GetCategoryList() returned no table.");
		return;
	end

	local categoryCount = #list;
	local loadedCompleted, loadedUncompleted = 0, 0;

	for i = 1, categoryCount do
		local catid = list[i];
		local cname, parentid = GetCategoryInfo(catid);
		AchieveAche_Categories[catid] = { name = cname, parentid = parentid };

		local total = GetCategoryNumAchievements(catid);
		if total and total > 0 then
			for j = 1, total do
				local id, aname, points, completed, m, d, y, desc = GetAchievementInfo(catid, j);
				if id then
					local entry = { catid = catid, name = aname or "", desc = desc or "" };
					if completed then
						AchieveAche_CompletedAchievements[id] = entry;
						loadedCompleted = loadedCompleted + 1;
					else
						AchieveAche_UncompletedAchievements[id] = entry;
						loadedUncompleted = loadedUncompleted + 1;
					end
				end
			end
		end
	end

	AchieveAche_MessageSelf(string.format(
		"AchieveAche: %d categories, %d completed, %d uncompleted",
		categoryCount, loadedCompleted, loadedUncompleted));
end

function AchieveAche_HideAllLabels()
	SearchResults:SetWidth(450);
	SearchResults:SetHeight(22);

	c = #AchieveAche_Labels;
	for i = 1, c do
		label = AchieveAche_Labels[i];

		label:Hide();
	end

	AchieveAche_CurLabelIndex = 1;
	AchieveAche_CurLabelY = 0;
end

function AchieveAche_AddToResults( achieveid, info, bIsCompleted )
	c = #AchieveAche_Labels;

	if AchieveAche_CurLabelIndex > c then
		label = CreateFrame("SimpleHtml", nil, SearchResults);
		label:SetFont("p", 'Fonts\\FRIZQT__.TTF', 11, "");
		label:SetWidth(450);
		label:SetScript("OnHyperlinkClick",
			function(self,link,text,button)
				SetItemRef(link, text, button, DEFAULT_CHAT_FRAME);
			end
		);
	else
		label = AchieveAche_Labels[AchieveAche_CurLabelIndex];
	end

	SearchResults:SetHeight(AchieveAche_CurLabelIndex * 22 + 22);

	label:SetPoint("TOPLEFT", 20, AchieveAche_CurLabelIndex * -22);

	link = GetAchievementLink( achieveid );
	if bIsCompleted then
		label:SetText( link );
	else
		label:SetText( link );
	end
	label:SetHeight(22);
	label:Show();

	if AchieveAche_CurLabelIndex > c then
		tinsert( AchieveAche_Labels, label );
	end

	AchieveAche_CurLabelIndex = AchieveAche_CurLabelIndex + 1;
end

function AchieveAche_SearchAllContaining( sText, bOnlyUncompleted )
	AchieveAche_HideAllLabels();

	sLowerText = string.lower(sText);

	if not bOnlyUncompleted then
		for achieveid, info in pairs(AchieveAche_CompletedAchievements) do
			sLowerDesc = string.lower(info["desc"]);
			sLowerName = string.lower(info["name"]);
			if string.find( sLowerDesc, sLowerText ) or string.find( sLowerName, sLowerText ) then
				AchieveAche_AddToResults( achieveid, info, true);
			end
		end
	end

	for achieveid, info in pairs(AchieveAche_UncompletedAchievements) do
		sLowerDesc = string.lower(info["desc"]);
		sLowerName = string.lower(info["name"]);
		if string.find( sLowerDesc, sLowerText ) or string.find( sLowerName, sLowerText ) then
			AchieveAche_AddToResults( achieveid, info, false);
		end
	end
end

function AchieveAcheSettings_LoadFromSavedVariables()
	AchieveAche_Ready = false;
	AchieveAche_Categories = {};
	AchieveAche_CompletedAchievements = {};
	AchieveAche_UncompletedAchievements = {};
	AchieveAche_Labels = {};
	AchieveAche_CurLabelIndex = 1;
end


function AchieveAche_MessageSelf( sMsg )
  if DEFAULT_CHAT_FRAME then
     DEFAULT_CHAT_FRAME:AddMessage( sMsg, 1.0, 0.0, 0.0);
  end
end

function AchieveAche_OnEvent( obj, event, ... )
	if ( event == CONST_VARSLOADED ) then
		AchieveAcheSettings_LoadFromSavedVariables();
--		AchieveAche_LoadAchievementsFromApi();

		bReady = true;
	end
end

function Button1_OnClick(sender, button, down)
	AchieveAcheFrame:Hide();
end

function Button2_OnClick()
	EditBox1:ClearFocus();

	isChecked = CheckButton1:GetChecked();
	sText = EditBox1:GetText();

	AchieveAche_SearchAllContaining( sText, isChecked );
end

function EditBox1_OnEnterPressed()
	Button2_OnClick();
end

function EditBox1_OnEscapePressed()
	EditBox1:ClearFocus();
end

function Button3_OnClick()
	sZone = GetRealZoneText();
	EditBox1:SetText(sZone);
	Button2_OnClick();
end
