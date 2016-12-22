-- Точка == точка доступа == роутер == маршрутизатор == модем ну вы поняли :)
-- Станция === esp-ха являеться точкой доступа

G = nil; collectgarbage() -- чистим всё перед запуском

_G = {
    conf = {
        reputedPoints = {-- доверенные (ожидаемые) точки
            -- чтобы не удалять точку из reputedPoints, её можно закоментировать -- :)
            ["точка_доступа_1"] = "пароль",
            ["точка_доступа_2"] = "пароль",
            ["точка_доступа_3"] = "пароль",
            ["ssplast"] = "21212122"
        },
        illPoints = { -- Точки которые надо избегать, к этим точкам подключения не будет.
            -- У illPoints более высокий приоритет, если точка есть в reputedPoints
            -- она всё равно будет исключена из возможных к подключению.
            "asus_points",
        },
        wifistaconfig = {-- настройки подключения к точке доступа
            ip = "192.168.0.5", -- желаемый IP esp-хи как клиента точки [если точка доступа даст DHCP добро] :)
            netmask = "255.255.255.0",
            gateway = "192.168.0.1" -- 192.168.X._   X должен отличаться от wifiapconfig.gateway 192.168.X._ при wifi.STATIONAP
        },
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
    sta = {
        scan = function()
            print("STA Начинаю сканирование.")
            wifi.sta.getap({ssid = nil,bssid = nil,channel = 0,show_hidden = 1}, 1, function(T)
                _G.sta.availablePoints = {}
                _G.sta.reputedPoints = {}
                _G.sta.flagFP = 0
                _G.sta.openPoints = {}
                _G.sta.flagOP = 0
                for b, v in pairs(T) do
                    local s, r, a, c = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
                    table.insert(_G.sta.availablePoints, {
                        ssid = s,
                        rssi = r,
                        authmode = a,
                        channel = c,
                        bssid = b
                    })
                    if _G.conf.reputedPoints[s] then
                        table.insert(_G.sta.reputedPoints, {
                            ssid = s,
                            pwd = _G.conf.reputedPoints[s]
                        })
                    else
                        if a == 0 then
                            table.insert(_G.sta.openPoints, {ssid = s, pwd = "password"})
                        end
                    end
                    print(" " .. b .. "  " .. string.format("%-3s",r) .. "  "..a.."  "..string.format("%-2s",c).."  "..string.format("%-32s",s))
                end
                print("STA Обнаружено ".. #_G.sta.availablePoints .. " точек, известных: " .. #_G.sta.reputedPoints .. ", открытых: " .. #_G.sta.openPoints .. ".")

                if #_G.sta.reputedPoints then -- есть известные точки
                    wifi.sta.config(
                        _G.sta.reputedPoints[1].ssid,
                        _G.sta.reputedPoints[1].pwd,1
                    )
                elseif #_G.sta.openPoints then -- есть открытые точки
                    wifi.sta.config(
                        _G.sta.openPoints[1].ssid,
                        _G.sta.openPoints[1].pwd,1
                    )
                else -- нет доступных точек
                    print("STA Так как доступных точек нет, следующее сканирование\n\tсетей будет проведено через 5 минут.")
                    tmr.alarm(0, 1000 * 60 * 5 --[[ 5 минут ]], 1, _G.sta.scan)
                end
            end)
        end
    }
}

wifi.setmode(wifi.STATIONAP) -- esp-ха будет работать в двух режимах одновременно
-- как клиент и как точка доступа, wifi.NULLMODE = режим сна
wifi.setphymode(wifi.PHYMODE_G)   -- https://nodemcu.readthedocs.io/en/master/en/modules/wifi/#wifisetphymode
wifi.sta.config("________","________") -- сброс конфига (затирание)
wifi.sta.autoconnect(1) -- включаем автоподключение к точке доступа (явно)
wifi.sta.setip(_G.conf.wifistaconfig)


wifi.ap.config(_G.conf.wifiapconfig)
wifi.ap.setip(_G.conf.wifiapconfig)
wifi.ap.dhcp.config(_G.conf.wifiapconfig)



wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
    print("Соединение с " .. T.SSID .. ", установленно на канале "..T.channel .. " mac: "..T.BSSID)

    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
        print("STA потеряно соединение с: "..T.SSID.." BSSID: "..
                T.BSSID.." reason: "..T.reason)
        wifi.eventmon.unregister(wifi.eventmon.STA_DISCONNECTED)
        _G.sta.scan()
    end)

end)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print("Получен IP: " .. T.IP)-- T.netmask -- T.gateway
    print("Получен AP IP: " .. wifi.ap.getip())-- T.netmask -- T.gateway
    tmr.stop(0)

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

end)

_G.sta.scan()


