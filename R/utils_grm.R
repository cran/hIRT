# check if a vector has at least two valid responses
invalid_grm <- function(x) max(x, na.rm = TRUE) < 2

lrm_fit <- function(x, y, weights, tol = 1e-16, ...){
  lrm.fit(x[weights>tol], y[weights>tol], weights = weights[weights>tol], ...)
}

# log likelihood function (return N * J matrix) y: N*J data frame alpha:
# length J list beta: length J numeric vector theta: length N numeric
# vector
loglik_grm <- function(alpha, beta, theta) {
    util <- outer(theta, beta)
    alpha_l <- simplify2array(unname(Map(function(x, y) x[y], alpha, y)))
    alpha_h <- simplify2array(unname(Map(function(x, y) x[y + 1L], alpha, y)))
    log(plogis(util + alpha_l) - plogis(util + alpha_h))
}

# posterior of theta (unnormalized) (returns N-vector)
# y: N*J data frame
# x: N*p model matrix
# z: N*q model matrix
# alpha: length J list
# beta: length J numeric vector
# gamma: p-vector
# lambda: q-vector
# theta_k: numeric scalar
# qw_k numeric scalar
theta_post_grm <- function(theta_k, qw_k) {
    wt_k <- dnorm(theta_k - fitted_mean, sd = sqrt(fitted_var)) * qw_k  # prior density * quadrature weight
    loglik <- rowSums(loglik_grm(alpha, beta, rep(theta_k, N)), na.rm = TRUE)
    logPop <- log(wt_k)
    exp(loglik + logPop)
}

theta_prior_grm <- function(theta_k, qw_k) {
  wt_k <- dnorm(theta_k - fitted_mean, sd = sqrt(fitted_var)) * qw_k  # prior density * quadrature weight
  # loglik <- rowSums(loglik_grm(alpha, beta, rep(theta_k, N)), na.rm = TRUE)
  logPop <- log(wt_k)
  exp(logPop)
}

# pseudo tabulated data for item J (returns K*H_j matrix)
# y_j: N-vector
# H_j: number of response categories for item j
# w: K*N matrix
dummy_fun_grm <- function(y_j, H_j) {
    dummy_mat <- outer(y_j, 1:H_j, "==")  # N*H_j matrix
    dummy_mat[is.na(dummy_mat)] <- 0
    w %*% dummy_mat
}

# pseudo tabulated data to pseudo data frame
# tab: K*H_j matrix
# theta_ls: K-vector
tab2df_grm <- function(tab, theta_ls) {
    H_j <- ncol(tab)
    theta <- rep(theta_ls, H_j)
    y <- rep(1:H_j, each = K)
    data.frame(y = factor(y), x = theta, wt = as.double(tab))
}

# score function of alpha and beta (return a H_j*N matrix) Lik: N*K
# matrix pik: N*K matrix alpha: J-list beta: J-vector theta_ls: K-vector
sj_ab_grm <- function(j) {
    temp2 <- array(0, c(N, K, H[[j]] + 1))
    h <- .subset2(y, j)
    drv_h <- vapply(theta_ls, function(theta_k) exp(alpha[[j]][h] + beta[[j]] *
        theta_k)/(1 + exp(alpha[[j]][h] + beta[[j]] * theta_k))^2, double(N))
    drv_h_plus_one <- -vapply(theta_ls, function(theta_k) exp(alpha[[j]][h +
        1L] + beta[[j]] * theta_k)/(1 + exp(alpha[[j]][h + 1L] + beta[[j]] *
        theta_k))^2, double(N))
    drv_h[h == 1, ] <- 0
    drv_h_plus_one[h == H[[j]], ] <- 0
    for (i in seq_len(N)) {
        if (is.na(h[[i]])) next
        temp2[i, , h[[i]]] <- drv_h[i, ]
        temp2[i, , h[[i]] + 1L] <- drv_h_plus_one[i, ]
    }
    comp_a <- pik * Lik/vapply(Lijk, `[`, 1:N, j, FUN.VALUE = double(N))  # N*K matrix
    comp_a[is.na(comp_a)] <- 0
    s_alpha <- vapply(1:N, function(i) comp_a[i, ] %*% temp2[i, , 2:H[[j]]],
        double(H[[j]] - 1L))  # (H[j]-1)*N matrix
    temp2_beta <- drv_h + drv_h_plus_one
    s_beta <- rowSums(comp_a * matrix(theta_ls, N, K, byrow = TRUE) * temp2_beta)  # N-vector
    s <- sweep(rbind(s_alpha, s_beta), 2, rowSums(Lik * pik), FUN = "/")
}
