local nats = require 'nats'
local cjson = require('cjson')

local socket = require("socket")

local params = {
    host = '37.143.9.213',
--    host = '10.128.0.137',
    port = 4222,
}

local client_n = nats.connect(params)

client_n:set_auth('target-user', 'target-pass$')
client_n:connect()


local function subscribe_callback(payload)
      app.Verbose(1, "res data ".. payload)
        t = cjson.decode(payload)
--     app.Verbose(1,t.port .." uuid "..t.uuid.." ip "..t.ip)
     uuid_aos=t.uuid
     ip_aos=t.ip
     port_aos=t.port
--     n_time=t.unix_time

end


function getHostname()
    local f = io.popen ("/bin/hostname")
    local hostname = f:read("*a") or ""
    f:close()
    hostname =string.gsub(hostname, "\n$", "")
    return hostname
end

-- Функция для проверки открытости порта
function isPortOpen(host, port)
    local sock = socket.tcp()
    sock:settimeout(10) -- Устанавливаем тайм-аут на подключение

    local result, error = sock:connect(host, port)
    if result then
        sock:close()
        return true
    else
        return false, error
    end
end

-- Разбор строки 
function split(source, sep)
    local result, i = {}, 1
    while true do
        local a, b = source:find(sep)
        if not a then break end
        local candidat = source:sub(1, a - 1)
        if candidat ~= "" then
            result[i] = candidat
        end i=i+1
        source = source:sub(b + 1)
    end
    if source ~= "" then
        result[i] = source
    end
    return result
end

function val(str)
    local result = split(str, ":")
    c=0
    for i, v in ipairs(result) do
        if c==0 then
	    key=v
    	    c=c+1
	else
    	    value=v
	end
    end
--    print("key ".. key.. " value "..value)
    return key,value
end



function   aos_in(context, exten)
	uniq = channel.UNIQUEID:get()
	app.noop(string.format("UNIQUEID: %s  a_soc: %s ",uniq,exten))

        callee = channel.CALLERID("num"):get()
	domen = channel.PJSIP_HEADER('read',"X-DOMEN-2"):get()
	channel["CDR(trunk)"]:set(domen)
	channel["CDR(ari-host)"]:set(getHostname())

            n_in=  channel["DB(Nats/nats_in)"]:get()

        client_n:publish('incoming_call', '{"sm_uuid":"'..n_in..'", "unic_id":"'..uniq.. '","from":"'..callee..'","to":"'..exten..'","domen":"'..domen..'","ari_host":"'..channel["CDR(ari-host)"]:get()..'"}')
--                client_n:publish(n_in, '{"unic_id":"'..uniq.. '","from":"'..callee..'","to":"'..exten..'","domen":"'..domen..'","ari_host":"'..channel["CDR(ari-host)"]:get()..'"}')
                local subscribe_id = client_n:subscribe(uniq, subscribe_callback)
                client_n:wait(1)
		client_n:unsubscribe(subscribe_id)

--        app.Verbose(1, "send" ..subscribe_id)
	app.Verbose(1, "Extension " .. exten .. " disabled".."  uuid "..uuid_aos .." ip:"..ip_aos.." port ".. port_aos )

	channel["CDR(direction)"]:set("IN")
	channel.CHANNEL('hangup_handler_push'):set('out_n,s,1')

	if port_aos=='0' then
	    app.hangup(17)
	elseif port_aos=='1' then
	    local command= "python3 /etc/asterisk/ar2.py"
	    local p = assert(io.popen(command))
	    local result = p:read("*all")
	    p:close()
	    app.noop("sip id ".. result)
	    app.dial('sip/'..result)
	    app.hangup(17)
	end

	aos_s=string.format('%s,%s:%s', uuid_aos, ip_aos, port_aos)
	aos_d=string.format('AudioSocket/%s:%s/%s/c(slin192)',ip_aos , port_aos, uuid_aos)
--		app.Verbose(1,"string "..aos_s)
    	app.wait(6)
                 app.answer()
app.UserEvent("bridge","unic_id:"..uniq.. ",Socketid:"..uuid_aos ) -- связка uuid 
                app.AudioSocket(aos_s)
--		app.dial(aos_d)
	app.hangup(34)
	end;

