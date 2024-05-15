--package.path = '/opt/lua-nats/src/?.lua;src/?.lua;' .. package.path
--pcall(require, 'luarocks.require')
--  string.format("Data for customer %s : %s %s", extension, name, number)
local nats = require 'nats'
local cjson = require('cjson')

local socket = require("socket")

local params = {
    host = '37.143.9.213',
--    host = '10.128.0.137',
    port = 4222,
}

local client_n = nats.connect(params)

--client_n:enable_trace()
client_n:set_auth('target-user', 'target-pass$')

client_n:connect()


local function subscribe_callback(payload)
      app.Verbose(1, "res data ".. payload)
--      j_data = payload:gsub("'", "\"")
--      app.Verbose(1,"parse"..j_data)
--      t = cjson.decode(j_data)
        t = cjson.decode(payload)
     app.Verbose(1,t.port .." uuid "..t.uuid.." ip "..t.ip)
     uuid_aos=t.uuid
     ip_aos=t.ip
     port_aos=t.port
     n_time=t.unix_time

end

--local _M = {}
function getHostname()
    local f = io.popen ("/bin/hostname")
    local hostname = f:read("*a") or ""
    f:close()
    hostname =string.gsub(hostname, "\n$", "")
    return hostname
end
--return _M

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



function   aos_in(context, exten)
	app.noop("a_soc exten:"..exten)
	uniq = channel.UNIQUEID:get()
	app.noop(string.format("UNIQUEID: %s",uniq))
--
                callee = channel.CALLERID("num"):get()
	name = channel.CALLERID("name"):get()
--    		peername = channel.CHANNEL("peername"):get()
--		domen = channel.SIP_HEADER("X-DOMEN-2"):get()
	domen = channel.PJSIP_HEADER('read',"X-DOMEN-2"):get()
--		domen = "test"
	app.noop("sip-h  "..domen)
	kama = channel.PJSIP_HEADER('read',"X-Kam"):get()
    	channel["CDR(kama-host)"]:set(kama)
	channel["CDR(trunk)"]:set(domen)
	channel["CDR(ari-host)"]:set(getHostname())

            n_in=  channel["DB(Nats/nats_in)"]:get()
--		app.noop("out  :"..n_in)
--		local pub_st=client_n:publish(n_in, '{"unic_id":"'..uniq.. '"} ')
	    local socket=require'socket'
	    st_time=socket.gettime()
--os.time()
                client_n:publish(n_in, '{"unic_id":"'..uniq.. '","from":"'..callee..'","to":"'..exten..'","domen":"'..domen..'","ari_host":"'..getHostname()..'"}')
                local subscribe_id = client_n:subscribe(uniq, subscribe_callback)
                client_n:wait(1)
	client_n:unsubscribe(subscribe_id)

        app.Verbose(1, "send" ..subscribe_id)
	app.Verbose(1, "Extension " .. exten .. " disabled".."  uuid "..uuid_aos .." ip:"..ip_aos.." port ".. port_aos )
	    end_time=socket.gettime()
	    all_time=uuid_aos..",IN,"..st_time..","..n_time..","..end_time.."\n"
	    file = io.open("/var/spool/asterisk/monitor/ast12.csv","a+")
	    file:write(all_time)
	    file:close()

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

--[[	    local isOpen, error = isPortOpen(ip_aos, port_aos)
	    if isOpen then
	            app.noop("Порт " .. ip_aos .. " открыт.")
	    else
	            app.noop("Порт " .. ip_aos .. " закрыт или недоступен. Ошибка: " .. error)
		end_time=socket.gettime()
	    all_time=uuid_aos..",IN,"..st_time..","..n_time..","..end_time.."\n"
	    file = io.open("/var/log/asterisk/ast12s.csv","a+")
	    file:write(all_time)
	    file:close()

		app.hangup(17)

	    end
]]--

	channel["CDR(direction)"]:set("IN")
	channel.CHANNEL('hangup_handler_push'):set('out_n,s,1')



	aos_s=string.format('%s,%s:%s', uuid_aos, ip_aos, port_aos)
	aos_d=string.format('AudioSocket/%s:%s/%s/c(slin192)',ip_aos , port_aos, uuid_aos)
