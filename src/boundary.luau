local vide = require(script.Parent.Parent.vide)

local source = vide.source
local show = vide.show

type Result<T> = {
	ok: true,
	result: T
} | {
	ok: false,
	err: string
}

return function<T>(try: () -> T, fallback: (err: string) -> T): () -> T

	local ok, result = pcall(try)

	if not ok then warn(`error boundary caught error: "{result}"`) end

	return show(
		source(ok),
		function()
			return result
		end,
		fallback
	)

end