function aos_in_stasis(context,exten)
	uniq = channel.UNIQUEID:get()
	app.noop(string.format("UNIQUEID: %s  a_soc: %s ",uniq,exten))

        callee = channel.CALLERID("num"):get()
	domen = channel.PJSIP_HEADER('read',"X-DOMEN-2"):get()
	channel["CDR(trunk)"]:set(domen)
	channel["CDR(ari-host)"]:set(getHostname())
	channel["CDR(direction)"]:set("IN")
	channel.CHANNEL('hangup_handler_push'):set('out_n,s,1')

    str=string.format( '{"unic_id":"%s";"from":"%s";"to":"%s";"domen":"%s";"ari_host":"%s"}',uniq,callee,exten,domen,channel["CDR(ari-host)"]:get())
                app.noop("str ".. str)
	app.Stasis("aos_ari",uniq,str)


end;

function out(context,exten)
	app.noop("out variable : exten".. exten.." param "..channel.param:get())
        local dial_str="tTo"
        local sip_h=""
	local trunk=""
	local suf=""
	local play=""
	local brige=""
	local nats=""
	channel["CDR(ari-host)"]:set(getHostname())
	channel["CDR(direction)"]:set("OUT")
	channel.CHANNEL('hangup_handler_push'):set('out_n,s,1')
        param=channel.param:get()
	b1="0"
	p1="0"
	direction=""
	br_id="0"
                t = cjson.decode(param)

	    -- Вывод значений из таблицы
	    for key, value in pairs(t) do
	     if key=='sip-h' then
		app.noop("sip_h")
		if type(value) == "table" then
		        for l, w in pairs(value) do
        		 app.noop(l, "=", w)
    	                    end
	        else 
	        sip_h=value
		end 
	     elseif key=='trunk' then
		trunk=value
		channel["CDR(trunk)"]:set(value)
	     elseif key=='suf' then
		suf='U(sub-suf^${'..value..'})'
             elseif key=='play' then
		p1=value
	     elseif key=='bridge' then
			b1=value
    	    elseif key=='nats_in' then
		channel["DB(Nats/nats_in)"]:set(value)
		nats="1"
	    elseif  key=='nats_out' then
	        channel["DB(Nats/nats_out)"]:set(value)
	        nats="1"
	    elseif key=='call_direction' then 
		direction=value
	     end
	    end
	    app.noop("b "..b1.."  p1 "..p1)

	    if (sip_h~="") then
--		out= cjson.encode(sip_h)
	        sip_hs='b(pjsip_add,1('..sip_h..'))'
--		sip_hs='b(addheaders,addheader,1(${somevar}))'
	        else
	        sip_hs=""
	    end
	    if (nats=="1") then
	            app.noop("in  :"..channel["DB(Nats/nats_in)"]:get())
    		app.noop("out :"..channel["DB(Nats/nats_out)"]:get())
    		app.hangup()
	    end
	    if (b1~="0" or p1~="0") then  -- Проверка наличия бриджа или файла для проигрывания 
		    play= 'U(bridge_in^'..direction..'^'..p1..'^'..b1..')'
	    end 
	    dail_str='PJsip/'..exten..'@'..trunk..',30,'..dial_str..play..suf..sip_hs
	    app.noop("d_s"..dail_str)
	app.dial(dail_str)
    end;





