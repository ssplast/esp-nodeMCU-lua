-- ����� == ����� ������� == ������ == ������������� == ����� �� �� ������ :)
-- ������� === esp-�� ��������� ������ �������

G = nil -- ������ �� ����� ��������
Conf = nil -- ������ �� ����� ��������
collectgarbage() -- ������ �� ����� ��������

Conf = {
    reputedPoints = {-- ���������� (���������) �����
        -- ����� �� ������� ����� �� reputedPoints, � ����� ��������������� -- :)
        ["asus_points"] = "������",
        ["�����_�������_1"] = "������",
        ["�����_�������_2"] = "������",
        ["�����_�������_3"] = "������",
        ["25_konteiner"] = "21212122",
        ["ssplast"] = "21212122"
    },
    illPoints = { -- ����� ������� ���� ��������, � ���� ������ ����������� �� �����.
        -- � illPoints ����� ������� ���������, ���� ����� ���� � reputedPoints
        -- ��� �� ����� ����� ��������� �� ��������� � �����������.
        "asus_points",
    },
    wifistaconfig = {-- ��������� ����������� � ����� �������
        ip = "192.168.0.111", -- �������� IP esp-�� ��� ������� ����� [���� ����� ������� ���� DHCP �����] :)
        netmask = "255.255.255.0",
        gateway = "192.168.0.1"
    },
    wifiapconfig = { -- ��������� esp-�� � ������ �������
        ssid = "ESP-"..node.chipid(), -- ��� esp-�� ��� �������
        pwd = "88888888", -- ������ �����������
        auth = wifi.OPEN, -- ����� ����������� wifi.OPEN wifi.WPA_PSK, wifi.WPA2_PSK, wifi.WPA_WPA2_PSK
        hidden = 0, -- ������� ����� 1(�������) ��� 0
        max = 4, -- ���������� ������������� �������� (����������)
        ip = "192.168.0.100", -- IP esp-�� ��� �������
        netmask = "255.255.255.0", -- ��������� ���������� �� ����� (������ ��������)
        gateway = "192.168.0.1",-- ��������� ���������� �� ����� (������ ��������)
        start = "192.168.0.111" -- DHCP ����� ������ IP ��������
    }
}

G = {
    sta = {
        scan = function()
            print("STA ������� ������������.")
            wifi.sta.getap({ssid = nil,bssid = nil,channel = 0,show_hidden = 1}, 1, function(T)
                G.sta.availablePoints = {}
                G.sta.reputedPoints = {}
                G.sta.flagFP = 0
                G.sta.openPoints = {}
                G.sta.flagOP = 0
                for b, v in pairs(T) do
                    local s, r, a, c = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")
                    table.insert(G.sta.availablePoints, {
                        ssid = s,
                        rssi = r,
                        authmode = a,
                        channel = c,
                        bssid = b
                    })
                    if Conf.reputedPoints[s] then
                        table.insert(G.sta.reputedPoints, {
                            ssid = s,
                            pwd = Conf.reputedPoints[s]
                        })
                    else
                        if a == 0 then
                            table.insert(G.sta.openPoints, {ssid = s, pwd = "password"})
                        end
                    end
                    print(" " .. b .. "  " .. string.format("%-3s",r) .. "  "..a.."  "..string.format("%-2s",c).."  "..string.format("%-32s",s))
                end
                print("STA ���������� ".. #G.sta.availablePoints .. " �����, ���������: " .. #G.sta.reputedPoints .. ", ��������: " .. #G.sta.openPoints .. ".")

                if #G.sta.reputedPoints then -- ���� ��������� �����
                    wifi.sta.config(
                        G.sta.reputedPoints[1].ssid,
                        G.sta.reputedPoints[1].pwd
                    )
                elseif #G.sta.openPoints then -- ���� �������� �����
                    wifi.sta.config(
                        G.sta.openPoints[1].ssid,
                        G.sta.openPoints[1].pwd
                    )
                else -- ��� ��������� �����
                    print("STA ��� ��� ��������� ����� ���, ��������� ������������\n\t����� ����� ��������� ����� 5 �����.")
                    tmr.alarm(0, 1000 * 60 * 5 --[[ 5 ����� ]], 1, G.sta.scan)
                end
            end)
        end
    }
}

wifi.setmode(wifi.STATIONAP) -- esp-�� ����� �������� � ���� ������� ������������
-- ��� ������ � ��� ����� �������, wifi.NULLMODE = ����� ���
wifi.setphymode(wifi.PHYMODE_G)   -- https://nodemcu.readthedocs.io/en/master/en/modules/wifi/#wifisetphymode
wifi.sta.config("________","________") -- ����� ������� (���������) 
wifi.sta.autoconnect(1) -- �������� ��������������� � ����� ������� (����)
wifi.sta.setip(Conf.wifistaconfig)

wifi.ap.setip(Conf.wifiapconfig)
wifi.ap.config(Conf.wifiapconfig)
wifi.ap.dhcp.config(Conf.wifiapconfig)



wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
    print("���������� � " .. T.SSID .. ", ������������ �� ������ "..T.channel .. " mac: "..T.BSSID)

    wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
        print("STA �������� ���������� �: "..T.SSID.." BSSID: "..
                T.BSSID.." reason: "..T.reason)
        wifi.eventmon.unregister(wifi.eventmon.STA_DISCONNECTED)
        G.sta.scan()
    end)

