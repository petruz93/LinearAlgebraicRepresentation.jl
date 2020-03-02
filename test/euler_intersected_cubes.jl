using ViewerGL, LinearAlgebraicRepresentation
GL = ViewerGL
Lar = LinearAlgebraicRepresentation

# setup structure
V,(VV,EV,FV,CV) = Lar.cuboid([1,1,1],true);
cuboid_big = (V,EV,FV,CV);
V,(VV,EV,FV,CV) = Lar.cuboid([1.25,0.75,0.75],true,[0.75,0.25,0.25]);
cuboid_small = (V,EV,FV,CV);

str = Lar.Struct([ cuboid_big, cuboid_small ]);
V,EV,FV,CV = Lar.struct2lar(str);

GL.VIEW([ GL.GLGrid(V,EV, GL.COLORS[1]), GL.GLFrame ]);
GL.VIEW([ GL.GLPol(V,CV, GL.COLORS[1]) ]);

# space arrangement
cop_EV = Lar.coboundary_0(EV);
cop_FE = Lar.coboundary_1(V, FV, EV);
W = convert(Lar.Points, V');
W, copEV, copFE, copCF = Lar.spatial_arrangement(W, cop_EV, cop_FE);

# compute containment graph of components
bicon_comps = Lar.Arrangement.biconnected_components(copEV)

# compute euler characteristic
χ = Lar.euler_characteristic(W, copEV, copFE)

# triangulation
triangulated_faces = Lar.triangulate(W, [copEV, copFE]);
FVs = convert(Array{Lar.Cells}, triangulated_faces);
V = convert(Lar.Points, W');
GL.VIEW( GL.GLExplode(V,FVs, 2.,2.,2.,99,.6) );

EVs = Lar.FV2EVs(copEV, copFE); # polygonal face fragments
GL.VIEW( GL.GLExplode(V,EVs,1.5,1.5,1.5,99,1) );

v,cvs,fvs,evs = Lar.pols2tria(V, copEV, copFE, copCF) # V by cols
GL.VIEW( GL.GLExplode(V,cvs[2:end] ,1,1,1,99) );
