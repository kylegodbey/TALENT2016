subroutine solve_BCS_equation(L,E_data,N,E_tot, lambda, delta)
implicit none

complex(8),parameter :: zI=(0d0,1d0) ! unit of imaginary part
integer,parameter :: Nm_iter=100
real(8) :: lambda, dN, Delta, E_tot, E_int, S_p, E_data
real(8) x1, lambda_old
complex(8),allocatable :: u(:), v(:), v_old(:), dv(:), f(:), dfdv(:,:)
integer :: N, i, j, i1, i2, i_c, Nm, Nm_rep, rep, err, v_err, gap_zero   ! N:particle number

! initial setting of the system***************
real(8) :: g
integer :: L, N_from, N_to
integer,allocatable :: Omg(:), nu(:)
real(8),allocatable :: eps(:)
NAMELIST / coupling_constant / g
NAMELIST / number_of_shells / L
NAMELIST / number_from_to / N_from, N_to
NAMELIST / shell_energy / eps
NAMELIST / shell_capacity / Omg, nu

open(30,file='epsilon.txt',status='old')
read(30,NML=coupling_constant)
read(30,NML=number_of_shells)
read(30,NML=number_from_to)

allocate(Omg(1:L),nu(1:L),eps(1:L))

read(30,NML=shell_energy)
read(30,NML=shell_capacity)
close(30)
!**********************************************
Nm = sum(Omg)
write(*,*) Nm, 'L=', L

open(20,file='result.dat')
write(20,'(10a15)') 'coupling const', 'number', 'uncertainty', 'chemical_pot', 'total energy', &
     'interaction', 'pairing gap', 'S_+ or S_-'
open(10,file='occ.dat')

do N=N_from,N_to,2
!N = N_from
!do rep=0,100
!   g = 0.2d0 - 0.002d0*rep
   gap_zero = 0
   write(10,'(a2,I2)') 'N=', N
   allocate(u(1:L), v(1:L), v_old(1:L), dv(1:L+1),&
        f(1:L+1), dfdv(1:L+1,1:L+1))

   call random

   do ! until converge

! decide the level i_c near the Fermi surface and minimum of Delta
  do i=1,L
      if (N-nint(2d0*sum(Omg(1:i))-sum(nu(1:i))) <= 0) then
         i_c = i
         exit 
      end if
   end do

! initialization
      do i=1,i_c
         if (i==1) then
            call random_number(x1)
            v(i) = 0.1d0*x1 + 0.9d0
         else
            v(i) = (v(i-1)-0.9d0)*x1 + 0.9d0
         end if
      end do
      do i=i_c,L
         if (i==i_c) then
            call random_number(x1)
            v(i) = 0.1d0*x1
         else
            v(i) = v(i-1)*x1
         end if
      end do
      call random_number(x1)
      v(i_c) = 0.8d0*x1+0.1d0

!      do i=1,L
!         call random_number(x1)
!         if (i==1) then
!            v(i) = x1
!         else
!            v(i) = v(i-1)*x1
!         end if
!      end do
      lambda = eps(L) - (eps(L)-eps(1))*x1
      
      do Nm_rep=1,Nm_iter
!   write(*,'(a10,f15.8)') 'lambda=', lambda
! set f(v_1,...,v_L), dfdE(v_1,...,v_L)
         do i=1,L
            f(i) = 2d0*(eps(i)-lambda-g*v(i)**2)*v(i)*sqrt(1-v(i)**2) &
                 + g*(2d0*v(i)**2-1)*sum((Omg(:)-nu(:))*sqrt(1-v(:)**2)*v(:))
         end do
         f(L+1) = 2d0*sum((Omg(:)-nu(:))*v(:)**2) + sum(nu(:)) - N
         do i1=1,L
            do i2=1,L
               if (i1==i2) then
                  dfdv(i1,i2) = 2d0*(eps(i1)-lambda-g*v(i1)**2)*sqrt(1-v(i1)**2) &
                       - 2d0*(eps(i1)-lambda-g*v(i1)**2)*v(i1)**2/sqrt(1-v(i1)**2) &
                       + 4d0*g*v(i1)*sum((Omg(:)-nu(:))*sqrt(1-v(:)**2)*v(:)) &
                       + g*(2d0*v(i1)**2-1)*(Omg(i1)-nu(i1))*(sqrt(1-v(i1)**2)-v(i1)**2/sqrt(1-v(i1)**2))
               else
                  dfdv(i1,i2) = g*(2d0*v(i1)**2-1)*(Omg(i2)-nu(i2))*(sqrt(1-v(i2)**2)-v(i2)**2/sqrt(1-v(i2)**2))
               end if
            end do
         end do
         do i1=1,L
            dfdv(i1,L+1) = -2d0*v(i1)*sqrt(1-v(i1)**2)
         end do
         do i2=1,L
            dfdv(L+1,i2) = 4d0*(Omg(i2)-nu(i2))*v(i2)
         end do
         dfdv(L+1,L+1) = 0d0
