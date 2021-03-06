-- видеоскрипт для плейлиста "wifire" https://wifire.tv (29/9/20)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- скрапер TVS: wifire_pls.lua
-- открывает подобные ссылки:
-- https://wifire.tv/1TVHD_OTT_wflite.m3u8
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://wifire%.tv') then return end
	local inAdr = m_simpleTV.Control.CurrentAddress
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, TypeBackColor = 0, PictFileName = '', UseLogo = 0, Once = 1})
	end
	if not m_simpleTV.User then
		m_simpleTV.User = {}
	end
	if not m_simpleTV.User.wifire then
		m_simpleTV.User.wifire = {}
	end
	local function showError(str)
		m_simpleTV.OSD.ShowMessageT({text = 'wifire ошибка: ' .. str, showTime = 5000, color = 0xffff1000, id = 'channelName'})
	end
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.3987.122 Safari/537.36')
		if not session then
			showError('0')
		 return
		end
	m_simpleTV.Http.SetTimeout(session, 16000)
	local function GetToken()
		local url = 'https://api.wifire.tv/api/v1/salt/web'
		local headers = 'Referer: https://wifire.tv/'
		local rc, answer = m_simpleTV.Http.Request(session, {url = url, headers = headers})
			if rc ~= 200 then return end
		local user_id = decode64('Nzg0M2Q0YTQtZTY3NS00M2NkLTgwODgtMTkzNDcxNzNiOGU2')
		local timeSt = math.floor(os.time() / 1e3) * 1000
		timeSt = timeSt - timeSt % 600
		local secret = timeSt .. user_id .. 'register;salt=' .. answer
		url = 'https://api.wifire.tv/api/v1/register?userId=' .. user_id .. '&secret=' .. m_simpleTV.Common.CryptographicHash(secret) .. '&client=web'
		rc, answer = m_simpleTV.Http.Request(session, {url = url, method = 'post', headers = headers})
			if rc ~= 200 then return end
	 return answer:match('"session_token":"([^"]+)')
	end
	if not m_simpleTV.User.wifire.token then
		m_simpleTV.User.wifire.token = GetToken()
			if not m_simpleTV.User.wifire.token then
				m_simpleTV.Http.Close(session)
				showError('1')
			 return
			end
	end
	local retAdr = 'https://api.wifire.tv/proxy/cookies?url=https%3A%2F%2Fsgw.tv.ti.ru%2FstreamingGateway%2FGetLivePlayList%3Fsource%3D'
			.. inAdr:gsub('https://wifire.tv/', '')
			.. '%26serviceArea%3DNBN_SA&c='
			.. m_simpleTV.User.wifire.token
	local extOpt = '$OPT:NO-STIMESHIFT$OPT:demux=adaptive,any'
	local rc, answer = m_simpleTV.Http.Request(session, {url = retAdr})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then
			showError('2')
		 return
		end
	retAdr:gsub('https://', 'http://')
	local base = retAdr:match('.+/')
	local t, i = {}, 1
		for res, br, res1, adr in answer:gmatch('EXT%-X%-STREAM%-IN([%C]+)[:,]BANDWIDTH=(%d+)([%C]*).-\n(.-)\n') do
			t[i] = {}
			br = tonumber(br)
			br = math.ceil(br / 10000) * 10
			res = res:match('RESOLUTION=(%d+x%d+)')
				or res1:match('RESOLUTION=(%d+x%d+)')
			if res then
				t[i].Name = res .. ' (' .. br .. ' кбит/с)'
				res = res:match('x(%d+)')
				t[i].Id = tonumber(res)
			else
				t[i].Name = 'аудио (' .. br .. ' кбит/с)'
				t[i].Id = 0
			end
			if not adr:match('^%s*http') then
				adr = base .. adr:gsub('^[%s/%.]+', '')
			end
			adr = adr:gsub('%-vid%-', '')
			adr = adr:gsub('^[%c%s]*(.-)[%c%s]*$', '%1')
			t[i].Address = adr:gsub('https://', 'http://') .. extOpt
			i = i + 1
		end
		if i == 1 then
			m_simpleTV.Control.CurrentAddress = retAdr .. extOpt
		 return
		end
	local lastQuality = tonumber(m_simpleTV.Config.GetValue('wifire_qlty') or 5000)
	table.sort(t, function(a, b) return a.Id < b.Id end)
	local index = #t
	if #t > 1 then
		t[#t + 1] = {}
		t[#t].Id = 5000
		t[#t].Name = '▫ всегда высокое'
		t[#t].Address = t[#t - 1].Address
		t[#t + 1] = {}
		t[#t].Id = 10000
		t[#t].Name = '▫ адаптивное'
		t[#t].Address = retAdr .. extOpt
		index = #t
			for i = 1, #t do
				if t[i].Id >= lastQuality then
					index = i
				 break
				end
			end
		if index > 1 then
			if t[index].Id > lastQuality then
				index = index - 1
			end
		end
		if m_simpleTV.Control.MainMode == 0 then
			t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
			t.ExtParams = {LuaOnOkFunName = 'wifireSaveQuality'}
			m_simpleTV.OSD.ShowSelect_UTF8('⚙ Качество', index - 1, t, 5000, 32 + 64 + 128)
		end
	end
	m_simpleTV.Control.CurrentAddress = t[index].Address
	function wifireSaveQuality(obj, id)
		m_simpleTV.Config.SetValue('wifire_qlty', id)
	end
-- debug_in_file(m_simpleTV.Control.CurrentAddress .. '\n')