--		app.Verbose(1,"string "..aos_s)
    	app.wait(6)
                 app.answer()
--	app.playback("beep")
                app.AudioSocket(aos_s)
--		app.dial(aos_d)
--		app.Verbose(1, string.format("Device name : %s, callee %s", name, callee))
	app.hangup(34)
	end;

function   aos_in2(context, exten)
	app.noop("a_soc exten:"..exten)
	uniq = channel.UNIQUEID:get()
	app.noop(string.format("UNIQUEID: %s",uniq))

                callee = channel.CALLERID("num"):get()
	name = channel.CALLERID("name"):get()
	domen = channel.PJSIP_HEADER('read',"X-DOMEN-2"):get()
	app.noop("sip-h  "..domen)
	kama = channel.PJSIP_HEADER('read',"X-Kam"):get()
    	channel["CDR(kama-host)"]:set(kama)
	channel["CDR(trunk)"]:set(domen)
	channel["CDR(ari-host)"]:set(getHostname())
	app.noop('"from":"'..callee..'","to":"'..exten..'","domen":"'..domen)

	channel["CDR(direction)"]:set("IN")
	channel.CHANNEL('hangup_handler_push'):set('out_n,s,1')

	local command= "python3 /etc/asterisk/ar2.py"
	local p = assert(io.popen(command))
	local result = p:read("*all")
	p:close()
	app.noop("sip id ".. result)
	app.dial('sip/'..result)

	end;



function out(context,exten)
	app.noop("out variable : exten".. exten.." param "..channel.param:get())
        dial_str="tTo"
        sip_h=""
	trunk=""
	suf=""
	play=""
	brige=""
	nats=""
	channel["CDR(ari-host)"]:set(getHostname())
	channel["CDR(direction)"]:set("OUT")
	channel.CHANNEL('hangup_handler_push'):set('out_n,s,1')
        param=channel.param:get()
	b1=""
	p1=""
                t = cjson.decode(param)

	    -- Вывод значений из таблицы
	    for key, value in pairs(t) do
	     if key=='sip_h' then
		app.noop("sip_h")
		if type(value) == "table" then
		        for l, w in pairs(value) do
        		 app.noop(l, "=", w)
    	                    end
	        end
	        sip_h=value
	     elseif key=='trunk' then
		trunk=value
		channel["CDR(trunk)"]:set(value)
	     elseif key=='suf' then
		suf='U(sub-suf^${'..value..'})'
             elseif key=='play' then
		if  (b1~=1 or b1~=nil) then
		app.noop("b1")
--                                play='U(play_f^${'..value..'})'
		p1=value
		else
		app.noop("b2")
--				play='U(play_f^${'..value..'}^${'..b1..'})'
		end
	     elseif key=='bridge' then
		if (p1~="" or p1~=nil) then
		app.noop("p1"..)
		play= 'U(play_f^'..value..')'
		b1=value
		else
		app.noop("p2")
		b1=value
		end
    	    elseif key=='nats_in' then
		channel["DB(Nats/nats_in)"]:set(value)
		nats="1"
		--nn=channel["DB(DND/nats)"]:get()
		--app.noop("db key ".. nn)
		--	channel["DB(DND/"..cid.."/)"]:get()
--                         app.noop("key "..key.." val "..value)
	        elseif  key=='nats_out' then
	            channel["DB(Nats/nats_out)"]:set(value)
		nats="1"
	    end
	    end
	    app.noop("b "..b1.."  p1 "..p1)
--	    if (b1~="" or p1~="") then
--		play='U(play_f2^'..p1..'^'..b1..')'
--	    end
	    if (sip_h~="") then
	        sip_hs='b(handler^addheader^1)'
	        else
	        sip_hs=""
	    end
	    if (nats=="1") then
	            app.noop("in  :"..channel["DB(Nats/nats_in)"]:get())
    		app.noop("out :"..channel["DB(Nats/nats_out)"]:get())
    		app.hangup()
	    end
	    dail_str='PJsip/'..exten..'@'..trunk..',30,'..dial_str..play..suf..sip_hs
	    app.noop("d_s"..dail_str)
	app.dial(dail_str)
    end;