extensions = {
-- Мскросы обработки 
     bridge_in ={
	["s"]= function(context, exten)
	    local direct =  channel.ARG1:get()
	    local file =  channel.ARG2:get()
	    local br_id =  channel.ARG3:get()
	    app.noop("Brige in"..br_id.." File "..file)
	    if file ~="0" then
		app.noop("Noop play file "..file )
		app.Wait(3)
		app.Playback(file)
--		app.MP3Player(file)
	    end
	    if br_id~="0" then 
		app.UserEvent("kill_chan","chan:".. br_id )
		if direct =="in" then
		    app.Bridge(br_id)
		else 
		    app.BridgeAdd(br_id)
		end 
		app.Return()
	    end
	end;

	};


-- Конец 
    a_soc ={
         ["_XXXXXX."] = aos_in;
         ["_+XXXXX."] = aos_in;
     ["service" ] = aos_in;
     ["sub-suf"] = function(context, exten)
--          ["s"] = function(context, exten)
	    suf =  channel.ARG1:get()
	    app.noop("Suff "..suf)
	    app.wait(10)
	    app.senddtmf(suf)
	    app.Return()
	end;



          ["112"] = function(context, exten)
	    app.noop("a_soc exten:"..exten)
	    local socket=require'socket'
	    param_out=channel.param:get()	    
	    aos_s='s'
		app.noop("out 112 variable : exten".. exten.." param "..param_out)
        	    t = cjson.decode(param_out)
	    -- Вывод значений из таблицы
	    for key, value in pairs(t) do
	     if key=='aos'then
		app.noop("aos")
		if type(value) == "table" then
		     port='3'
		     host='2'
		     uniq_id='1'
		        for lo, w in pairs(value) do
		    	    if  lo == 'port' then
				port=w
		    	    elseif lo == 'uniq_id' then
				uniq_id=w
		    	    elseif lo == 'host' then
				host=w
    	                    end
		        end
		app.noop(string.format("host: %s  port: %s ",host,port))
		    if port==nil then 
			    app.exit() --hangup()
		    end 
		    aos_s=string.format('%s,%s:%s', uniq_id, host, port)
		    aos_d=string.format('AudioSocket/%s:%s/%s', host, port, uniq_id)
		    end
		end
	    end
	uniq = channel.UNIQUEID:get()
	app.noop(string.format("UNIQUEID: %s  aos %s",uniq,aos_s))
    	    app.AudioSocket(aos_s)
	    app.noop("!!!!!!! end auudio !!!!!!")
	end;

};

out_n = {
          ["_XX."] = out;
          ["_+X."] = out;

          ["pjsip_add"]  = function (c, e)
		local json =  channel.ARG1:get()
		local json2 =  channel.ARG2:get()
		app.noop("pjsip add header "..json.." " ..json2 )
		key,value=val(json)
                         channel.PJSIP_HEADER("add", key):set(value)
		key,value=val(json2)
                         channel.PJSIP_HEADER("add", key):set(value)

--			 channel.PJSIP_HEADER("add", "X-trunk"):set("be")
                	 app.Return()
                 end;

          ["s"] = function(context, exten)
--             app.noop("h case")
--             app.NoOp('Hangup Cause='..channel['HANGUPCAUSE']:get().." cdr "..channel["CDR(start)"]:get())
             HANGUPCAUSE_STRING=channel.HANGUPCAUSE_KEYS:get()

cdr1='{"start":"'..channel["CDR(start)"]:get()..'","src":"'..channel["CDR(src)"]:get()..'","dst":"'..channel["CDR(dst)"]:get()..'","billsec":"'..channel["CDR(billsec)"]:get()
cdr2='","trunk":"'..channel["CDR(trunk)"]:get()..'","record":"'..channel["CDR(record)"]:get()..'","Hangup_Cause":"'..channel['HANGUPCAUSE']:get()..'","duration":"'..channel["CDR(duration)"]:get()
cdr3='","direction":"'..channel["CDR(direction)"]:get()..'","uniqueid":"'..channel["CDR(uniqueid)"]:get()..'","answer":"'..channel["CDR(answer)"]:get()..'","ari-host":"'.. channel["CDR(ari-host)"]:get()..'","Kama-host":"'.. channel["CDR(kama-host)"]:get().. '"}'


app.UserEvent("i_trunk","trunk:"..channel["CDR(trunk)"]:get()..",number_a:"..channel["CDR(src)"]:get()..",uniqueid:"..channel["CDR(uniqueid)"]:get())
app.noop(cdr1)
app.noop(cdr2)
app.noop(cdr3)
    client_n:publish('cp_cdr',cdr1..cdr2..cdr3)
    app.Return()
        end;
          };

old_cdr ={
          ["s"] = function(context, exten)
--    app.noop("h case")
--    app.NoOp('Hangup Cause OLD ='..channel['HANGUPCAUSE']:get().." cdr "..channel["CDR(start)"]:get())
    HANGUPCAUSE_STRING=channel.HANGUPCAUSE_KEYS:get()

cdr1='{"start":"'..channel["CDR(start)"]:get()..'","src":"'..channel["CDR(src)"]:get()..'","dst":"'..channel["CDR(dst)"]:get()..'","billsec":"'..channel["CDR(billsec)"]:get()
cdr2='","trunk":"'..channel["CDR(trunk)"]:get()..'","record":"'..channel["CDR(recordingfile)"]:get()..'","Hangup_Cause":"'..channel['HANGUPCAUSE']:get()..'","duration":"'..channel["CDR(duration)"]:get()
cdr3='","direction":"OUT","uniqueid":"'..channel["CDR(uniqueid)"]:get()..'","answer":"'..channel["CDR(answer)"]:get()..'","ari-host":"'.. getHostname()..'","Kama-host":"'.. channel["CDR(kama-host)"]:get().. '"}'

app.UserEvent("i_trunk","trunk:"..channel["CDR(trunk)"]:get()..",number_a:"..channel["CDR(src)"]:get()..",uniqueid:"..channel["CDR(uniqueid)"]:get())
app.noop(cdr1)
app.noop(cdr2)
app.noop(cdr3)
    client_n:publish('cp_cdr',cdr1..cdr2..cdr3)
    app.Return()

        end;
};


};