end)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print("������� IP: " .. T.IP)-- T.netmask -- T.gateway
    tmr.stop(0)


    -- httpserver
    -- Author: Marcos Kirsch

    -- Starts web server in the specified port.
    return function ()

        local s = net.createServer(net.TCP, 10) -- 10 seconds client timeout
        s:listen(
            80,
            function (connection)

                -- This variable holds the thread (actually a Lua coroutine) used for sending data back to the user.
                -- We do it in a separate thread because we need to send in little chunks and wait for the onSent event
                -- before we can send more, or we risk overflowing the mcu's buffer.
                local connectionThread

                local allowStatic = {GET=true, HEAD=true, POST=false, PUT=false, DELETE=false, TRACE=false, OPTIONS=false, CONNECT=false, PATCH=false}

                local function startServing(fileServeFunction, connection, req, args)
                    connectionThread = coroutine.create(function(fileServeFunction, bufferedConnection, req, args)
                        fileServeFunction(bufferedConnection, req, args)
                        -- The bufferedConnection may still hold some data that hasn't been sent. Flush it before closing.
                        if not bufferedConnection:flush() then
                            connection:close()
                            connectionThread = nil
                        end
                    end)

                    local BufferedConnectionClass = dofile("httpserver-connection.lc")
                    local bufferedConnection = BufferedConnectionClass:new(connection)
                    local status, err = coroutine.resume(connectionThread, fileServeFunction, bufferedConnection, req, args)
                    if not status then
                        print("Error: ", err)
                    end
                end

                local function handleRequest(connection, req)
                    collectgarbage()
                    local method = req.method
                    local uri = req.uri
                    local fileServeFunction = nil

                    if #(uri.file) > 32 then
                        -- nodemcu-firmware cannot handle long filenames.
                        uri.args = {code = 400, errorString = "Bad Request"}
                        fileServeFunction = dofile("httpserver-error.lc")
                    else
                        local fileExists = file.open(uri.file, "r")
                        file.close()

                        if not fileExists then
                            -- gzip check
                            fileExists = file.open(uri.file .. ".gz", "r")
                            file.close()

                            if fileExists then
                                --print("gzip variant exists, serving that one")
                                uri.file = uri.file .. ".gz"
                                uri.isGzipped = true
                            end
                        end

                        if not fileExists then
                            uri.args = {code = 404, errorString = "Not Found"}
                            fileServeFunction = dofile("httpserver-error.lc")
                        elseif uri.isScript then
                            fileServeFunction = dofile(uri.file)
                        else
                            if allowStatic[method] then
                                uri.args = {file = uri.file, ext = uri.ext, isGzipped = uri.isGzipped}
                                fileServeFunction = dofile("httpserver-static.lc")
                            else
                                uri.args = {code = 405, errorString = "Method not supported"}
                                fileServeFunction = dofile("httpserver-error.lc")
                            end
                        end
                    end
                    startServing(fileServeFunction, connection, req, uri.args)
                end

                local function onReceive(connection, payload)
                    collectgarbage()
                    local conf = dofile("httpserver-conf.lc")
                    local auth
                    local user = "Anonymous"

                    -- as suggest by anyn99 (https://github.com/marcoskirsch/nodemcu-httpserver/issues/36#issuecomment-167442461)
                    -- Some browsers send the POST data in multiple chunks.
                    -- Collect data packets until the size of HTTP body meets the Content-Length stated in header
                    if payload:find("Content%-Length:") or bBodyMissing then
                        if fullPayload then fullPayload = fullPayload .. payload else fullPayload = payload end
                        if (tonumber(string.match(fullPayload, "%d+", fullPayload:find("Content%-Length:")+16)) > #fullPayload:sub(fullPayload:find("\r\n\r\n", 1, true)+4, #fullPayload)) then
                            bBodyMissing = true
                            return
                        else
                            --print("HTTP packet assembled! size: "..#fullPayload)
                            payload = fullPayload
                            fullPayload, bBodyMissing = nil
                        end
                    end
                    collectgarbage()

                    -- parse payload and decide what to serve.
                    local req = dofile("httpserver-request.lc")(payload)
                    print(req.method .. ": " .. req.request)
                    if conf.auth.enabled then
                        auth = dofile("httpserver-basicauth.lc")
                        user = auth.authenticate(payload) -- authenticate returns nil on failed auth
                    end

                    if user and req.methodIsValid and (req.method == "GET" or req.method == "POST" or req.method == "PUT") then
                        handleRequest(connection, req)
                    else
                        local args = {}
                        local fileServeFunction = dofile("httpserver-error.lc")
                        if not user then
                            args = {code = 401, errorString = "Not Authorized", headers = {auth.authErrorHeader()}}
                        elseif req.methodIsValid then
                            args = {code = 501, errorString = "Not Implemented"}
                        else
                            args = {code = 400, errorString = "Bad Request"}
                        end
                        startServing(fileServeFunction, connection, req, args)
                    end
                end

                local function onSent(connection, payload)
                    collectgarbage()
                    if connectionThread then
                        local connectionThreadStatus = coroutine.status(connectionThread)
                        if connectionThreadStatus == "suspended" then
                            -- Not finished sending file, resume.
                            local status, err = coroutine.resume(connectionThread)
                            if not status then
                                print(err)
                            end
                        elseif connectionThreadStatus == "dead" then
                            -- We're done sending file.
                            connection:close()
                            connectionThread = nil
                        end
                    end
                end

                local function onDisconnect(connection, payload)
                    if connectionThread then
                        connectionThread = nil
                        collectgarbage()
                    end
                end

                connection:on("receive", onReceive)
                connection:on("sent", onSent)
                connection:on("disconnection", onDisconnect)

            end
        )
        -- false and nil evaluate as false
        local ip = wifi.sta.getip()
        if not ip then ip = wifi.ap.getip() end
        if not ip then ip = "unknown IP" end
        print("nodemcu-httpserver running at http://" .. ip .. ":" ..  port)
        return s

    end


end)

G.sta.scan()


