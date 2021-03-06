#' @include panelPomp-internal.R
NULL

### coef method for panelPomp signature
#' Extract coefficients from the \code{pParams} slot of \code{panelPomp} objects.
#'
#' What do I do?
#'
#' S4 method.
#'
#' @param object A \code{panelPomp} object.
#'
#' @export
#'
setMethod(
  f = "coef",
  signature = signature(object = "panelPomp"),
  definition = function(object) {object@pParams}
)# END setMethod



### length method for panelPomp signature
#' Count the number of units in the \code{unitobjects} slot of \code{panelPomp} objects.
#'
#' Help me!
#'
#' S4 method.
#'
# Can't @inheritParams coef because coef's argument is "object" not "x" (which is length's argument)
#' @param x A \code{panelPomp} object.
#'
#' @export
#'
setMethod(
  f = "length",
  signature = signature(x = "panelPomp"),
  definition = function(x) {
    length(unitobjects(object = x))
  }
)# END setMethod




### mif2 method for panelPomp signature
#' Apply the \code{mif2} algorithm to a \code{panelPomp} object.
#'
#' Mystery of mysteries
#'
#' S4 method.
#'
#' @inheritParams coef,panelPomp-method 
#' @inheritParams pomp::mif2
#' @param shared.start shared.arg.
#' @param specific.start specific.arg.
#' @param rw.sd An unevaluated expression of the form \code{quote(rw.sd())} to be used for all panel units. If a \code{list} of such expressions of the same length as the \code{object} argument is provided, each list element will be used for the corresponding panel unit.
#' @param cooling.fraction.50 cooling.fraction.50 (seems to cause an error if documentation inherited from 'pomp' package)
#' @param transform transform (seems to cause an error if documentation inherited from 'pomp' package)
#'
#' @export
#'
setMethod(
  f = "mif2",
  signature = signature(object = "panelPomp"),
  definition = function(object,
                        shared.start,
                        specific.start,
                        Np,
                        Nmif = 1,
                        cooling.type = c("hyperbolic", "geometric"),
                        cooling.fraction.50,
                        transform = FALSE,
                        rw.sd,
                        verbose = getOption("verbose"),
                        ...) {
    
    ep <- paste0(sQuote("panelPomp::mif2")," error: ")
    
    # If no starting values are specified, try using the pParams slot
    if (missing(shared.start)) shared.start <- coef(object)$shared
    if (missing(specific.start)) specific.start <- coef(object)$specific
    
    if (is.null(shared.start)){
      stop(ep, "non-empty ", sQuote("shared.start"), " must be specified if ", 
           sQuote("coef(object)$shared")," is empty.", call.=FALSE)
    }
    if (is.null(nrow(specific.start))){
      stop(ep, "non-empty ", sQuote("specific.start"), " must be specified if ", 
           sQuote("coef(object)$specific")," is empty.", call.=FALSE)
    }
    # If the pParams slot is not empty, check that the shared and specific structure of any 
    # provided starting values match the pParams slot
    if (!is.null(coef(object)$shared)){
      if (
        !identical(character(0), setdiff(x = names(coef(object)$shared), y = names(shared.start)))
        &
        !(is.null(names(coef(object)$shared)) & is.null(names(shared.start)))
      ){
        stop(ep, "names of ", sQuote("shared.start"), " must match those of ", 
             sQuote("coef(object)$shared"),".", call.=FALSE
        )
      }
    }
    if (!is.null(coef(object)$specific)){
      if (
        !identical(character(0), setdiff(x = rownames(coef(object)$specific), y = rownames(specific.start)))
        &
        !(is.null(rownames(coef(object)$specific)) & is.null(rownames(specific.start)))
      ){
        stop(ep, "rownames of ", sQuote("specific.start"), " must match those of ", 
             sQuote("coef(object)$specific"),".", call.=FALSE
        )
      }
      if (!identical(x = colnames(coef(object)$specific), y = colnames(specific.start))){
        stop(ep, "colnames of ", sQuote("specific"), " must be identical to those of ", 
             sQuote("coef(object)$specific"),".", call.=FALSE
        )
      }
    }
    
    if (missing(Np)) {
      stop("Missing 'Np' argument.")
    }
    if (missing(cooling.fraction.50)) {
      stop("Missing 'cooling.fraction.50' argument.")
    }
    if (missing(rw.sd)) {
      stop(ep,"missing ",sQuote("rw.sd")," argument.",call.=FALSE)
    }
    # Check that all parameters in the pomp objects have been provided either as shared or specific ...
    if(!all(names(coef(unitobjects(object)[[1]])) %in% c(names(shared.start), rownames(specific.start)))) 
      stop("At least one 'pomp' parameter needs to be added to the (shared. or specific.) start argument")
    # ... and viceversa.
    if(!all(c(names(shared.start), rownames(specific.start))  %in% names(coef(unitobjects(object)[[1]]))))
      stop("At least one parameter in the (shared. or specific.) start argument is not being used")
    pmif2.internal(
      object,
      pstart = list(shared = shared.start, specific = specific.start),
      Np = Np,
      Nmif = Nmif,
      cooling.type = cooling.type,
      cooling.fraction.50 = cooling.fraction.50,
      transform = transform,
      prw.sd = rw.sd,
      ...
    )# END CALL pmif2.internal
  } # END FN definition arg
) # END setMethod




