-- видеоскрипт для плейлиста "Витрина ТВ" https://wink.rt.ru (10/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- скрапер TVS: mediavitrina_pls.lua
-- ## открывает подобные ссылки ##
-- https://player.mediavitrina.ru/ctc_ext/ontvtimeru_web/player.html
-- https://player.mediavitrina.ru/kultura/limehd_web/player.html
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://player%.mediavitrina%.ru') then return end
	local inAdr = m_simpleTV.Control.CurrentAddress
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = '', TypeBackColor = 0, UseLogo = 0, Once = 1})
	end
	local function showErr(str)
		local t = {text = 'mediavitrina ошибка: ' .. str, color = ARGB(255, 255, 102, 0), showTime = 1000 * 5, id = 'channelName'}
		m_simpleTV.OSD.ShowMessageT(t)
	end
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; rv:85.0) Gecko/20100101 Firefox/85.0')
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	local function streamsTab(answer, adr)
		local t, i = {}, 1
			for w in answer:gmatch('EXT%-X%-STREAM%-INF(.-\n.-)\n') do
				local adr = w:match('\n(.+)')
				local bw = w:match('BANDWIDTH=(%d+)')
				local res = w:match('RESOLUTION=%d+x(%d+)')
				if adr and bw then
					bw = tonumber(bw)
					bw = math.ceil(bw / 100000) * 100
					t[i] = {}
					t[i].Id = bw
					if res then
						t[i].Name = res .. 'p (' .. bw .. ' кбит/с)'
					else
						t[i].Name = bw .. ' кбит/с'
					end
					t[i].Address = adr
					i = i + 1
				end
			end
			if #t > 0 then
			 return t
			end
			for res, bw in answer:gmatch('<Representation[^>]+height="(%d+)[^>]+bandwidth="(%d+)') do
				bw = tonumber(bw)
				bw = math.ceil(bw / 10000) * 10
				t[i] = {}
				t[i].Id = bw
				t[i].Name = res .. 'p (' .. bw .. ' кбит/с)'
				t[i].Address = string.format('%s$OPT:adaptive-max-bw=%s', adr, bw)
				i = i + 1
			end
	 return t
	end
	local rc, answer = m_simpleTV.Http.Request(session, {url = inAdr})
		if rc ~= 200 then
			m_simpleTV.Http.Close(session)
			showErr(1)
		 return
		end
	local url = answer:match('http[^\'"<>]+as_array%.json')
		if not url then
			m_simpleTV.Http.Close(session)
			showErr(1)
		 return
		end
	local rc, answer = m_simpleTV.Http.Request(session, {url = decode64('aHR0cHM6Ly9tZWRpYS5tZWRpYXZpdHJpbmEucnUvZ2V0X3Rva2Vu')})
		if rc ~= 200 then
			m_simpleTV.Http.Close(session)
			showErr(2)
		 return
		end
	local token = answer:match('"token":"([^"]+)')
		if not token then
			showErr(3)
		 return
		end
	url = url .. '?token=' .. token
	rc, answer = m_simpleTV.Http.Request(session, {url = url})
		if rc ~= 200 then
			m_simpleTV.Http.Close(session)
			showErr(4)
		 return
		end
	local retAdr = answer:match('"mpd":%["([^"]+)') or answer:match('"hls":%["([^"]+)')
		if not retAdr then
			showErr(5)
		 return
		end
	rc, answer = m_simpleTV.Http.Request(session, {url = retAdr})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then
			showErr(6)
		 return
		end
	local t = streamsTab(answer, retAdr)
		if #t == 0 then
			m_simpleTV.Control.CurrentAddress = retAdr
		 return
		end
	table.sort(t, function(a, b) return a.Id < b.Id end)
	local lastQuality = tonumber(m_simpleTV.Config.GetValue('mediavitrina_qlty') or 5000000)
	local index = #t
	if #t > 1 then
		t[#t + 1] = {}
		t[#t].Id = 5000000
		t[#t].Name = '▫ всегда высокое'
		t[#t].Address = t[#t - 1].Address
		t[#t + 1] = {}
		t[#t].Id = 10000000
		t[#t].Name = '▫ адаптивное'
		t[#t].Address = retAdr
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
			t.ExtParams = {LuaOnOkFunName = 'mediavitrinaSaveQuality'}
			m_simpleTV.OSD.ShowSelect_UTF8('⚙ Качество', index - 1, t, 5000, 32 + 64 + 128)
		end
	end
	m_simpleTV.Control.CurrentAddress = t[index].Address
	function mediavitrinaSaveQuality(obj, id)
		m_simpleTV.Config.SetValue('mediavitrina_qlty', tostring(id))
	end
-- debug_in_file(t[index].Address .. '\n')