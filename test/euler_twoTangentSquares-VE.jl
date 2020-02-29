using ViewerGL, LinearAlgebraicRepresentation
GL = ViewerGL
Lar = LinearAlgebraicRepresentation

# input of primitive shape
V, (VV,EV,FV) = Lar.cuboid([1,1], true)
square = (V,EV)
model = Lar.Struct([ square,
			Lar.t(0,0.4), Lar.r(3π/4), square ])
V,EV = Lar.struct2lar(model)

VV = [[k] for k=1:size(V,2)]
GL.VIEW( GL.numbering(.4)((V,[VV, EV]),GL.COLORS[1]) );

# arrangement of input data
W = convert(Lar.Points, V')
cop_EV = Lar.coboundary_0(EV)
V, copEV, copFE = Lar.planar_arrangement(W, cop_EV)

# compute containment graph of components
bicon_comps = Lar.Arrangement.biconnected_components(copEV)

# compute euler characteristic
χ = Lar.euler_characteristic(V, copEV, copFE)
println("χ = $χ ; bicon_comps = $(length(bicon_comps))");

# visualization of component graphs
EW = Lar.cop2lar(copEV)
W = convert(Lar.Points, V')
comps = [ GL.GLLines(W,EW[comp],GL.COLORS[(k-1)%12+1]) for (k,comp) in enumerate(bicon_comps) ];
GL.VIEW(comps);

# final solid visualization
triangulated_faces = Lar.triangulate2D(V, [copEV, copFE])
V = convert(Lar.Points, V')
FVs = convert(Array{Lar.Cells}, triangulated_faces)
GL.VIEW(GL.GLExplode(V,FVs,1.,1.,1.,99,1));

# polygonal face boundaries
EVs = Lar.FV2EVs(copEV, copFE)
EVs = convert(Array{Array{Array{Int64,1},1},1}, EVs)
GL.VIEW(GL.GLExplode(V,EVs,1.2,1.2,1.2,99,1));
