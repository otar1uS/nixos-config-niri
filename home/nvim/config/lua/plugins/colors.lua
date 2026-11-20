return {

	{
		"folke/tokyonight.nvim",
		-- LazyVim applies the colorscheme itself; transparency set via opts survives that reload.
		opts = {
			transparent = true,
			styles = {
				sidebars = "transparent",
				floats = "transparent",
			},
		},
	},
}
