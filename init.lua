-- ����� == ����� ������� == ������ == ������������� == ����� �� �� ������ :)
-- ������� === esp-�� ��������� ������ �������

G = nil; collectgarbage() -- ������ �� ����� ��������

_G = {
    http = {
        port = 80 -- HTTP ������ ����� ������� ���� ����
    },
    sta = {
        conf = {
            reputedWIFI = {-- ���������� (���������) ����� (�� ������ ������ �����������)
                ["asd"] = "11111111",
                ["dsa"] = "11111111",
                ["qwert"] = "11111111",
                ["zxc"] = "11111111",
                ["25_konteiner"] = "21212122",
                ["ssplast23"] = "21212122",
                --["ssplast24"] = "21212122" -- ������������������ ����� :)
            },
            illWIFI = { -- (׸���� ������) ����� ������� ���� ��������, � ���� ������ ����������� �� �����.
                -- � illWIFI ����� ������� ���������, ���� ����� ���� � reputedWIFI
                -- ��� �� ����� ����� ��������� �� ��������� � �����������.
                ["dt33"] = true, -- ��������� � ������ ������
                ["infotradeinfo"] = true,-- ��������� � ������ ������
                ["illwifi"] = true,-- ��������� � ������ ������
                ["illwifi2"] = false,-- �� ��������� � ������ ������
                --["illwifi3"] = false,-- �� ��������� � ������ ������ :)
            },
            wifistaconfig = {-- ��������� ����������� � ����� �������
                ip = "192.168.1.5", -- �������� IP esp-�� ��� ������� ����� [���� ����� ������� ���� DHCP �����] :) ������ gateway ����
                netmask = "255.255.255.0",
                gateway = "192.168.1.1" -- 192.168.X._ ������ ��������� � dhcp �������
                -- ���� ������ �������� � ������ ��������� 192.168.X.5 ������� X �������� � �������� �������
                -- ����� ������ ��� ��������� ������������� ������ wifi.sta.setip(_G.sta.conf.wifistaconfig)
                }
        },
        start = function()
            wifi.setmode(wifi.STATIONAP) -- esp-�� ����� �������� � ���� ������� ������������
            -- ��� ������ � ��� ����� �������, wifi.NULLMODE = ����� ���
            wifi.setphymode(wifi.PHYMODE_G)   -- https://nodemcu.readthedocs.io/en/master/en/modules/wifi/#wifisetphymode
            -- wifi.sta.config("________","________") -- ����� ������� (���������)
            wifi.sta.autoconnect(1) -- �������� ��������������� � ����� ������� (����)
            wifi.sta.setip(_G.sta.conf.wifistaconfig)-- ���� ��������������� ��� ������ ������ esp-�� ����� �������� IP �� ��� ����������
            _G.sta.scan()
        end,
        scan = function()
            print("STA ������� ������������.")
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
                    if _G.sta.conf.illWIFI[s] then -- ���� ����� ���� � ������ ������
                        --print("STA ����� " .. s .. " ������� � ������ ������.")
                        table.insert(_G.sta.illWIFI, s)
                    else
                        if _G.sta.conf.reputedWIFI[s] then -- ��������� �����
                            table.insert(_G.sta.reputedWIFI, {
                                ssid = s,
                                pwd = _G.sta.conf.reputedWIFI[s]
                            })
                        end
                        if tonumber(a) == 0 then -- �������� �����
                            table.insert(_G.sta.openWIFI, {ssid = s, pwd = "", rssi = r})
                        end
                    end
                    print(" " .. b .. "  " .. string.format("%-3s",r) .. "  "..a.."  "..string.format("%-2s",c).."  "..string.format("%-32s",s))
                end
                print("STA ���������� ".. #_G.sta.availableWIFI ..
                        " �����,\n�� ��� ���������: " .. #_G.sta.reputedWIFI ..
                        ",\n�� ��� ��������: " .. #_G.sta.openWIFI ..
                        ",\n�� ��� �����������: " .. #_G.sta.illWIFI
                )
                if #_G.sta.reputedWIFI > 0 then -- ���� ��������� �����
                print("STA ������� ����������� � ��������� ����� " .. _G.sta.reputedWIFI[1].ssid)
                    wifi.sta.config(
                        _G.sta.reputedWIFI[1].ssid,
                        _G.sta.reputedWIFI[1].pwd,1
                    )
                elseif #_G.sta.openWIFI > 0 then -- ���� �������� �����
                    print("STA ������� ����������� � �������� ����� " .. _G.sta.openWIFI[1].ssid)
                    wifi.sta.config(
                        _G.sta.openWIFI[1].ssid,
                        _G.sta.openWIFI[1].pwd,1
                    )
                end
            end)
        end
    },
    ap = {
        conf = {
            wifiapconfig = { -- ��������� esp-�� � ������ �������
                ssid = "ESP-"..node.chipid(), -- ��� esp-�� ��� �������
                pwd = "88888888", -- ������ �����������
                auth = wifi.WPA_WPA2_PSK, -- ����� ����������� wifi.OPEN, wifi.WPA_PSK, wifi.WPA2_PSK, wifi.WPA_WPA2_PSK
                hidden = 0, -- ������� ����� 1(�������) ��� 0
                max = 4, -- ���������� ������������� �������� (����������)
                ip = "192.168.5.5", -- IP esp-�� ��� �������
                netmask = "255.255.255.0", -- ��������� ���������� �� ����� (������ ��������)
                gateway = "192.168.5.1",
                start = "192.168.5.6" -- DHCP ����� ������ IP ��������
            }
        },
        start = function()
            wifi.ap.config(_G.ap.conf.wifiapconfig)
            wifi.ap.setip(_G.ap.conf.wifiapconfig)
            wifi.ap.dhcp.config(_G.ap.conf.wifiapconfig)
            print("\n\n\nAP ���������� IP: " .. wifi.ap.getip())-- T.netmask -- T.gateway
        end
    }
}

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
    print("STA ���������� � " .. T.SSID .. ", ������������ �� ������ "..T.channel .. " mac: "..T.BSSID)
end)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
    print("STA ������� IP: " .. T.IP)-- T.netmask -- T.gateway
    dofile("myhttpserver.lua")-- ����� ��������� � � ������ �����,
    -- ��� HTTP ������ ����������� ����� �������� ����������� � �������
end)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
    print("STA �������� ���������� �: "..T.SSID.." reason: " ..T.reason .. " BSSID: "..
            T.BSSID)
    if T.reason == 202 and not _G.sta.conf.illWIFI[T.SSID] then
        _G.sta.conf.illWIFI[T.SSID] = true
        print(T.SSID.. " ��������� � ������ ������ (�� ������� �������������.)")
    end
    _G.sta.start()
end)
wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, function(T)
    print("wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, function(T)")
    _G.sta.start() end)
wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function()
    print("wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function()")
    _G.sta.start() end)
wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
    print("AP ����������� ������ MAC: " .. T.MAC .. " ID: " .. T.AID) end)
wifi.eventmon.register(wifi.eventmon.AP_STADISCONNECTED, function(T)
    print("AP �������� ���������� � �������� MAC: " .. T.MAC .. " ID: " .. T.AID) end)


_G.ap.start() -- ������������� ������� � ������ �����������, ESP-�� ��� ����� �������
_G.sta.start() -- start ���������� ������ STA, ESP-�� ��� ������ �������


