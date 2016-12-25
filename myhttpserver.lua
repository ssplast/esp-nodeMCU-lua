if not _G.http.server then
    _G.http.server = net.createServer(net.TCP, 10)
    _G.http.server:listen(_G.http.port, function (connection)


        local function onReceive(connection, req)
            print("Запрос")
            local e = req:find("\r\n", 1, true)
            local line = req:sub(1, e - 1)
            local r = {}
            _, i, r.method, r.request = line:find("^([A-Z]+) (.-) HTTP/[1-9]+.[0-9]+$")
            print("_ = " .. _)
            print("i = " .. i)
            print("r.method = " .. r.method)
            print("r.request = " .. r.request)
            print(line)
            print("\n\n\n"..req)
            connection:send("Добро пожалровать.")
            --connection:close()
        end
        local function onSent(connection, payload)
            print("Отправка данных окончена.")
            connection:close()
        end
        local function onDisconnect(connection, payload)
            print("Запрос окончен.")
            collectgarbage()
        end
        connection:on("receive", onReceive)
        connection:on("sent", onSent)
        connection:on("disconnection", onDisconnect)
    end)
    print("Начал работу HTTP сервер на " .. _G.http.port .. " порту.")
else
    print("HTTP сервер продалжает свою работу на порту: ".._G.http.port)
end