### pfilter method for panelPomp signature
#' Apply a particle filter to \code{panelPomp} objects.
#'
#' S4 method.
#'
#' S4 method.
#'
#' @inheritParams coef,panelPomp-method 
#' @inheritParams panelPomp,list-method
#' @inheritParams pomp::mif2
#' @param tol unit-specific filtering tolerances.  Can be a scalar or a named numeric vector with names matching \code{names(unitobjects(object))}.
#' @param ... additional arguments, passed to the \code{pfilter} method of \pkg{pomp}.
#' @export
#'
setMethod(
  f = "pfilter",
  signature = signature(object = "panelPomp"),
  definition =
    function(object,
             shared,
             specific,
             Np,
             tol,
             verbose = getOption("verbose"),
             ...) {
      
      ep <- paste0("in ",sQuote("panelPomp::pfilter"),": ")
      
      # If no starting values are specified, try using the pParams slot
      if (missing(shared)) shared <- coef(object)$shared
      if (missing(specific)) specific <- coef(object)$specific
      
      if (is.null(shared)){
        stop(ep, "non-empty ", sQuote("shared"), " must be specified if ", 
             sQuote("coef(object)$shared")," is empty.", call.=FALSE)
      }
      if (is.null(nrow(specific))){
        stop(ep, "non-empty ", sQuote("specific"), " must be specified if ", 
             sQuote("coef(object)$specific")," is empty.", call.=FALSE)
      }
      # If the pParams slot is not empty, check that the shared and specific structure of any 
      # provided starting values match the pParams slot
      if (!is.null(coef(object)$shared)){
        if (
          !identical(character(0), setdiff(x = names(coef(object)$shared), y = names(shared)))
          &
          !(is.null(names(coef(object)$shared)) & is.null(names(shared)))
        ){
          stop(ep, "names of ", sQuote("shared"), " must match those of ", 
            sQuote("coef(object)$shared"),".", call.=FALSE
          )
        }
      }
      if (!is.null(coef(object)$specific)){
        if (
          !identical(character(0), setdiff(x = rownames(coef(object)$specific), y = rownames(specific)))
          &
          !(is.null(rownames(coef(object)$specific)) & is.null(rownames(specific)))
        ){
          stop(ep, "rownames of ", sQuote("specific"), " must match those of ", 
            sQuote("coef(object)$specific"),".", call.=FALSE
          )
        }
        if (!identical(x = colnames(coef(object)$specific), y = colnames(specific))){
          stop(ep, "colnames of ", sQuote("specific"), " must be identical to those of ", 
            sQuote("coef(object)$specific"),".", call.=FALSE
          )
        }
      }
      if (missing(Np)) {
        stop(ep, "Missing 'Np' argument.")
      }
      # Check that all parameters in the pomp objects have been provided either as shared or specific ...
      if(!all(names(coef(unitobjects(object)[[1]])) %in% c(names(shared), rownames(specific)))) 
        stop(ep, "At least one 'pomp' parameter needs to be added to the (shared. or specific.) 
             start argument.")
      # ... and viceversa.
      if(!all(c(names(shared), rownames(specific))  %in% names(coef(unitobjects(object)[[1]]))))
        stop(ep, "At least one parameter in the (shared. or specific.) start argument is not 
             being used.")
      
        pPfilter.internal(
          object = object,
          params = list(shared = shared, specific = specific),
          Np = Np,
          verbose = verbose,
          ...
        )
      }
) # END setMethod




### unitobjects method for panelPomp signature
#' Extract individual \code{pomp} objects from \code{panelPomp} objects.
#'
#' S4 method
#'
#' S4 method.
#'
#' @param object A \code{panelPomp} object.
#' @param unitname unitname.
#'
#' @export
#'
setMethod(
  f = "unitobjects",
  signature = signature(object = "panelPomp"),
  definition = function(object,
                        unitname) {
    if (missing(unitname)) {
      return(object@unit.objects)
    } else {
      return(object@unit.objects[unitname][[1]])
    }
  }
)# END setMethod