! use LU method to solve df/dE * dE = -f
         f(:) = -f(:)
         call LU(L+1, dfdv, f, dv, err)

         v_old(:) = v(:)
         lambda_old = lambda
         do i=1,L
            v(i) = v_old(i) + dv(i)
         end do
         lambda = lambda_old + real(dv(L+1))
!      do i=1,L+1
!         write(*,'(a10,I3,a5,I2,a2,2f15.8)') 'iteration:', Nm_rep, 'dv(', i, ')=', dv(i)
!      end do
         if (abs(dv(L+1))/abs(lambda_old)<1e-6) exit   
      end do

! check result****************************************
      write(*,'(a3,i3)') 'N=', N
      do i=1,L+1
         write(*,'(a10,I3,a5,I2,a2,2f15.8)') 'iteration:', Nm_rep, 'v(', i, ')=', v(i)
      end do
      if (Nm_rep==Nm_iter+1) then
         write(*,*) 'Did not converge, repeat'
         cycle
      end if

      v(:) = abs(v(:))
      
      v_err = 0
      do i=1,L
         if (real(v(i))**2>1d0) then
            write(*,*) 'v**2>1, repeat'
            v_err = 1
         end if
      end do
      if (v_err==1) cycle
      
! calculate physical values
      u(:) = sqrt(1-v(:)**2)
      Delta = g*real(sum((Omg(:)-nu(:))*u(:)*v(:)))
! check gap equation
      if (abs(Delta-0.5d0*g*Delta*sum((Omg(:)-nu(:))/sqrt((eps(:)-lambda-g*v(:)**2)**2+Delta**2)))>1e-3) then
         write(*,*) 'wrong result'
         cycle
      end if
! gap/=0
      if (gap_zero==10) exit ! gap=0 is unique solution
      if (Delta<5e-6) then
         write(*,*) 'the case is gap=0'
         gap_zero = gap_zero + 1 
         cycle
      end if
!**************************************************

      if (abs(dv(L+1))/abs(lambda_old)<1e-6) exit  
   end do

! plot
   do i=1,L
      write (10,'(a4,I2,a2,10f15.8)') 'v(', i, ')=', v(i)**2
   end do
   dN = sqrt(4d0*real(sum((Omg(:)-nu(:))*u(:)**2*v(:)**2)))
   E_tot = 2d0*real(sum((Omg(:)-nu(:))*((eps(:)-g*v(:)**2)*v(:)**2+0.5d0*g*v(:)**4))) &
        - Delta**2/g + sum(eps(:)*nu(:))
   E_int = -1d0*real(sum((Omg(:)-nu(:))*g*v(:)**4)) - Delta**2/g
   S_p = real(sum((Omg(:)-nu(:))*u(:)*v(:)))
   write(20,'(f15.8,i15,10f15.8)') g, N, &
        dN, lambda, E_tot, E_int, Delta, S_p
   
   deallocate(u, v, v_old, dv, f, dfdv)
end do

deallocate(Omg,nu,eps)

close(10)
close(20)


end subroutine

subroutine random

  integer :: clock
  integer seedsize
  integer,allocatable:: seed(:)
  
  call random_seed(size=seedsize)
  allocate(seed(seedsize))
  call system_clock(count=clock)
  seed = clock  
  call random_seed(put=seed)
  
end subroutine random

