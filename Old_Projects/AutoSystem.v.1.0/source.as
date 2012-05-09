def mouseToCenter(_x, _y)
	screen_res_x = (_x / 2)
	screen_res_y = (_y / 2)
	
	MouseMove(screen_res_x, screen_res_y)
end_def

def createNewFolder(_folder_name)
	mouseToCenter(1440, 900)

	MouseClick("right")
	x = MouseGetPosX()
	y = MouseGetPosY()
	MouseMove((x + 100), (y + 160))
	
	Sleep(1000)
	
	MouseMove((x + 400), (y + 160))
	MouseClick()
	
	folder_name = (_folder_name + "{ENTER}")
	Send(folder_name)
end_def

Sleep(2000)
WinMinimizeAll()
createNewFolder("Secrets")