--VERSION 2.1  28/sep/23
function Busca_Disparador(Hr,Min)
	--Buscamos para UV
	--print("Hr: "..Hr..":"..Min)
	--print(Reg[269],Reg[271])
	Hr=tonumber(Hr)
	Min=tonumber(Min)
	--CHECA HORA DE DISPARO PARA MSG PRUEBA UV
	if (Hr==Reg[269] and Min==Reg[271]) then
			--a, c=MB_Read(550,1,5,"H",1,3)
			--c=tonumber(c)
			print("a: "..a.."  c: "..Reg[550])
			if (Reg[550]~=0) then 
				FTP_Reporte("UV")
    			Send_SMS("UV")
    		end
   	end
	--CHECA HORA DE DISPARO PARA MSG NORMAL CONAGUA
	if (Hr==Reg[273] and Min==Reg[275]) then
			FTP_Reporte("CNA")
    		Send_SMS("CNA")
    end
	--CHECA HORA DE DISPARO PARA MSG PSI
	if (Hr==Reg[277] and Min==Reg[279]) then
		FTP_Reporte("PSI")
		Send_SMS("PSI")
	end
--AUXILIARES
local file="/root/chequeo.txt"
	local a,b=io.open(file,"r")
	if (a==nil) then 
		print("No existe Archivo de Chequeo")
		return 1 end
	for s in io.lines(file) do   --para copiar los datos del archivo de config al HMI
	print(s)
		if (string.len(s)~=0) then 
			E1=string.find(s,",")
			E2=string.find(s,",",E1+1)
			E3=string.find(s,",",E2+1)
			E4=string.find(s,",",E3+1)
			P1=string.sub(s,0,E1-1)
			P2=string.sub(s,E1+1,E2-1)
			P3=string.sub(s,E2+1,E3-1)
			P4=string.sub(s,E3+1)
		end
		print("P1: "..P1.." P2: "..P2.." P3: "..P3.." P4: "..P4)
		if P1=="*" then TrgHr=Hr else TrgHr=tonumber(P1) end
		--if Hr%(TrgHr)==0 then TrgHr=Hr end
		if P2=="*" then TrgMin=Min else TrgMin=tonumber(P2) end
		--if Min%(TrgMin)==0 then TrgMin=Min end
		print("TrgHr: "..TrgHr.." TrgMin: "..TrgMin)
		if (Hr==TrgHr and Min==TrgMin and P3=="reboot") then 
			os.execute("reboot")
		end
		if (Hr==TrgHr and Min==TrgMin) then
			Genera_Reporte("CNA")
			SendSMS_Inside(P3,Reporte)
		end
	end

end

function FTP_Reporte( tipo )
	print("FTP_Reporte", tipo)
	Genera_Reporte(tipo)
	GuardaReporte(tipo)
	Send_FTP(tipo)
	return 0
end

function Send_SMS( tipo )
	print("Send_SMS", tipo)
	if tipo=="PSI" then 
		if Reg[554]~=0 then
			if Reg[213]~="" then SendSMS_Inside(Reg[213],Reporte)   end
			if Reg[219]~="" then SendSMS_Inside(Reg[219],Reporte)   end
			if Reg[225]~="" then SendSMS_Inside(Reg[225],Reporte)   end
			if Reg[231]~="" then SendSMS_Inside(Reg[231],Reporte)   end
			if Reg[237]~="" then SendSMS_Inside(Reg[237],Reporte)   end
			if Reg[243]~="" then SendSMS_Inside(Reg[243],Reporte)   end
			if Reg[249]~="" then SendSMS_Inside(Reg[249],Reporte)   end
			if Reg[255]~="" then SendSMS_Inside(Reg[255],Reporte)   end
			if Reg[261]~="" then SendSMS_Inside(Reg[261],Reporte)   end
			if Reg[267]~="" then SendSMS_Inside(Reg[267],Reporte)   end
		end	
		if Reg[554]==0 then print("SMS Deshabilitado") end
	end
	
	if (tipo=="CNA" or tipo=="UV") then
			
		if Reg[551]==1  then
			Genera_Reporte("UV_SMS")
			Reporte="1|"..Reporte
			if Reg[350]~="" then SendSMS_Inside(Reg[350],Reporte)   end
		end
		if Reg[551]==2  then
			Genera_Reporte("UV_SMS")
			Reporte="2|"..Reporte
			if Reg[350]~="" then SendSMS_Inside(Reg[350],Reporte)   end
		end
		if Reg[551]==3  then
			Genera_Reporte("UV_SMS")
			Reporte="3|"..Reporte
			if Reg[350]~="" then SendSMS_Inside(Reg[350],Reporte)   end
		end

	end
