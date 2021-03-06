#' Estimates of Latent Preferences/Abilities
#'
#' EAP estimates of latent preferences for either \code{hltm} or \code{hgrm} models.
#'
#' @inheritParams print.hIRT
#'
#' @return A data frame of EAP estimates of latent preferences and their approximate standard errors.
#' @export
#' @examples
#' y <- nes_econ2008[, -(1:3)]
#' x <- model.matrix( ~ party * educ, nes_econ2008)
#' z <- model.matrix( ~ party, nes_econ2008)
#' nes_m1 <- hgrm(y, x, z)
#' pref <- latent_scores(nes_m1)
#' require(ggplot2)
#' ggplot(data = nes_econ2008) +
#' geom_density(aes(x = pref$post_mean, col = party))
latent_scores <- function(x, digits = 3) {
    if (!inherits(x, "hIRT"))
      stop("Use only with 'hIRT' objects.\n")
    round(x[["scores"]], digits)
}

