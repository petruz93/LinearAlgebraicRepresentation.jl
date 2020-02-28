using SparseArrays
using ViewerGL
GL = ViewerGL
using LinearAlgebraicRepresentation
Lar = LinearAlgebraicRepresentation

V = [0.1972649 0.2464999 0.2187192 0.2679542 0.686082 0.5932705 0.8533899 0.7605785 1.1832645 1.3287132 1.4321643 1.5776131 1.0224958 1.2029449 0.9847223 1.1651714 1.3227588 1.353673 0.9990077 1.0299219 1.5318421 1.4893674 1.2650475 1.2225729 0.7126548 0.7569095 0.6814385 0.7256931 0.4524947 0.3425744 0.5812341 0.4713138 1.0960876 1.262034 0.9913078 1.1572542 0.9618413 0.6418082 1.0018243 0.6817912; 1.78830443 1.80930533 1.73800643 1.75900733 1.48466913 1.53732743 1.77955313 1.83221143 1.86718673 2.18004573 1.75147273 2.06433163 1.94003713 1.91927233 1.61178063 1.59101573 1.43677903 1.35742863 1.31064863 1.23129813 1.89724883 1.68246173 1.95000803 1.73522103 1.64723193 1.61188753 1.60814613 1.57280163 1.40879763 1.47291863 1.62949063 1.69361163 2.32095143 2.11285603 2.23739433 2.02929903 1.19415203 1.24807003 1.43147343 1.48539143]
EV = Array{Int64,1}[[1, 2], [3, 4], [1, 3], [2, 4], [5, 6], [7, 8], [5, 7], [6, 8], [9, 10], [11, 12], [9, 11], [10, 12], [13, 14], [15, 16], [13, 15], [14, 16], [17, 18], [19, 20], [17, 19], [18, 20], [21, 22], [23, 24], [21, 23], [22, 24], [25, 26], [27, 28], [25, 27], [26, 28], [29, 30], [31, 32], [29, 31], [30, 32], [33, 34], [35, 36], [33, 35], [34, 36], [37, 38], [39, 40], [37, 39], [38, 40]]

VV = [[k] for k=1:size(V,2)]
GL.VIEW( GL.numbering(.05)((V,[VV, EV]),GL.COLORS[1]) );


# arrangement of input data
W = convert(Lar.Points, V')
cop_EV = Lar.coboundary_0(EV)
V, copEV, copFE = Lar.planar_arrangement(W, cop_EV)

# compute containment graph of components
bicon_comps = Lar.Arrangement.biconnected_components(copEV)

χ = Lar.euler_characteristic(V, copEV, copFE);
println("χ = $χ ⟹   $(χ == 2)");

# visualization of component graphs
EW = Lar.cop2lar(copEV)
W = convert(Lar.Points, V')
comps = [ GL.GLLines(W,EW[comp],GL.COLORS[(k-1)%12+1]) for (k,comp) in enumerate(bicon_comps) ];
GL.VIEW(comps);

# visualization of numbered arrangement
VV = [[k] for k=1:size(V,1)]
EV = Lar.cop2lar(copEV);
FE = Lar.cop2lar(copFE);
# FV = cat([[EV[e] for e in face] for face in FE])

# final solid visualization
triangulated_faces = Lar.triangulate2D(V, [copEV, copFE])
V = convert(Lar.Points, V')
FVs = convert(Array{Lar.Cells}, triangulated_faces)
GL.VIEW(GL.GLExplode(V,FVs,1.2,1.2,1.2,99,1));

# polygonal face boundaries
EVs = Lar.FV2EVs(copEV, copFE)
EVs = convert(Array{Array{Array{Int64,1},1},1}, EVs)
GL.VIEW(GL.GLExplode(V,EVs,1.2,1.2,1.2,1,1));
