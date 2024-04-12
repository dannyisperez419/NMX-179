--Carga Parametros desde archivo
--function carga( file )
require "Modbus_Master"
require "HMI"
require "Reporte"
HMI=0 
Reporte_Table={}
z="|"
Reporte=""
Nombre_Archivo_UV=""
Nombre_Archivo_local_UV=""
Nombre_Archivo=""
Nombre_Archivo_local=""
Nombre_Archivo_UV_SMS=""
Nombre_Archivo_Local_UV_SMS=""
	local file="/root/Config.txt"
	local a,b=io.open(file,"r")
	local Slave={}
	Reg={}
	RegType={}
	Slave["ID"]=1
	--Slave["Func"]=16
	Slave["Type"]=20
	if (a==nil) then 
		print("No existe Archivo de configuracion")
		return 1 end
		HoM="H"
	for Linea in io.lines(file) do   --para copiar los datos del archivo de config al HMI
	print(Linea)
		if (string.len(Linea)~=0) then 
			Principio=(string.find(Linea,","))+1
			Segunda=string.find(Linea,",",Principio+1)
			Fin=string.len(Linea)
			Linea1=string.sub(Linea, Segunda+1, Fin)
			Linea2=tonumber(string.sub(Linea, Principio,Segunda-1))
			Linea3=tonumber(string.sub(Linea, 0, Principio-2) )
			Slave["Type"]=tonumber(Linea2)
			--print(Linea3, Linea2, Linea1)
			--Linea3: Direccion
			--Linea2: Tipo
			--Linea1: Dato
			local Valor
			if (Linea2==20) then 
				Valor=Linea1 
			end   --Tratar DATA como cadena
			if (Linea2==3 or Linea2==5) then Valor=tonumber(Linea1) end  --Tratar DATA como Numero
			Reg[Linea3]=Valor
			RegType[Linea3]=Linea2

			--print(Linea3, Linea2, Linea1, Slave["Type"])
			--print(Slave["Func"])
			if (Linea1~="") then 
				--if ((MB_Write( Linea3,Linea1,tonumber(Linea2),HoM,Slave))~=" 0")  then break end
			end
		else
			Linea2=-1
			Linea1="nul"
			print("Linea2", Linea2,"Linea1", Linea1)
		end
	end
	--for k,v in pairs(Reg) do print(k,v,RegType[k]) end
--Revisamos si HMI esta conectada 
if (MB_Write( 500,tostring(0),3,"H",1)~=" 0") then HMI=0 else HMI=1 end
--print(MB_Write( 500,tostring(1),3,"M",Slave))
print("HMI: ",HMI)

repeat  --ciclo infinito
	t1=os.time()
	if (t1%60==0) then 
		Hora_act=os.date("%H")
		Min_act=os.date("%M")
		print ("T2: "..Hora_act..":"..Min_act..":"..os.date("%S"))
		--Executa lineas de cada 1 min
		Busca_Disparador(Hora_act,Min_act)

	end

	if (t1%600==0) then 
		Hora_act=os.date("%H")
		Min_act=os.date("%M")
		print ("T3: (10 min) "..Hora_act..":"..Min_act..":"..os.date("%S"))
		--Executa lineas de cada 10 min
		Reenvia("PSI")
		Reenvia("CNA")
		Reenvia("UV")
		

	end
--Pone Fecha y hora a la HMI cada 1/2 hora
	if (t1%(30*60)==0) then 
		Hora_act=os.date("%H")
		Min_act=os.date("%M")
		print ("T4: (30 min) "..Hora_act..":"..Min_act..":"..os.date("%S").." Se sincroniza reloj")
		Year=tonumber(os.date("%Y"))
		Mes=tonumber(os.date("%m"))
		dia=tonumber(os.date("%d"))
		sec=tonumber(os.date("%S"))
		a,b=MB_Write(65280,Year,3,"H",1,3)
		if a==" 0" then
			MB_Write(65281,Mes,3,"H",1,3)
			MB_Write(65282,dia,3,"H",1,3)
			MB_Write(65283,Hora_act,3,"H",1,3)
			MB_Write(65284,Min_act,3,"H",1,3)
			MB_Write(65285,sec,3,"H",1,3)
		end
		
	end

	
	while (os.time()<t1+1) do end
	print ("T1: ",os.date("%H:%M:%S"))
	--Ejecuta instrucciones de 1 Segundo
	local a, b=MB_Read(65287,1,5,"H",1,3) --Esta activa la HMI?
	--print("Pantalla Activa"..a.."  "..b)
	if (a==" 0") then --Si responde HMI podemos preguntar que esta haciendo
		--if Good_signal() then  print("Buena Señal") else print("Mala Señal") end
		if (b~="0") then  --Si no esta dormida la HMI sigue preguntando en que pantalla esta
			a, c=MB_Read(508,1,5,"H",1,3)  --Sincronizar Hora?
				
				if (c~="0") then 
					Hora_act=os.date("%H")
					Min_act=os.date("%M")
					print ("Sincroniza Reloj "..Hora_act..":"..Min_act..":"..os.date("%S"))
					Year=tonumber(os.date("%Y"))
					Mes=tonumber(os.date("%m"))
					dia=tonumber(os.date("%d"))
					sec=tonumber(os.date("%S"))
					a,b=MB_Write(65280,Year,3,"H",1,3)
					if a==" 0" then
						MB_Write(65281,Mes,3,"H",1,3)
						MB_Write(65282,dia,3,"H",1,3)
						MB_Write(65283,Hora_act,3,"H",1,3)
						MB_Write(65284,Min_act,3,"H",1,3)
						MB_Write(65285,sec,3,"H",1,3)
						MB_Write(508,0,3,"H",1,3)
					end
				end 
			a, b=MB_Read(65343,1,5,"H",1,3)--en que pantalla estamos?
			if (b=="3" or b=="4" or b=="8" ) then
				a, c=MB_Read(504,1,5,"H",1,3)  --Quiere actualizar el HMI?
				--print(a,c)
				if (c~=0) then  Actualiza_Pantalla(tonumber(c)) end  --Si sí quiere manda en que pantalla esta
				a, c=MB_Read(506,1,5,"H",1,3)  --Quiere Guardar el HMI?
				--print("Print 70",a,c)
				if (c~="0") then Guarda_Datos(tonumber(c)) end --Si sí quiere manda ¿en que pantalla esta?
				--Si esta oprimido el boton de "Salvar" se ejecuta la parte para obtener los datos 
				-- de la medicion de flujo Flujo_addr Flujo_Func Flujo_Formato Flujo_Escala
				
			end
			if (b=="8" ) then
				a, c=MB_Read(507,1,5,"H",1,3)
				--print("Print 80",a,b,c)
				if (c~="0") then Muestra_Valores()	end		-- escribe al HMI el valor obtenido
			end
			if (b=="2") then Muestra_Valores() end		-- escribe al HMI el valor obtenido
			if (b=="5") then Actualiza_USB() end		-- escribe al HMI el valor obtenido
			Signal=Good_signal()
			if Signal~="error" then 
				MB_Write(650,Signal,20,"H",1)
			end
            
		
		end		
	end

	
	
until (x==1)




os.execute(exit)




