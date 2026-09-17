repeat
	task.wait()
until game:IsLoaded()

loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/b6711b16b0770f1e2a96659dbf64832b.lua"))()
