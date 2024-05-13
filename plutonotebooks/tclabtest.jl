### A Pluto.jl notebook ###
# v0.19.42

using Markdown
using InteractiveUtils

# ╔═╡ d0486440-10cd-11ef-128c-490c3ee3a4dd
using Pkg

# ╔═╡ e6528e34-887d-4e9e-bb62-787ef6528401
 Pkg.develop(path="d:\\/gitprojects/00Ai4Energy-github/TCLab.jl/")

# ╔═╡ a2bc60be-708f-4216-8048-655253a18cc6
using TCLab

# ╔═╡ 59ecce48-4c06-4c22-befd-d935e75dfe07
tclab=TCLabDevice()

# ╔═╡ 0c97668c-364d-4890-9ed0-873fbf4fb4a1
initialize!(tclab)

# ╔═╡ 1622b37d-2cb9-4ff1-9692-321d0d7da45f
LED(tclab, 100)

# ╔═╡ e509ff6e-eb0f-42c4-b3e2-e50405af08dd
LED(tclab, 0)

# ╔═╡ 492ba75a-5aff-49a9-9d4f-ec49d76903bb
LED(tclab, 25)

# ╔═╡ Cell order:
# ╠═d0486440-10cd-11ef-128c-490c3ee3a4dd
# ╠═e6528e34-887d-4e9e-bb62-787ef6528401
# ╠═a2bc60be-708f-4216-8048-655253a18cc6
# ╠═59ecce48-4c06-4c22-befd-d935e75dfe07
# ╠═0c97668c-364d-4890-9ed0-873fbf4fb4a1
# ╠═1622b37d-2cb9-4ff1-9692-321d0d7da45f
# ╠═e509ff6e-eb0f-42c4-b3e2-e50405af08dd
# ╠═492ba75a-5aff-49a9-9d4f-ec49d76903bb
