using ViewerGL, LinearAlgebraicRepresentation
GL = ViewerGL
Lar = LinearAlgebraicRepresentation

V = [0.3307458 0.2735878 0.2527472 0.1955892 0.8735746 0.9604089 1.3600696 1.4469038 0.8952041 0.4087921 0.7697594 0.2833474 0.4465003 0.3177087 0.1293396 0.000548 1.1021824 0.6979647 1.0492281 0.6450104; 1.80716725 1.73722735 1.87091125 1.80097145 1.10328515 1.58712345 1.01597415 1.49981235 1.15705855 1.04345955 1.69419185 1.58059285 2.30620035 1.78225795 2.38416245 1.86022005 1.24012995 1.20346525 1.82393505 1.78727025]
EV = Array{Int64,1}[[1, 2], [3, 4], [1, 3], [2, 4], [5, 6], [7, 8], [5, 7], [6, 8], [9, 10], [11, 12], [9, 11], [10, 12], [13, 14], [15, 16], [13, 15], [14, 16], [17, 18], [19, 20], [17, 19], [18, 20]]
VV = [[k] for k=1:size(V,2)]

GL.VIEW( GL.numbering(.05)((V,[VV, EV]),GL.COLORS[1]) );

# arrangement of input data
W = convert(Lar.Points, V')
cop_EV = Lar.coboundary_0(EV)
W, copEV, copFE = Lar.planar_arrangement(W, cop_EV)

# compute containment graph of components
bicon_comps = Lar.Arrangement.biconnected_components(copEV)

# compute euler characteristic
χ = Lar.euler_characteristic(W, copEV, copFE);
println("χ = $χ ⟹   $(χ == 2)");

# triangulation
triangulated_faces = Lar.triangulate2D(W, [copEV, copFE]);
FVs = convert(Array{Lar.Cells}, triangulated_faces);
V = convert(Lar.Points, W');
GL.VIEW( GL.GLExplode(V,FVs, 1.5,1.5,1.5,99,0.6) );

EVs = Lar.FV2EVs(copEV, copFE); # polygonal face fragments
GL.VIEW( GL.GLExplode(V,EVs,1.5,1.5,1.5,99,1) );

# visualization of component graphs
# EW = Lar.cop2lar(copEV)
# w = convert(Lar.Points, W')
# comps = [ GL.GLLines(w,EW[comp],GL.COLORS[(k-1)%12+1]) for (k,comp) in enumerate(bicon_comps) ]
# GL.VIEW(comps);