end

function Genera_Reporte( tipo )
	print("Genera_Reporte", tipo)
	
	Reporte_Table["KER"]=0
	--AGREGAR Preguntar por otras razones del KER y sumarlas al mismo
	--	if tonumber(RSSI())<-75 then Reporte_Table["KER"]=1 end  no vamos a usar KER=1 para bajo nivel de señal
	    Mes=os.date("*t")["month"]
        if Mes<10 then Mes="0"..tostring(Mes) end
        Dia=os.date("*t")["day"]
        if Dia<10 then Dia="0"..tostring(Dia) end
        Hora=os.date("*t")["hour"]
        if Hora<10 then Hora="0"..tostring(Hora) end
        Minuto=os.date("*t")["min"]
        if Minuto<10 then Minuto="0"..tostring(Minuto) end
        Segundo=os.date("*t")["sec"]
        if Segundo<10 then Segundo="0"..tostring(Segundo) end
        Reporte_Table["Fecha"]=os.date("*t")["year"]..Mes..Dia
        Reporte_Table["Hora"]=Hora..Minuto..Segundo
        --Reporte_Table["KER"]="003"
        Reporte_Table["RFC"]=string.upper(Reg[0])
        --OBTEN VALOR DEL MEDIDOR EL TOTALIZADO
        if (Reg[303]>6 and Reg[303]<19) then Qty=2 else Qty=1 end
		--if (Reg[295]>6) then Qty=2 else Qty=1 end
		a,b=MB_Read(Reg[299],Qty,Reg[303],"M",Reg[281],4-Reg[301])
		--print(Reg[303],Qty,Reg[301],a,b)
		if (a==" 0") then 
			Valor=string.format("%11.3f",b)
			Reporte_Table["Total"] =string.gsub(Valor," ","")
		else
			Reporte_Table["Total"] =-1
			Reporte_Table["KER"]=Reporte_Table["KER"]+16 --debemos mejorar el codigo de error ya que puede haber varios simultaneos
            Log = io.open("/root/PSI/errorLog.txt", "a+")
            io.output(Log)
            error="Fecha: "..Reporte_Table["Fecha"].." Hora: "..Reporte_Table["Hora"].." Error Modbus Medidor KER: "..Reporte_Table["KER"].."\n"
            io.write(error)
            io.close(Log)
        end
    if (tipo=="CNA" or tipo=="PSI") then
        Reporte_Table["RFC"]=Reg[0]
        Reporte_Table["NSM"]=Reg[11]
        Reporte_Table["NSUE"]=Reg[22]
        Reporte_Table["Lat"]=Reg[44]
        Reporte_Table["Long"]=Reg[55]
        Reporte_Table["NSUTD"]=Reg[33]

           
        Reporte="M"..z..Reporte_Table["Fecha"]..z..Reporte_Table["Hora"]..z..Reporte_Table["RFC"]..z
        ..Reporte_Table["NSM"]..z..Reporte_Table["NSUE"]..z..Reporte_Table["Total"]..z
        ..Reporte_Table["Lat"]..z..Reporte_Table["Long"]..z..Reporte_Table["KER"]
        --*********************************************************
        --****  Nombre del Archivo ***********************
        Nombre_Archivo=Reporte_Table["RFC"].."_"..Reporte_Table["Fecha"].."_"..Reporte_Table["NSM"].."_"..Reporte_Table["NSUTD"]..".txt"
        Nombre_Archivo_local="/root/temp/"..tipo.."/"..Nombre_Archivo

		


    elseif (tipo=="UV") then
    	Reporte_Table["RFC"]=Reg[0]
        Reporte_Table["NSM"]=Reg[11]
        Reporte_Table["NSUE"]=Reg[22]
        Reporte_Table["Lat"]=Reg[44]
        Reporte_Table["Long"]=Reg[55]
    	Reporte_Table["NSUTD"]=Reg[33]
    	Reporte_Table["UV"]=Reg[356]
    	Reporte="M"..z..Reporte_Table["Fecha"]..z..Reporte_Table["Hora"]..z..Reporte_Table["RFC"]..z
        ..Reporte_Table["NSM"]..z..Reporte_Table["NSUTD"]..z
        ..Reporte_Table["Lat"]..z..Reporte_Table["Long"]..z..Reporte_Table["KER"]..z..Reporte_Table["UV"]
        Nombre_Archivo_UV=Reporte_Table["RFC"].."_"..Reporte_Table["Fecha"].."_"..Reporte_Table["NSM"].."_"..Reporte_Table["NSUTD"].."_"..Reporte_Table["UV"]..".txt"
        Nombre_Archivo_local_UV="/root/temp/UV/"..Nombre_Archivo_UV

    elseif (tipo=="UV_SMS") then
    	Reporte_Table["RFC"]=Reg[0]
        Reporte_Table["NSM"]=Reg[11]
        Reporte_Table["NSUE"]=Reg[22]
        Reporte_Table["Lat"]=Reg[44]
        Reporte_Table["Long"]=Reg[55]
    	Reporte_Table["NSUTD"]=Reg[33]
    	Reporte_Table["UV"]=Reg[356]
    	Reporte="M"..z..Reporte_Table["Fecha"]..z..Reporte_Table["Hora"]..z..Reporte_Table["RFC"]..z
        ..Reporte_Table["NSM"]..z..Reporte_Table["NSUE"]..z..Reporte_Table["NSUTD"]..z..Reporte_Table["Total"]..z
        ..Reporte_Table["Lat"]..z..Reporte_Table["Long"]..z..Reporte_Table["KER"]..z..Reporte_Table["UV"]
        Nombre_Archivo_UV_SMS=Reporte_Table["RFC"].."_"..Reporte_Table["Fecha"].."_"..Reporte_Table["NSM"].."_"..Reporte_Table["NSUTD"].."_"..Reporte_Table["UV"]..".txt"
        Nombre_Archivo_local_UV_SMS="/root/temp/UV_SMS/"..Nombre_Archivo_UV_SMS    end

       
        
