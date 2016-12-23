-- Точка == точка доступа == роутер == маршрутизатор == модем ну вы поняли :)
-- Станция === esp-ха являеться точкой доступа

G = nil; collectgarbage() -- чистим всё перед запуском

_G = {
    sta = {
        conf = {
            reputedWIFI = {-- доверенные (ожидаемые) точки
                ["asd"] = "11111111",
                ["dsa"] = "11111111",
                ["qwert"] = "11111111",
                ["zxc"] = "11111111",
                ["ssplast23"] = "21212122",
                --["ssplast24"] = "21212122" -- закоменнтированная точка :)
            },
            illWIFI = { -- (Чёрный список) Точки которые надо избегать, к этим точкам подключения не будет.
                -- У illWIFI более высокий приоритет, если точка есть в reputedWIFI
                -- она всё равно будет исключена из возможных к подключению.
                ["dt33"] = true, -- участвует в чёрном списке
                ["illwifi"] = true,-- участвует в чёрном списке
                ["illwifi2"] = false,-- НЕ участвует в чёрном списке
                --["illwifi3"] = false,-- НЕ участвует в чёрном списке :)
            },
            wifistaconfig = {-- настройки подключения к точке доступа
                ip = "192.168.0.5", -- желаемый IP esp-хи как клиента точки [если точка доступа даст DHCP добро] :)
                netmask = "255.255.255.0",
                gateway = "192.168.0.1" -- 192.168.X._   X должен отличаться от wifiapconfig.gateway 192.168.X._ при wifi.STATIONAP
            }
        },
        start = function()
            wifi.setmode(wifi.STATIONAP) -- esp-ха будет работать в двух режимах одновременно
            -- как клиент и как точка доступа, wifi.NULLMODE = режим сна
            wifi.setphymode(wifi.PHYMODE_G)   -- https://nodemcu.readthedocs.io/en/master/en/modules/wifi/#wifisetphymode
            wifi.sta.config("________","________") -- сброс конфига (затирание)
            wifi.sta.autoconnect(1) -- включаем автоподключение к точке доступа (явно)
            wifi.sta.setip(_G.sta.conf.wifistaconfig)
            _G.sta.scan()
        end,
        scan = function()
            print("STA Начинаю сканирование.")
            wifi.sta.getap({ssid = nil,bssid = nil,channel = 0,show_hidden = 1}, 1, function(T)
                _G.sta.availableWIFI = {}
                _G.sta.reputedWIFI = {}
                _G.sta.openWIFI = {}
                _G.sta.illWIFI = {}
                for b, v in pairs(T) do
                    local s, r, a, c = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
                    table.insert(_G.sta.availableWIFI, {
                        ssid = s,
                        rssi = r,
                        authmode = a,
                        channel = c,
                        bssid = b
                    })


                    if _G.sta.conf.illWIFI[s] then -- известная точка
                        print(s.. " внесена в чёрный список.")
                        table.insert(_G.sta.illWIFI, s)
                    else
                        if _G.sta.conf.reputedWIFI[s] then -- известная точка

                            table.insert(_G.sta.reputedWIFI, {
                                ssid = s,
                                pwd = _G.sta.conf.reputedWIFI[s]
                            })
                        end

                        if tonumber(a) == 0 then -- открытая точка
                            table.insert(_G.sta.openWIFI, {ssid = s, pwd = "", rssi = r})
                        end
                    end

                    print(" " .. b .. "  " .. string.format("%-3s",r) .. "  "..a.."  "..string.format("%-2s",c).."  "..string.format("%-32s",s))
                    --print(s)
                end
                print("STA Обнаружено ".. #_G.sta.availableWIFI ..
                        " точек,\nиз них известных: " .. #_G.sta.reputedWIFI ..
                        ",\nиз них открытых: " .. #_G.sta.openWIFI ..
                        ",\nиз них запрещенных: " .. #_G.sta.illWIFI
                )

                if #_G.sta.reputedWIFI > 0 then -- есть известные точки
                print("STA Попытка подключения к известной точке " .. _G.sta.reputedWIFI[1].ssid)
                    wifi.sta.config(
                        _G.sta.reputedWIFI[1].ssid,
                        _G.sta.reputedWIFI[1].pwd,1
                    )
                elseif #_G.sta.openWIFI > 0 then -- есть открытые точки
                    print("STA Попытка подключения к открытой точке " .. _G.sta.openWIFI[1].ssid)
                    wifi.sta.config(
                        _G.sta.openWIFI[1].ssid,
                        _G.sta.openWIFI[1].pwd,1
                    )
                    wifi.sta.connect()
                else -- нет доступных точек
                    print("STA Так как доступных точек нет, следующее сканирование\nсетей будет проведено через 5 минут.")
                    tmr.alarm(0, 1000 * 60 * 5 --[[ 5 минут ]], 1, _G.sta.start)-- запускаем сканирование снова через в n-ное время
                end
            end)
        end
    },
    ap = {
        conf = {
            wifiapconfig = { -- настройки esp-хи в режиме станции
                ssid = "ESP-"..node.chipid(), -- имя esp-хи как станции
                pwd = "88888888", -- пароль авторизации
                auth = wifi.OPEN, -- режим авторизации wifi.OPEN wifi.WPA_PSK, wifi.WPA2_PSK, wifi.WPA_WPA2_PSK
                hidden = 0, -- скрытый режим 1(включён) или 0
                max = 4, -- количество одновременных клиентов (соединений)
                ip = "192.168.5.5", -- IP esp-хи как станции
                netmask = "255.255.255.0", -- полезного применения не нашол (просто стандарт)
                gateway = "192.168.5.1",-- 192.168.X._   X должен отличаться от wifistaconfig.gateway 192.168.X._ при wifi.STATIONAP
                start = "192.168.5.6" -- DHCP старт выдачи IP клиентам
            }
        },
        start = function()
            wifi.ap.config(_G.ap.conf.wifiapconfig)
            wifi.ap.setip(_G.ap.conf.wifiapconfig)
            wifi.ap.dhcp.config(_G.ap.conf.wifiapconfig)
        end
    }
}







wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
    print("STA Соединение с " .. T.SSID .. ", установленно на канале "..T.channel .. " mac: "..T.BSSID)
end)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
    print("STA Потеряно соединение с: "..T.SSID.." reason: " ..T.reason .. " BSSID: "..
            T.BSSID)
    if T.reason == 202 then
        table.insert(_G.sta.conf.illWIFI, T.SSID)
        print(T.SSID.. " добавлена в чёрный список (не удалось авторизоватся.)")
    end
    --wifi.eventmon.unregister(wifi.eventmon.STA_DISCONNECTED)
    --_G.sta.scan()
end)
wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, function(T)
print("\n\tSTA - AUTHMODE CHANGE".."\n\told_auth_mode: "..
        T.old_auth_mode.."\n\tnew_auth_mode: "..T.new_auth_mode)
end)
wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function()
print("\n\tSTA - DHCP TIMEOUT")
end)


wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print("STA Получен IP: " .. T.IP)-- T.netmask -- T.gateway
    print("Получен AP IP: " .. wifi.ap.getip())-- T.netmask -- T.gateway
    tmr.stop(0)

    --[[
    local httpServer = net.createServer(net.TCP, 10) -- 10 seconds client timeout
    httpServer:listen(80, function (connection)
        local function onReceive(connection, payload)
            print("Receive Receive Receive Receive")
            connection:send("Receive Receive Receive Receive АБВабв")
            connection:close()
        end
        local function onSent(connection, payload)
            print("Sent Sent Sent Sent")
            connection:close()
        end
        local function onDisconnect(connection, payload)
            print("Disconnect")
            collectgarbage()
        end
        connection:on("receive", onReceive)
        connection:on("sent", onSent)
        connection:on("disconnection", onDisconnect)
    end)
    ]]

end)

_G.sta.start() -- restart собственно запуск


