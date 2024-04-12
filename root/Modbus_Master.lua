MB_T={ "8bit_int", "8bit_uint","16bit_int_hi_first","16bit_int_low_first","16bit_uint_hi_first",
 "16bit_uint_low_first","32bit_float1234","32bit_float4321","32bit_float2143","32bit_float3412",
"32bit_int1234","32bit_int4321","32bit_int2143","32bit_int3412","32bit_uint1234","32bit_uint4321",
"32bit_uint2143","32bit_uint3412","hex","ascii","bool"}
MB_S={"300","600","1200","2400","4800","9600","19200","38400","57600","115200"}
MB_D={5,6,7,8}
MB_Stop={1,2}
MB_P={"none", "even","odd"}

function MB_Read( Add,qty,type,HoM,Sl,Func)	
		--print("Read: ",Add,qty,type,HoM,Sl,Func)
	if (HoM=="M") then
		
		a="ubus call modbus_master serial.test '{\"id\":"
		..Sl..", \"timeout\":1, \"function\":"..Func..", \"first_reg\":"..Add+1
		..", \"reg_count\":\"" ..qty.."\",\"data_type\":\""
		..MB_T[type].."\", \"no_brackets\":1,"
		.."\"serial_type\":\"/dev/rs485\", \"baudrate\":" .. MB_S[tonumber(Reg[1283])+1]..", \"databits\":"..MB_D[tonumber(Reg[285])+1]
		..", \"stopbits\":".. MB_Stop[tonumber(Reg[1289])+1]..", \"parity\":\""..MB_P[tonumber(Reg[1287]+1)].."\"}'"
		--print(a)
	elseif (HoM=="H") then
		a="ubus call modbus_master serial.test '{\"id\":"
		..Sl..", \"timeout\":1, \"function\":"..Func..", \"first_reg\":"..Add+1
		..", \"reg_count\":\"" ..qty.."\",\"data_type\":\""
		..MB_T[type].."\", \"no_brackets\":1,"
		.."\"serial_type\":\"/dev/rs232\", \"baudrate\":115200, \"databits\":8, \"stopbits\": 1, \"parity\":\"none\"}'"
	end
	--print(a)
	handle= io.popen(a)
    resultado=handle:read("*a")
	handle:close()
	if (HoM=="M") then
		--print("M: "..resultado)
		handle= io.popen(a)
    	resultado=handle:read("*a")
		handle:close()
		--print("M: "..resultado)
		handle= io.popen(a)
    	resultado=handle:read("*a")
		handle:close()
		--print("M: "..resultado)
	end
	x,y=string.find(resultado,'"error": ') 
	--print (resultado.."  error: "..x.." "..y)
	error=string.sub(resultado,y,string.find(resultado,",")-1)
	--print(resultado)
	if (error==" 0") then
		if (type<=18) then
			x,y=string.find(resultado,'"result": "')
			--print("x,y: ",x,y)
			resultado=string.sub(resultado,y+1,string.find(resultado,'"',y+1)-1)
			
		end

		if (type==20) then
			local b,c=string.find (resultado,'\"\\"')
			--print("valor de c: ",c)
			c=c+1
			local d,e=string.find (resultado,"\\u0000")
			--print("valor de d: ",d)
			if (d~=nil) then resultado=string.sub (resultado,c,d-2) end
			if (d==nil) then 
				d,e=string.find (resultado,'\\"',c) 
				--print("valor de d: ",d)
				resultado=string.sub (resultado,c,d-1)
				
			end
			
		end
	
	end
	return error, resultado
end

function MB_Write( Add,Data,type,HoM,Sla)
	--print ("Data: ",Data)
	local Sl={}
	Sl["Type"]=type
	Sl["ID"]=Sla
	
	if (HoM=="M") then
		a="ubus call modbus_master serial.test '{\"id\":"
		..Sl["ID"]..", \"timeout\":2, \"function\":".."16"..", \"first_reg\":"..Add+1
		..", \"reg_count\":\"" ..Data.."\",\"data_type\":\""
		..MB_T[type].."\", \"no_brackets\":1,"
		.."\"serial_type\":\"/dev/rs485\", \"baudrate\":" .. MB_S[tonumber(Reg[1283])+1]..", \"databits\":"..MB_D[tonumber(Reg[285])+1]
		..", \"stopbits\":".. MB_Stop[tonumber(Reg[1289])+1]..", \"parity\":\""..MB_P[tonumber(Reg[1287]+1)].."\"}'"
	elseif (HoM=="H") then
		a="ubus call modbus_master serial.test '{\"id\":"
		..Sl["ID"]..", \"timeout\":2, \"function\":".."16"..", \"first_reg\":"..Add+1
		..", \"reg_count\":\"" ..Data.."\",\"data_type\":\""
		..MB_T[type].."\", \"no_brackets\":1,"
		.."\"serial_type\":\"/dev/rs232\", \"baudrate\":115200, \"databits\":8, \"stopbits\": 1, \"parity\":\"none\"}'"
	end
	--print(a)
	handle= io.popen(a)
	--print(a)
    resultado=handle:read("*a")
    handle:close()
    --print(resultado)
    local x,y=string.find(resultado,'"error": ') 
    local error=string.sub(resultado,y,string.find(resultado,",")-1)
    --print (error)
    if (error~=" 0") then 
    	local x,y=string.find(resultado,'"result": "')
    	local resultado=string.sub(resultado,y+1,string.find(resultado,'"',y+1)-1)
    	--print("Error: ",error)
    	return error
    else
      	--print("Error (else): ",error)
      	return error
    end
end