end

function GuardaReporte( tipo )
	print("GuardaReporte: "..tipo)
	--print(Reporte)
	if tipo=="CNA" or tipo=="PSI" then
		Archivo = io.open(Nombre_Archivo_local, "w")
		--print (Nombre_Archivo_local)
        io.output(Archivo)
		io.write(Reporte)
		io.close(Archivo)
	elseif tipo=="UV" then
		Archivo = io.open(Nombre_Archivo_local_UV, "w")
		--print(Nombre_Archivo_local_UV)
        io.output(Archivo)
		io.write(Reporte)
		io.close(Archivo)
	end	
	Archivo = io.open("/root/PSI/logger/logger_FTP.txt", "a+")
   	Reporte="FTP "..tipo.." > "..Reporte.."\n"
    io.output(Archivo)
    io.write(Reporte)
    io.close(Archivo)
    print(Reporte)
end

function Send_FTP(tipo)
        --*******Madar a FTP
        --***Leectura de la configuracion del FTP y sus credenciales
        print ("Send_FTP: "..tipo)
        --local FTP_file=(FTP_file) no se ocupa
        --print(FTP_file)
        if (tipo=="UV" or tipo=="CNA") then
        	FTP_Usr=Reg[77]
        	FTP_Pass="'"..Reg[88].."'"
        	FTP_Serv=Reg[750]
        	FTP_Port=Reg[601]
        	FTP_Path=Reg[99]
        elseif (tipo=="PSI") then
        	FTP_Usr=Reg[123]
        	FTP_Pass="'"..Reg[134].."'"
        	FTP_Serv=Reg[700]
        	FTP_Port=Reg[621]
        	FTP_Path=Reg[145]
        end

        --***************************************************************************************
    if (tipo=="UV") then
        comando="ftpput -v -u "..FTP_Usr.." -p "..FTP_Pass.." "..FTP_Serv.." "
        ..FTP_Path..Nombre_Archivo_UV.." "..Nombre_Archivo_local_UV
        --comando="curl --connect-timeout 10 -T "..Nombre_Archivo_local_UV.." ftp://"..FTP_Serv..FTP_Path..Nombre_Archivo_UV.." ".."-u "..FTP_Usr..":"..FTP_Pass.." -s "
        File_to_Send=Nombre_Archivo_local_UV
        print(comando)
    elseif (tipo=="PSI" or tipo=="CNA") then
        comando="ftpput -v -u "..FTP_Usr.." -p "..FTP_Pass.." "..FTP_Serv.." "
        ..FTP_Path..Nombre_Archivo.." "..Nombre_Archivo_local
        --comando="curl  --connect-timeout 10 -T "..Nombre_Archivo_local.." ftp://"..FTP_Serv..FTP_Path..Nombre_Archivo.." ".."-u "..FTP_Usr..":"..FTP_Pass.." -s "
        File_to_Send=Nombre_Archivo_local
        print(comando) 
    end
        
       --*******************************
    if tipo=="UV" then
    	--[[a, b=MB_Read(550,1,5,"H",1,3)
		if a==" 0" then --1
			Reg[550]=tonumber(b)--2 habilita UV
		end--3
		a, b=MB_Read(552,1,5,"H",1,3)--4
		if a==" 0" then --5
			Reg[552]=tonumber(b)--6 habilita FTP
		end--7--]]
		if (Reg[550]~=0 and Reg[552]~=0) then--8 lineas para determinar si se envia o no el comando 
			local Signal=Good_signal()
			if Signal=="Buena  " or Signal=="Regular" then
	    		if (os.execute(comando)==0) then
    	    		print("Envio Exitoso")
        			if not(os.remove(File_to_Send)) then 
        				print("Reporte Elimindo de lista exitosamente") 
        				return 0
        			end
    			else
        			print("Envio UV No exitoso")
        			return 1
    			end
    			
    			
    		end
    	else
    		if not(os.remove(File_to_Send)) then 
    			print("Reporte No enviado por FTP por peticion y NO fue Elimindo de lista.") 
    			return 0 
    		end
    		print("Reporte No enviado por FTP por peticion y Elimindo de lista exitosamente.") 
    	end
    end
	if tipo=="PSI" then
    	--[[a, b=MB_Read(553,1,5,"H",1,3)
		if a==" 0" then 
			Reg[553]=tonumber(b)
		end--]]
		if Reg[553]~=0 then
			local Signal=Good_signal()
			if Signal=="Buena  " or Signal=="Regular" then
	    		if (os.execute(comando)==0) then
	    			print("Envio Exitoso")
        			if not(os.remove(File_to_Send)) then 
        				print("Reporte Elimindo de lista exitosamente") 
        				return 0
        			end
    			else
        			print("Envio PSI No exitoso")
        			return 1
    			end
    		end
    	else
    		print("Reporte No enviado por FTP por peticion y será Elimindo de lista")
    		if not(os.remove(File_to_Send)) then 
    			print("Reporte Elimindo de lista exitosamente")
    			return 0 
    		end
    	end
    end
    if tipo=="CNA" then
    	--[[a, b=MB_Read(552,1,5,"H",1,3)
		if a==" 0" then 
			Reg[552]=tonumber(b)
		end--]]
		if Reg[552]~=0 then
			local Signal=Good_signal()
			if Signal=="Buena  " or Signal=="Regular" then
	    		if (os.execute(comando)==0) then
    	    		print("Envio Exitoso")
        			if not(os.remove(File_to_Send)) then 
        				print("Reporte Elimindo de lista exitosamente") 
        				return 0
        			end
    			else
        			print("Envio CNA No exitoso")
        			return 1
    			end
       		end
    		
    	else
    		if not(os.remove(File_to_Send)) then 
    			print("Reporte No enviado por FTP por peticion y Elimindo de lista exitosamente") 
    			return 0
    		end
    	end
    end

    
        --si no se logra enviar el ftp se debe mantener el archivo en un directorio hasta lograr el envio
        --Cuando se logra el envio se borra el archivo del directorio
        --print(os.remove(Nombre_Archivo))   --Borra el archivo

