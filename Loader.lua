repeat
	task.wait()
until game:IsLoaded()

loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/7b1f1cadd44f51e4958bbb9f30c89568.lua"))()
