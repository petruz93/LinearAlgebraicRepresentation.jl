using ViewerGL, LinearAlgebraicRepresentation
GL = ViewerGL
Lar = LinearAlgebraicRepresentation

#Tetrahemihexahedron
V, (VV,EV,FV,CV) = Lar.simplex(3, true)
tetra = V, EV,FV,CV
model = Lar.Struct([ tetra,
					Lar.r(π,0,0), tetra,
					Lar.r(0,π,0), tetra,
					Lar.r(0,π,0), Lar.r(0,0,π), tetra ]);

V, EV,FV,CV = Lar.struct2lar(model)
GL.VIEW([ GL.GLGrid(V,FV), GL.GLFrame ]);

EV = collect(Set(EV)) # removes duplicates in EV
cop_EV = Lar.coboundary_0(EV::Lar.Cells);
cop_FE = Lar.coboundary_1(V, FV::Lar.Cells, EV::Lar.Cells);
W = convert(Lar.Points, V');

# arrangement don't work! TODO: fix
V, copEV, copFE, copCF = Lar.Arrangement.spatial_arrangement( W::Lar.Points, cop_EV::Lar.ChainOp, cop_FE::Lar.ChainOp)
χ = Lar.euler_characteristic(W, copEV, copFE)

FVs = [ [FV[k]] for k=1:length(FV)]
GL.VIEW(GL.GLExplode(V,FVs,1.5,1.5,1.5,99, .5));
