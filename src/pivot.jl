"""
x = nnls(A, b; ...)

Solves non-negative least-squares problem by block principal pivoting method 
(Algorithm 1) described in Kim & Park (2011).

Optional arguments:
    tol: tolerance for nonnegativity constraints
    max_iter: maximum number of iterations

References:
	J. Kim and H. Park, Fast nonnegative matrix factorization: An
	active-set-like method and comparisons, SIAM J. Sci. Comput., 33 (2011),
	pp. 3261–3281.
"""
function pivot_nnls(C::Matrix{Float64},
                    b::Vector{Float64};
                    tol::Float64=1e-8,
                    max_iter=30*size(C,2))


    # dimensions, initialize solution
    p,q = size(C)
    x = zeros(q) # primal variables
    y = -C'*b    # dual variables

    # parameters for swapping
    α = 3
    β = q+1

    # Divide elements into two sets
    F = zeros(Bool,q) # we want y[F] == 0, x[F] >= 0
    G = ones(Bool,q)  # we want x[G] == 0, y[G] >= 0


    x[F] =  C[:,F] \ b
    y[G] =  C[:,G]' * (C[:,F]*x[F] - b)

 #    println(round(x',2))
	# println(round(y',2))
	# println(round(Int,F))
	# println(round(Int,G))
	# println(round(Int,(F & (x.<-tol)) | (G & (y.<-tol))))
	# println("****")
	# sleep(1)

    # while infeasible
    while any(x[F] .< -tol) || any(y[G] .< -tol)

    	# identify infeasible variables
    	V = (F & (x .< -tol)) | (G & (y .< -tol))
    	nV = sum(V)

    	if nV < β
    		# infeasible variables decreased
    		β = nV  # store number of infeasible variables
    		α = 3   # reset α
    	else
    		# infeasible variables stayed the same or increased
    		if α >= 1
    			α = α-1 # tolerate increases for α cycles
    		else
    			# backup rule
    			i = findlast(V)
    			V = zeros(Bool,q)
    			V[i] = true
    		end
    	end

    	# update partition of variables
		V_and_G = V & G # infeasible variables in set G (move to F)
		V_and_F = V & F # infeasible variables in set F (move to G)
		notV = ~V
		F = (F & notV) | V_and_G
		G = (G & notV) | V_and_F

		# update primal/dual variables
		x[F] =  C[:,F] \ b
		y[G] =  C[:,G]' * ((C[:,F]*x[F]) - b)

		# println(round(x',2))
		# println(round(y',2))
		# println(round(Int,F))
		# println(round(Int,G))
		# println(round(Int,(F & (x .< -tol)) | (G & (y .< -tol))))
		# println("****")
		# sleep(1)
    end

    x[~F] = 0.0
    return x
end
