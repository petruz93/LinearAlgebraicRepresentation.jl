"""
	euler_characteristic(V::Lar.Points, copEV::Lar.ChainOp,	copFE::Lar.ChainOp)

Return the Euler Characteristic number of a 2D- or 3D-model.
`V` is given by rows.
"""
function euler_characteristic(
		V::Lar.Points, # by rows
		copEV::Lar.ChainOp,
		copFE::Lar.ChainOp)

	χ = size(V,1) - size(copEV,1) + size(copFE,1)
	return χ
end

"""
	euler_characteristic_general(V::Lar.Points, cc::Lar.ChainOp...)

Return the Euler Characteristic number of a n-dimensional model.
`V` is given by rows.
"""
function euler_characteristic_general(V::Lar.Points, cc::Lar.ChainOp...)
	χ = size(V,1)
	for k in 1:length(cc)
		χ = χ + (-1)^k * size(cc[k],1)
	end
	return χ
end