end

function Reenvia( tipo )
	print("---------------ls temp/"..tipo.."/ >directorio")
	if (os.execute("ls temp/"..tipo.."/ >directorio")==0) then 
		
		file = io.open("/root/directorio","r")
		io.input(file)
		local Linea=io.read()
		--if (Linea~="" or Linea~=nil) then print("Linea: "..Linea) end
		
		while (Linea~=nil) do 
			
			if tipo=="UV" then 
				Nombre_Archivo_UV=Linea
				Nombre_Archivo_local_UV="/root/temp/UV/"..Nombre_Archivo_UV
				print("Nombre del archivo UV: "..Nombre_Archivo_UV)
				print("Nombre del archivo local UV: "..Nombre_Archivo_local_UV)
				
			elseif tipo=="PSI" then
				Nombre_Archivo=Linea
				Nombre_Archivo_local="/root/temp/PSI/"..Nombre_Archivo
				print("Nombre del archivo: "..Nombre_Archivo)
				print("Nombre del archivo local: "..Nombre_Archivo_local)
			elseif tipo=="CNA" then
				Nombre_Archivo=Linea
				Nombre_Archivo_local="/root/temp/CNA/"..Nombre_Archivo
				print("Nombre del archivo: (CNA)"..Nombre_Archivo)
				print("Nombre del archivo local (CNA): "..Nombre_Archivo_local)
			end
			Send_FTP(tipo) 
			Linea=io.read()
		end
		io.close(file)

	end
