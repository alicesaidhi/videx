local ReplicatedStorage = game:GetService("ReplicatedStorage")
return {
	setupFilesAfterEnv = {},
	projects = {ReplicatedStorage.packages.videx},
	testMatch = {
		"**/__tests__/*.(spec|test)",
	},
	testPathIgnorePatterns = {"dev_packages", "packages/pesde_index"},
}
