-- видеоскрипт для плейлиста "TV+ HD" http://www.tvplusonline.ru (10/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- скрапер TVS: tv+hd_pls.lua
-- расширение дополнения httptimeshift: tvhd-timeshift_ext.lua
-- ## открывает подобные ссылки ##
-- https://tv+hd.perviyhd
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://tv%+hd%.(%w+)') then return end
	local inAdr = m_simpleTV.Control.CurrentAddress
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, TypeBackColor = 0, PictFileName = '', UseLogo = 0, Once = 1})
	end
	if not m_simpleTV.User then
		m_simpleTV.User = {}
	end
	if not m_simpleTV.User.tvhd then
		m_simpleTV.User.tvhd = {}
	end
	m_simpleTV.User.tvhd.address = nil
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	local userAgent = 'Mozilla/5.0 (Windows NT 10.0; rv:86.0) Gecko/20100101 Firefox/86.0'
	local session = m_simpleTV.Http.New(userAgent)
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	local id = inAdr:gsub('.+%.(%w+)', '%1')
	local url = decode64('aHR0cHM6Ly93d3cudHZwbHVzc3RyZWFtaW5nLnJ1L2dldHNpZ25lZHVybGNkbnY0LnBocD9xPTAmcD1hJnM9MCZjPQ') .. id
	url = url:gsub('$OPT:.+', '')
	local rc, retAdr = m_simpleTV.Http.Request(session, {url = url})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then return end
	m_simpleTV.User.tvhd.address = id
	retAdr = string.format('%s$OPT:no-gnutls-system-trust$OPT:http-user-agent=%s', retAdr:gsub('%c', ''), userAgent)
	m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(retAdr .. '\n')