extensions = {
    a_soc ={
         ["_XXXXXX."] = aos_in;
         ["_+XXXXX."] = aos_in;
     ["service" ] = aos_in;
     ["sub-suf"] = function(context, exten)
	    app.noop("null string")
	    app.wait(10)
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
		    aos_s=string.format('%s,%s:%s', uniq_id, host, port)
		    aos_d=string.format('AudioSocket/%s:%s/%s', host, port, uniq_id)
		    end
		end
	    end
	uniq = channel.UNIQUEID:get()
	app.noop(string.format("UNIQUEID: %s  aos %s",uniq,aos_s))
--	    app.wait(3)
--[[		local isOpen, error = isPortOpen(host, port)
	    if isOpen then
	            app.noop("Порт " .. host .. " открыт.")
	    else
	            app.noop("Порт " .. host ..":".. port.. " закрыт или недоступен. Ошибка: " .. error)
		end_time=socket.gettime()
		all_time="out,"..uniq..","..host..":".. port ..","..end_time.."\n"
		file = io.open("/var/log/asterisk/ast12s.csv","a+")
		file:write(all_time)
		file:close()
		app.hangup(17)
	    end]]--
--			app.answer()
--		channel.CHANNEL('hangup_handler_push'):set('out_n,s,1')
--			app.dial(aos_d)
    	    app.AudioSocket(aos_s)
	end;




          ["113"] = function(context, exten)
	app.noop("a_soc exten:"..exten)
	uniq = channel.UNIQUEID:get()
               app.UserEvent("out","uniqueid:"..uniq)


	app.noop(string.format("UNIQUEID: %s",uniq))
--		app.answer()
--		app.wait(2)
--
            n_out=  channel["DB(Nats/nats_out)"]:get()
	app.noop("out  :"..n_out)
	    local socket=require'socket'
	    st_time=socket.gettime()
	local pub_st=client_n:publish(n_out, '{"unic_id":"'..uniq.. '"} ')
	if pub_st~=null then
    	app.Verbose(1, "send "..pub_st)
	end
                local subscribe_id = client_n:subscribe(uniq, subscribe_callback)
                client_n:wait(1)
	client_n:unsubscribe(subscribe_id)
                app.Verbose(1, "Extension " .. exten .. " disabled".."  uuid "..uuid_aos .." ip:"..ip_aos.." port ".. port_aos )
	callee = channel.CALLERID("num"):get()
	name = channel.CALLERID("name"):get()
	    end_time=socket.gettime()
	    all_time=uuid_aos..",OUT,"..st_time..","..n_time..","..end_time.."\n"
	    file = io.open("/var/spool/asterisk/monitor/ast12.csv","a+")
	    file:write(all_time)
	    file:close()
--    		peername = channel.CHANNEL("peername"):get()
--		channel['hangup_handler_push']='handlers,s,1'
--		app.Set('CHANNEL(hangup_handler)=handlers,s,1');
--		channel.CHANNEL('hangup_handler_push'):set('handlers,s,1')
--		app.NoOp('pre-dial handler, Adding Hangup Handler'..channel['hangup_handler_push']:get())
	app.wait(2)

	aos_s=string.format('%s,%s:%s', uuid_aos, ip_aos, port_aos)
	app.Verbose(1,"string "..aos_s)
                app.AudioSocket(aos_s)
	app.Verbose(1, string.format("Device name : %s, callee %s", name, callee))
	app.hangup(34)
	end;

};
    out_n = {
          ["_XX."] = out;
          ["_+X."] = out;
              ["pjsip_addheader"] = function (c, e)
                 json =  channel.ARG1:get()
                   for key, arg in pairs(json) do
        	 app.noop(l, "=", w)
                         channel.PJSIP_HEADER("add", key:set(arg))
                   end
                 return app['return']()
                 end;
          ["s"] = function(context, exten)
             app.noop("h case")
             app.NoOp('Hangup Cause='..channel['HANGUPCAUSE']:get().." cdr "..channel["CDR(start)"]:get())
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
    app.noop("h case")
    app.NoOp('Hangup Cause OLD ='..channel['HANGUPCAUSE']:get().." cdr "..channel["CDR(start)"]:get())
    HANGUPCAUSE_STRING=channel.HANGUPCAUSE_KEYS:get()
--  if channel["CDR(kama-host)"]:get() == nil then channel["CDR(kama-host)"]:set("out")

cdr1='{"start":"'..channel["CDR(start)"]:get()..'","src":"'..channel["CDR(src)"]:get()..'","dst":"'..channel["CDR(dst)"]:get()..'","billsec":"'..channel["CDR(billsec)"]:get()
cdr2='","trunk":"'..channel["CDR(trunk)"]:get()..'","record":"'..channel["CDR(recordingfile)"]:get()..'","Hangup_Cause":"'..channel['HANGUPCAUSE']:get()..'","duration":"'..channel["CDR(duration)"]:get()
cdr3='","direction":"OUT","uniqueid":"'..channel["CDR(uniqueid)"]:get()..'","answer":"'..channel["CDR(answer)"]:get()..'","ari-host":"'.. getHostname()..'","Kama-host":"'.. channel["CDR(kama-host)"]:get().. '"}'

app.UserEvent("i_trunk","trunk:"..channel["CDR(trunk)"]:get()..",number_a:"..channel["CDR(src)"]:get()..",uniqueid:"..channel["CDR(uniqueid)"]:get())

app.noop(cdr1)
app.noop(cdr2)
app.noop(cdr3)
    client_n:publish('cp_cdr_t',cdr1..cdr2..cdr3)
    app.Return()

        end;
};

rec ={
          ["s"] = function(context, exten)
    app.noop("record case")

f_name=exten..


    app.NoOp('Hangup Cause OLD ='..channel['HANGUPCAUSE']:get().." cdr "..channel["CDR(start)"]:get())
    HANGUPCAUSE_STRING=channel.HANGUPCAUSE_KEYS:get()
--  if channel["CDR(kama-host)"]:get() == nil then channel["CDR(kama-host)"]:set("out")

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




    demo = {
	s = demo_start;

	["2"] = function()
	    app.background("demo-moreinfo")
	    demo_instruct()
	end;
	["3"] = function ()
	    channel.LANGUAGE():set("fr") -- set the language to french
	    demo_congrats()
	end;

	["1000"] = function()
--	See the naming conflict note above.
	    app['goto']("default", "s", 1)
	end;

	["1234"] = function()
	    app.playback("transfer", "skip")
	    -- do a dial here
	end;

	["1235"] = function()
	    app.voicemail("1234", "u")
	end;

	["1236"] = function()
	    app.dial("Console/dsp")
	    app.voicemail(1234, "b")
	end;

	["#"] = demo_hangup;
	t = demo_hangup;
                i = function()
                        app.playback("invalid")
                        demo_instruct()
                end;

	["500"] = function()
	    app.playback("demo-abouttotry")
	    app.dial("IAX2/guest@misery.digium.com/s@default")
	    app.playback("demo-nogo")
	    demo_instruct()
	end;

	["600"] = function()
	    app.playback("demo-echotest")
	    app.echo()
	    app.playback("demo-echodone")
	    demo_instruct()
	end;

	["8500"] = function()
	    app.voicemailmain()
	    demo_instruct()
	end;

    };

    default = {
	-- by default, do the demo
	include = {"demo"};
    };

    public = {
	-- ATTENTION: If your Asterisk is connected to the internet and you do
	-- not have allowguest=no in sip.conf, everybody out there may use your
	-- public context without authentication.  In that case you want to
	-- double check which services you offer to the world.
	--
	include = {"demo"};
    };

    ["local"] = {
	["_NXXXXXX"] = outgoing_local;
    };
}

hints = {
    demo = {
	[1000] = "SIP/1000";
	[1001] = "SIP/1001";
    };

    default = {
	["1234"] = "SIP/1234";
    };
}