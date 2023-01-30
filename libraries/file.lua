local File = {}

local HttpService = game:GetService("HttpService")

function File.Get(Name, Options)
	local Split = Name:match("/") and Name:split("/") or {Name}
	if #Split > 1 then
	    local Current = ""
		for i = 1, #Split - 1 do
		    Current = Current.."/"..Split[i]
			if not isfolder(Current) then
			    makefolder(Current)
			end
		end
	end
	
	local Content = Options or {}
	
	local Path = Name..".json"
	if not isfile(Path) then
		writefile(Path, HttpService:JSONEncode(Content))
	else
		Content = HttpService:JSONDecode(readfile(Path))
	end
	
	return setmetatable({}, {
		__index = function(_, k)
			return rawget(Content, k)
		end,
		__newindex = function(_, k, v)
			rawset(Content, k, v)
			writefile(Path, HttpService:JSONEncode(Content))
		end
	})
end

return File
