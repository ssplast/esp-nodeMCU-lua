if not _G.http.server then
    _G.http.server = net.createServer(net.TCP, 10)
    _G.http.server:listen(_G.http.port, function (conn)
        conn:on("receive", function(conn, req)
            local parsereq = req
            print("������")
            local url = string.match(req, "[%u]+ (/[%d%a]*%.?[%d%a]*)")
            local val = string.match(req, "%?([%a%d%p]+)" )
            local method = string.match(req, "([%u]+) /")
            conn:send("<div>����� �����������.</div><div>".. method .."</div><div>".. url .."</div><div>".. val .."</div>")
        end)
        conn:on("sent", function(conn, payload)
            print("�������� ������ ��������.")
            conn:close()
        end)
        conn:on("disconnection", function(conn, payload)
            print("������ �������.")
            conn = nil
            payload = nil
            collectgarbage()
        end)
    end)
    print("����� ������ HTTP ������ �� " .. _G.http.port .. " �����.")
else
    print("HTTP ������ ���������� ���� ������ �� �����: ".._G.http.port)
end
