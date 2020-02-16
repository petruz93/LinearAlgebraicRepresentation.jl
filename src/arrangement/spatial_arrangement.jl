Lar = LinearAlgebraicRepresentation

"""
	frag_face_channel(in_chan, out_chan, V, EV, FE, sp_idx)

Parallel fragmentation of faces in `FE` against faces in `sp_idx`.
"""
function frag_face_channel(in_chan, out_chan, V, EV, FE, sp_idx)
    run_loop = true
    while run_loop
        sigma = take!(in_chan)
        if sigma != -1
            put!(out_chan, frag_face(V, EV, FE, sp_idx, sigma))
        else
            run_loop = false
        end
    end
end



"""
	frag_face(V, EV, FE, sp_idx, sigma)

`sigma` face fragmentation against faces in `sp_idx[sigma]`
"""
function frag_face(V, EV, FE, sp_idx, sigma)

    vs_num = size(V, 1) # V by rows

	# 2D transformation of sigma face
    sigmavs = (abs.(FE[sigma:sigma,:])*abs.(EV))[1,:].nzind
    sV = V[sigmavs, :]
    sEV = EV[FE[sigma, :].nzind, sigmavs]
    M = Lar.Arrangement.submanifold_mapping(sV)
    tV = ([V ones(vs_num)]*M)[:, 1:3]  # folle convertire *tutti* i vertici
    sV = tV[sigmavs, :]
    # sigma face intersection with faces in sp_idx[sigma]
    for i in sp_idx[sigma]
        tmpV, tmpEV = Lar.Arrangement.face_int(tV, EV, FE[i, :])

        sV, sEV = Lar.skel_merge(sV, sEV, tmpV, tmpEV)
    end

    # computation of 2D arrangement of sigma face
    sV = sV[:, 1:2]
    nV, nEV, nFE = planar_arrangement(sV, sEV, sparsevec(ones(Int8, length(sigmavs))))
    if nV == nothing ## not possible !! ... (each original face maps to its decomposition)
        return [], spzeros(Int8, 0,0), spzeros(Int8, 0,0)
    end
    nvsize = size(nV, 1)
    nV = [nV zeros(nvsize) ones(nvsize)]*inv(M)[:, 1:3] ## ????
    return nV, nEV, nFE
end


function merge_vertices(V::Lar.Points, EV::Lar.ChainOp, FE::Lar.ChainOp, err=1e-4)
    vertsnum = size(V, 1)
    edgenum = size(EV, 1)
    facenum = size(FE, 1)
    newverts = zeros(Int, vertsnum)
    # KDTree constructor needs an explicit array of Float64
    V = Array{Float64,2}(V)
    W = convert(Lar.Points, LinearAlgebra.transpose(V))
    kdtree = KDTree(W)
	# remove vertices congruent to a single representative
    todelete = []
    i = 1
    for vi in 1:vertsnum
        if !(vi in todelete)
            nearvs = Lar.inrange(kdtree, V[vi, :], err)
            newverts[nearvs] .= i
            nearvs = setdiff(nearvs, vi)
            todelete = union(todelete, nearvs)
            i = i + 1
        end
    end
    nV = V[setdiff(collect(1:vertsnum), todelete), :]

    # translate edges to take congruence into account
    edges = Array{Tuple{Int, Int}, 1}(undef, edgenum)
    oedges = Array{Tuple{Int, Int}, 1}(undef, edgenum)
    for ei in 1:edgenum
        v1, v2 = EV[ei, :].nzind
        edges[ei] = Tuple{Int, Int}(sort([newverts[v1], newverts[v2]]))
        oedges[ei] = Tuple{Int, Int}(sort([v1, v2]))
    end
    nedges = union(edges)
    # remove edges of zero length
    nedges = filter(t->t[1]!=t[2], nedges)
    nedgenum = length(nedges)
    nEV = spzeros(Int8, nedgenum, size(nV, 1))

    etuple2idx = Dict{Tuple{Int, Int}, Int}()
    for ei in 1:nedgenum
    	begin
        	nEV[ei, collect(nedges[ei])] .= 1
        	nEV
        end
        etuple2idx[nedges[ei]] = ei
    end
    for e in 1:nedgenum
    	v1,v2 = findnz(nEV[e,:])[1]
    	nEV[e,v1] = -1; nEV[e,v2] = 1
    end

    # compute new faces to take congruence into account
    faces = [[
        map(x->newverts[x], FE[fi, ei] > 0 ? oedges[ei] : reverse(oedges[ei]))
        for ei in FE[fi, :].nzind
    ] for fi in 1:facenum]


    visited = []
    function filter_fn(face)

        verts = []
        map(e->verts = union(verts, collect(e)), face)
        verts = Set(verts)

        if !(verts in visited)
            push!(visited, verts)
            return true
        end
        return false
    end

    nfaces = filter(filter_fn, faces)

    nfacenum = length(nfaces)
    nFE = spzeros(Int8, nfacenum, size(nEV, 1))

    for fi in 1:nfacenum
        for edge in nfaces[fi]
            ei = etuple2idx[Tuple{Int, Int}(sort(collect(edge)))]
            nFE[fi, ei] = sign(edge[2] - edge[1])
        end
    end

    return Lar.Points(nV), nEV, nFE
