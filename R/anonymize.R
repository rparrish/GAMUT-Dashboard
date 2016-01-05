#'
#' anonymize
#'
#' recodes a list of factors to a number from 100 to 999
#'
#' @param x a list of factors
#' @return a list of numbers
#' @author Rollie Parrish
#' @export

anonymize <- function(x) {
  set.seed(42)

  if(is.factor(x)) {
    new.ID <- sample(seq(from=100, to=100+length(levels(x))), length(levels(x)))
#      new.ID <- sample(1:length(x), length(x))

  }
#  return(LETTERS[new.ID])
    return(new.ID)
}

