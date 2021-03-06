% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rc9.R
\name{rc9}
\alias{rc9}
\title{Generate a Rogers-Castro nine-parameter migration schedule}
\usage{
rc9(x, param = NULL, scaled = TRUE)
}
\arguments{
\item{x}{Vector of numbers}

\item{param}{List with names matching the parameters in the age schedule}

\item{scaled}{Scale estimates to sum to one across all ages, x.}
}
\value{
Returns the M(x) values from the Rogers-Castro schedule of age specific migration rate. The age range for the calculation can take any sequence of positive numbers, such as ages in single or 5-year intervals. The \code{param} argument must be a list with correct names for each parameter. See for example the \code{\link{rc9.fund}} object for an example of the naming convention.
}
\description{
Provides the Rogers-Castro schedule,
\deqn{ M(x) = a_{1} \exp[-\alpha_{1}x] + a_{2} \exp [ \alpha_{2}(x-\mu_{2})- \exp [ \lambda_{2}(x-\mu_{2}) ] ] +c}
for a given set of parameters and ages.
}
\examples{
# single age groups
x <- 1:100
m <- rc9(x, param = rc9.fund)
plot(x, m, type="l")

# 5 year age groups
m <- rc9(x, param = rc9.fund)
plot(x, m, type="l")
}
\references{
Rogers, A., and L. J. Castro. (1981). Model Migration Schedules. \emph{IIASA Research Report 81} RR-81-30
}
\seealso{
\code{\link{rc9.fund}}
}
\author{
Guy J. Abel
}