end

function spatial_arrangement_1(
		V::Lar.Points, # by rows
		copEV::Lar.ChainOp,
		copFE::Lar.ChainOp, multiproc::Bool=false)

	# spaceindex computation
	FV = Lar.compute_FV( copEV, copFE )
	model = (convert(Lar.Points,V'), FV)
	sp_idx = Lar.spaceindex(model)

	# initializations
    fs_num = size(copFE, 1)
    rV = Array{Float64,2}(undef,0,3)
    rEV = SparseArrays.spzeros(Int8,0,0)
    rFE = SparseArrays.spzeros(Int8,0,0)

	# multiprocessing of face fragmentation
    if (multiproc == true)
        in_chan = Distributed.RemoteChannel(()->Channel{Int64}(0))
        out_chan = Distributed.RemoteChannel(()->Channel{Tuple}(0))
        @async begin
            for sigma in 1:fs_num
                put!(in_chan, sigma)
            end
            for p in Distributed.workers()
                put!(in_chan, -1)
            end
        end
        for p in Distributed.workers()
            @async Base.remote_do(
                frag_face_channel, p, in_chan, out_chan, V, EV, FE, sp_idx)
        end
        for sigma in 1:fs_num
            rV, rEV, rFE = Lar.skel_merge(rV, rEV, rFE, take!(out_chan)...)
        end
    else
	# sequential (iterative) processing of face fragmentation
        for sigma in 1:fs_num
            #print(sigma, "/", fs_num, "\r")
            nV, nEV, nFE = Lar.Arrangement.frag_face(V, copEV, copFE, sp_idx, sigma)
			#nV, nEV, nFE = Lar.fragface(V, copEV, copFE, sp_idx, sigma)
			nV = convert(Lar.Points, nV)
            a,b,c = Lar.skel_merge( rV,rEV,rFE,  nV,nEV,nFE )
            rV=a;  rEV=b;  rFE=c
        end
    end
	# merging of close vertices, edges and faces (3D congruence)
	rV, rEV, rFE = merge_vertices(rV, rEV, rFE)
    return rV, rEV, rFE
end


function spatial_arrangement_2(
		rV::Lar.Points,
		rcopEV::Lar.ChainOp,
		rcopFE::Lar.ChainOp, multiproc::Bool=false)

	#rcopCF = Lar.build_copFC(rV, rcopEV, rcopFE)
	rcopCF = minimal_3cycles(rV, rcopEV, rcopFE)
    return rV, rcopEV, rcopFE, rcopCF
end




"""
    spatial_arrangement(V::Points, copEV::ChainOp, copFE::ChainOp; [multiproc::Bool])

Compute the arrangement on the given cellular complex 2-skeleton in 3D.

A cellular complex is arranged when the intersection of every possible pair of cell
of the complex is empty and the union of all the cells is the whole Euclidean space.
The function returns the full arranged complex as a list of vertices V and a chain of borders EV, FE, CF.

## Additional arguments:
- `multiproc::Bool`: Runs the computation in parallel mode. Defaults to `false`.
"""
function spatial_arrangement(
		V::Lar.Points, # by rows
		copEV::Lar.ChainOp,
		copFE::Lar.ChainOp, multiproc::Bool=false)

	# face subdivision
	rV, rcopEV, rcopFE = Lar.Arrangement.spatial_arrangement_1( V, copEV, copFE, multiproc ) # copFE global
	#@show rV; @show findnz(rcopEV); @show findnz(rcopFE);

	bicon_comps = Lar.Arrangement.biconnected_components(rcopEV)
	# W,bicon_comps = Lar.biconnectedComponent((W,EV))
	#@error "comps# = $(length(bicon_comps))"
	check_single_non_zero_CSC(rcopFE)

	# 3-complex and containment graph
	# ricostruzione delle 3-celle
	rV, rEV, rFE, rCF = Lar.Arrangement.spatial_arrangement_2(rV, rcopEV, rcopFE)
end


function check_single_non_zero_CSC(A::SparseMatrixCSC)
	sleep_time = 5 # seconds
	temp = 0
	result = []
	for i in 1:size(A,2)
		push!(result, temp)
		temp = 0
		for j in 1:size(A,1)
			temp += abs(A[j,i])
		end
		# println(temp)	# show column sums
	end
	count = 0
	for k in result
		if k == 1
			count += 1
		end
	end
	if count != 0
		println("//////////////////////////////////////////////////////////////////////////////////////////////////////////")
		println("CHECKING SINGLE NON ZERO ELEMENT")
		println("WARNING, THE MATRIX CONTAINS $count COLUMN WITH A SINGLE NON ZERO ELEMENT")
		println("the execution will sleep for $sleep_time seconds")
		sleep(sleep_time)
		println("//////////////////////////////////////////////////////////////////////////////////////////////////////////")
	end
end
