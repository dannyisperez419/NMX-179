--VERSION 2.0  04/septiembre/23
function Actualiza_Pantalla( pagina )
	--print("Actualiza Pantalla Pagina: ",pagina)
	local file
	if (pagina==4) then 
		file="/root/Pag4.txt" 
	elseif (pagina==3) then 
		file="/root/Pag3.txt" 
	elseif (pagina==8) then 
		file="/root/Pag8.txt"
	else 
		return -1
	end

	
	--print("File: ",file)
	local a,b=io.open(file,"r")
	--print("a, b", a, b)
	if (a==nil) then 
		print("No existe Archivo de configuracion de Pagina: ",Pagina)
		return -1
	end
	for Linea in io.lines(file) do
		Principio=(string.find(Linea,","))+1
		Linea1=tonumber(string.sub(Linea, 0, Principio-2) )
		Linea2=tonumber(string.sub(Linea, Principio))
		print(Linea1,Reg[Linea1],RegType[Linea1],"H",1)
		x,y =MB_Write(Linea1,Reg[Linea1],RegType[Linea1],"H",1)
		--print("x,y: ",x,y)
	end
	MB_Write( 504,tostring(0),5,"H",1)
	MB_Write( 503,tostring(0),5,"H",1)
	MB_Write(500,0,5,"H",1) --Borra bandera de CAMBIOS
end
function Guarda_Datos(pagina)
	print("Guarda Datos Pagina guardar: ",pagina)
	local file
	if (pagina==4) then 
		file="/root/Pag4.txt" 
	elseif (pagina==3) then 
		file="/root/Pag3.txt" 
	elseif (pagina==8) then 
		file="/root/Pag8.txt"
	else 
		return -1
	end

	
	print("File: ",file)
	local a,b=io.open(file,"r")
	print("a, b", a, b)
	if (a==nil) then 
		print("No existe Archivo de configuracion de Pagina: ",Pagina)
		return -1
	end
	for Linea in io.lines(file) do
		Principio=(string.find(Linea,","))+1
		Linea1=tonumber(string.sub(Linea, 0, Principio-2) )
		Linea2=tonumber(string.sub(Linea, Principio))
		print("L1:", Linea1, "L2:",Linea2)
		x,y =MB_Read(Linea1,Linea2,RegType[Linea1],"H",1,3)
		print("x,y: ",x,y)
		if(x~=" 0")then return -1 end
		if (RegType[Linea1]==20) then Reg[Linea1]=y end
		if (RegType[Linea1]==3) then Reg[Linea1]=tonumber(y) end
	end
	for k,v in pairs(Reg) do print(k,v) end
	print(MB_Write( 506,tostring(0),5,"H",1))--indice pagina
	print(MB_Write( 505,tostring(0),5,"H",1))--bandera
	Guardar_Archivo()
	MB_Write(500,0,5,"H",1) --Borra bandera de CAMBIOS
	os.execute(exit)
end
function Guardar_Archivo()  --guarda la configuracion actual en un archivo
	print("Guardar Archivo")
	os.execute("cp /root/Config.txt /root/Config.bak")
	local file="/root/Config.txt"
	local a=io.open(file,"w+")
	table.sort( Reg)
	table.sort(RegType)
	for k,v in pairs(Reg) do
		print(k,v)
		a:write(k..","..RegType[k]..","..Reg[k].."\n")
		print(k..","..RegType[k]..","..Reg[k])
	end
	a:close()
end
function Muestra_Valores()
	--print("Muestra Valores")
	if (Reg[295]>6 and Reg[295]<19) then Qty=2 else Qty=1 end
	--print("Linea: 85",Reg[291],Qty,Reg[295],"M",Reg[281],4-Reg[293])
	a,b=MB_Read(Reg[291],Qty,Reg[295],"M",Reg[281],4-Reg[293])
	--print(a,b)
	if (a==" 0") then 
		a,c=MB_Read(2001,1,3,"H",1,3)
		if (a==" 0") then
			c = tonumber(c)
			if c==0 then
				Valor=string.format("%11.3f",b)
				print(Valor, b)
				MB_Write(510,Valor,20,"H",1,3)
			end
			if c==1 then
				Valor=string.format("%11.3f",b/3.6)
				MB_Write(510,Valor,20,"H",1,3)
			end
		end
	else
		MB_Write(510,"error",20,"H",1,3)	
	end --si el resultado de la lectura fue exitosoe scribe al HMI el valor obtenido
	--T O T A L I Z A D O
	if (Reg[303]>6 and Reg[303]<19) then Qty=2 else Qty=1 end
	--if (Reg[295]>6) then Qty=2 else Qty=1 end
	a,b=MB_Read(Reg[299],Qty,Reg[303],"M",Reg[281],4-Reg[301])
	--print(Reg[303],Qty,Reg[301],a,b)
	if (a==" 0") then 
		Valor=string.format("%11.3f",b)
		MB_Write(520,Valor,20,"H",1)
	else
		MB_Write(520,"error",20,"H",1)
	end --si el resultado de la lectura fue exitoso --si el resultado de la lectura fue exitoso
	--print("FIN   Muestra Valores ****************")
end

function Actualiza_USB()
	handle= io.popen("mount")
    resultado=handle:read("*a")
    handle:close()
    --print(resultado)
    if string.find (resultado, "/mnt/sda1") ~=nil then 
    	Reg680=1
    	MB_Write(680,1,3,"H",1)
    	a,b=MB_Read(682,1,3,"H",1,3)
   		if a==" 0" then
   			if b~="0" then
   				handle= io.popen("umount /mnt/sda1")
    			resultado=handle:read("*a")
    			handle:close()
    			print(resultado)
    			if resultado~="" then print("Error de desmontaje") 
    			else print("Desmontaje correcto")
    				MB_Write(682,0,3,"H",1)
    				MB_Write(680,0,3,"H",1)
    			end
    		end
    	end
    	a,b=MB_Read(684,1,3,"H",1,3)
   		if a==" 0" then
   			if b~="0" then
   				handle= io.popen("cp /root/PSI/logger/logger_FTP.txt /mnt/sda1")
    			resultado=handle:read("*a")
    			handle:close()
    			print(resultado)
    			if resultado~="" then print("Error de descarga") 
    			else print("Descarga de datos correcta")
    				MB_Write(684,0,3,"H",1)
    			end
    		end
    	end
   	else
    	Reg680=0
    	MB_Write(680,0,3,"H",1)
    end
   	 	
end