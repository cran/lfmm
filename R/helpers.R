## @export
impute_median <- function(Y) {
  n <- nrow(Y)
  p <- ncol(Y)
  missing.index <- which(is.na(Y))
  meds <- apply(Y, 2, stats::median, na.rm = TRUE) 
  Y[missing.index] <- (matrix(1,n,1) %*% matrix(meds,1,p))[missing.index] ## :-(
  Y
}
## @export
compute_B_ridge <- function(A, X, lambda) {
  D <- diag(1, ncol(X), ncol(X))
  if (is.matrix(A)) {
    t(solve((crossprod(X,X) + lambda * D), crossprod(X, A)))
  } else if(is.function(A)) {
    D <- diag(1, ncol(X), ncol(X))
    t(solve((crossprod(X, X) + lambda * D), A(X)))
  }
}
## @export
compute_B_lasso <- function(A, X, lambda) {
  B_hat <- compute_B_ridge(A, X, 0.0)
  sign(B_hat) * sapply((abs(B_hat) - lambda), function(x) max(0,x))
}

# score are assume to follow student distibution with df degre of freedom
compute_pvalue_from_tscore <- function(score, df) {
  apply(score, 1:2, function(z) 2 * stats::pt(abs(z), df = df, lower.tail = FALSE))
}

# score are assume to follow normal distibution
compute_pvalue_from_zscore <- function(score, mean = 0, sd = 1) {
  apply(score, 1:2, function(z) 2 * stats::pnorm(abs(z), mean = mean, sd = sd, lower.tail = FALSE))
}

compute_pvalue_from_zscore2 <- function(score2, df = 1) {
  apply(score2, 1:2, function(z) stats::pchisq(z, lower.tail = FALSE, df = df))
}

compute_gif <- function(score) {
  score2 <- score ^ 2
  apply(score2, 2, stats::median, na.rm = TRUE) / stats::qchisq(0.5, df = 1)
}

compute_svd <- function(Af, Atransf,k, nu, nv, dim, opts = list(tol = 10e-10)) {
  RSpectra::svds(A = Af,
                 Atrans = Atransf,
                 k = k,
                 nu = nu, nv = nv,
                 opts = opts,
                 dim = dim)
}

compute_svd_soft <- function(Af, Atransf, gamma, k, dim, opts = list(tol = 10e-10)) {
  svd.res <- RSpectra::svds(A = Af,
                            Atrans = Atransf,
                            k = k + 2, ## mouais...
                            nu = k + 2, nv = k + 2,
                            opts = opts,
                            dim = dim)
  svd.res$d <- svd.res$d - gamma
  svd.res$d <- svd.res$d[svd.res$d > 0.0]
  K <- length(svd.res$d)
  if (K > k) {
    warning("K is increasing, now K = ", K)
  }
  if (K > (k + 2) || K <= 0.0) {
    stop("K too big or too small, OMG, call 911 !!")
  }
  svd.res$u <-svd.res$u[,1:K] 
  svd.res$v <- svd.res$v[,1:K]
  svd.res
}

## Compute the matrix used to reduce correlation with X
compute_P <- function(X, lambda) {

  ## param
  d <- ncol(X)
  n <- nrow(X)

  res <- list()
  svd.res <- compute_eigen_svd(X)

  D1 <- diag(1, n, n)

  diag(D1)[1:d] <- sqrt(lambda / (lambda + svd.res$sigma))

  D1.inv <- D1
  diag(D1.inv) <- 1 / diag(D1.inv)

  res$sqrt.P <- tcrossprod(D1, svd.res$Q)
  res$sqrt.P.inv <- svd.res$Q %*% D1.inv

  res
}