end

function SendSMS_Inside(num, reporte)
	num=tonumber(num)
	if num~=nil then 
		
		SMS="gsmctl -S -s \""..num.." "..reporte.."\""
		print("SMS: "..SMS)
		handle= io.popen(SMS)
    	local resultado=handle:read("*a")
    	handle:close()
    	print(resultado)
    	if (string.find(resultado,"ERROR")~=nil) then
			Log = io.open("/root/PSI/errorLog.txt", "a+")
        	io.output(Log)
        	io.write(SMS)
        	io.write(resultado)
        	io.close(Log)
        else
        	if tipo~="PSI" then
				Archivo = io.open("/root/PSI/logger/logger_FTP.txt", "a+")
    			Rep="SMS Enviado a:"..num.."<=>"..reporte.." =>".."Estado del Mensaje:"..resultado
    			io.output(Archivo)
    			io.write(Rep)
    			io.close(Archivo)
    		end
        end
    end
end
function RSSI( ... )
	handle= io.popen("gsmctl -q")  --buscamos el valor RSSI
    local resultado=handle:read("*l")
    handle:close() 
    --print("Resultado: ",resultado)
   	if resultado~=nil then 
    	local valor=string.sub(resultado,(string.find(resultado," ")+1))
    	return valor
	else
		return -120
	end

    --print("RSSI: "..valor

    -- gsmctl -A AT+CREG?
end

function Good_signal( ... )
	handle= io.popen("gsmctl -A AT+CSQ")  --buscamos el valor RSSI
    local resultado=handle:read("*l")
    handle:close() 
    --print("Resultado: ",resultado)
    if resultado~=nil then 
    	local a=string.find(resultado,",")+1
    	local BER=tonumber(string.sub(resultado,a))
    	local b=string.find(resultado,": ")+2
    	local RSSI=tonumber(string.sub(resultado,b,a-2))
    	--print ("BER: "..BER)
    	--print("RSSI: "..RSSI)
    	if BER==99 and RSSI >=14 and RSSI<=31 then
    		--print ("RSSI tipo 1: "..RSSI.." BER: "..BER)
    		return "Buena  "
    	elseif BER==99 and RSSI >=131 and RSSI<=191 then
    		--print ("RSSI tipo 2: "..RSSI.." BER: "..BER)
    		return "Buena  "
    	elseif BER==99 and RSSI >=7 and RSSI<=13 then
    		--print ("RSSI tipo 1: "..RSSI.." BER: "..BER)
    		return "Regular"
    	elseif BER==99 and RSSI >=116 and RSSI<=130 then
    		--print ("RSSI tipo 2: "..RSSI.." BER: "..BER)
    		return "Regular"
    	else
    		--print("RSSI: "..RSSI.." BER: "..BER)
    		return "Mala   "
    	end
 	end
 	return "error"
end