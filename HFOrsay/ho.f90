!> Harmonic oscillator module
module ho
contains
!> Compute the radial wave-function of an HO
!> \param n principal quantum number
!> \param l orbital quantum number
!> \param r space point 
function ho_rad_wf(n,l,r) result(wf)
use maths
use constants
use lag_pol
implicit none
integer,intent(in)::n,l
double precision,intent(in)::r
double precision::wf,norm,nnorm,expf,xi,clag
xi = r/bosc
norm=dsqrt(2**(n+l+2)*fac(n)/(dsqrt(pi)*ffac(2*n+2*l+1)))
nnorm=norm/bosc**(3.d0/2.d0)
expf = exp(-(xi**2)*0.5d0)
clag = laguerre(n,dble(l+half),xi**2)
wf = nnorm*xi**l*clag*expf
end function ho_rad_wf
!> A function computing only the norm for a radial HO
!> \param n principal quantum number
!> \param l orbital quantum number
function ho_norm(n,l) result(norm)
use maths
use constants
implicit none
double precision::norm,l
integer::n
norm=dsqrt(2**(n+l+2)*fac(n)/(dsqrt(pi)*ffac(2*n+int(2*l)+1)))
end function
end module ho
