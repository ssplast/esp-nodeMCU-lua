if not _G.http.server then
    _G.http.server = net.createServer(net.TCP, 10)
    _G.http.server:listen(_G.http.port, function (conn)
        conn:on("receive", function(conn, req)
            local parsereq = req
            print("Запрос")
            local url = string.match(req, "[%u]+ (/[%d%a]*%.?[%d%a]*)")
            local val = string.match(req, "%?([%a%d%p]+)" )
            local method = string.match(req, "([%u]+) /")
            conn:send("<div>Добро пожалровать.</div><div>".. method .."</div><div>".. url .."</div><div>".. val .."</div>")
        end)
        conn:on("sent", function(conn, payload)
            print("Отправка данных окончена.")
            conn:close()
        end)
        conn:on("disconnection", function(conn, payload)
            print("Запрос окончен.")
            conn = nil
            payload = nil
            collectgarbage()
        end)
    end)
    print("Начал работу HTTP сервер на " .. _G.http.port .. " порту.")
else
    print("HTTP сервер продалжает свою работу на порту: ".._G.http.port)
end
