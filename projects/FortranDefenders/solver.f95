module solver
  use grid
  implicit none

contains

  subroutine solve
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! This subroutine is closely based on the notes provided by the organizers
    ! of the 2016 Density Functional Theory TALENT Course.
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    integer :: i, ir, nnodes
    real(wp) :: Etrial, Eupper, Elower, a1, a2, a3, norm
    real(wp), allocatable :: potential(:), test(:)
    logical :: sign

    allocate(potential(0:nbox),test(0:nbox))

    Eupper = 100000_wp
    Elower = -v0
    do i=1,1000000
      Etrial = (Eupper+Elower)/2.0
      ! Trying very large values right now, may change this if unstable

      ! = Etrial - Potential
      do ir=0,nbox
        potential(ir) = (-vpb*fullwoodsaxon(ir)+Etrial)/hbar22m
      end do

      wavefunctions(0,:,:,:) = 0.0
      wavefunctions(1,:,:,:) = 1.0
      do ir=1,nbox-1
        a1 = 2.0 * (1.0 - (5.0/12.0) * h**2 * potential(ir))
        a2 = (1.0 + (1.0/12.0) * h**2 * potential(ir-1))
        a3 = (1.0 + (1.0/12.0) * h**2 * potential(ir+1))

        wavefunctions(ir+1,:,:,:) = (a1*wavefunctions(ir,:,:,:) - a2*wavefunctions(ir-1,:,:,:))/a3
      end do
      nnodes = 0
      ! I believe this is appropriate logic for checking the sign change of the
      ! wavefunction
      sign = wavefunctions(1,0,1,1) > 0
      do ir =1,nbox
        if ((wavefunctions(ir,0,1,1) > 0) .NEQV. sign) then
          sign = wavefunctions(ir,0,1,1) > 0
          nnodes = nnodes + 1
        end if
      end do

      if (nnodes > nodes) then
        Eupper = Etrial
      else if (nnodes < nodes) then
        Elower = Etrial
      else
        ! This is a variation on the lower energy in order to "squeeze" the
        ! energies together. by moving it a small amount (arbitrarily here)
        ! we can force the solution to converge.
        Elower = Elower + 0.1
      end if

      if (abs(Eupper - Elower) < conv) then
        write (6,*) "Converged!"
        write (6,*) "|Eupper - Elower| =", abs(Eupper - Elower)
        write (6,*) "Energy =", Etrial
        write (6,*) "Exact Energy =",infwell_exact()
        write (6,*) "Difference between calculated and exact =",Etrial-infwell_exact()
        exit
      end if
    end do

    if (abs(Eupper - Elower) > conv) then
      write (6,*) "Program did not converge!"
      write (*,*) abs(Eupper - Elower)
    end if
    ! Normalisation
    norm = sqrt(sum(h*wavefunctions(:,0,1,1)*wavefunctions(:,0,1,1)))
    wavefunctions(:,0,1,1) = wavefunctions(:,0,1,1)/norm

    ! Printing points for plotting. I run $ xmgrace plt

    do ir=0,nbox
      test(ir) = sqrt(2/(nbox*h)) * sin((nodes+1) * pi * meshpoints(ir)/(nbox*h))
      write(13,*) ir*h, wavefunctions(ir,0,1,1)*wavefunctions(ir,0,1,1), fullwoodsaxon(ir)
    end do

  end subroutine solve


  subroutine solvelr
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! This subroutine is closely based on the notes provided by the organizers
    ! of the 2016 Density Functional Theory TALENT Course.
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    integer :: i, ir, nnodes
    real(wp) :: Etrial, Eupper, Elower, a1, a2, a3, norm
    real(wp), allocatable :: potential(:), test(:), test2(:),test3(:)
    logical :: sign

    allocate(potential(0:nbox),test(0:nbox),test2(0:nbox),test3(0:nbox))

    Eupper = 100000_wp
    Elower = -v0
    do i=1,1000000
      Etrial = (Eupper+Elower)/2.0
      ! Trying very large values right now, may change this if unstable

      ! Attempting to set the potential before hand, if this does not work, we
      ! can do it "on the fly"
      do ir=0,nbox
        potential(ir) = (-vpb*fullwoodsaxon(ir)+Etrial)/hbar22m
      end do

      wfl(0,0,1,1) = 0.0
      wfr(nbox,0,1,1) = 0.0
      wfl(1,0,1,1) = 1.0
      wfr(nbox-1,0,1,1) = 1.0
      do ir=1,nbox-1
        a1 = 2.0 * (1.0 - (5.0/12.0) * h**2 * potential(ir))
        a2 = (1.0 + (1.0/12.0) * h**2 * potential(ir-1))
        a3 = (1.0 + (1.0/12.0) * h**2 * potential(ir+1))

        wfl(ir+1,0,1,1) = (a1*wfl(ir,0,1,1) - a2*wfl(ir-1,0,1,1))/a3
      end do

      do ir=nbox-1,1,-1
        a1 = 2.0 * (1.0 - (5.0/12.0) * h**2 * potential(ir))
        a2 = (1.0 + (1.0/12.0) * h**2 * potential(ir+1))
        a3 = (1.0 + (1.0/12.0) * h**2 * potential(ir-1))

        wfr(ir-1,0,1,1) = (a1*wfr(ir,0,1,1) - a2*wfr(ir+1,0,1,1))/a3

      end do

      if (.NOT. (mod(nodes,2) .EQ. 0)) then
        wfr(:,0,1,1) = wfr(:,0,1,1)
      end if

      nnodes = 0
      ! I believe this is appropriate logic for checking the sign change of the
      ! wavefunction
      sign = wfr(nbox-1,0,1,1) > 0
      do ir =nbox-1,1,-1
        if ((wfr(ir,0,1,1) > 0) .NEQV. sign) then
          sign = wfr(ir,0,1,1) > 0
          nnodes = nnodes + 1
        end if
      end do

      if (nnodes > nodes) then
        Eupper = Etrial
      else if (nnodes < nodes) then
        Elower = Etrial
      else
        ! This is a variation on the lower energy in order to "squeeze" the
        ! energies together. by moving it a small amount (arbitrarily here)
        ! we can force the solution to converge.
        Elower = Elower + .1

      end if


      if (abs(Eupper - Elower) < conv) then
        !if (abs(wfr(nbox/2) - wfl(nbox/2)) < conv) then
          !if (abs((wfr(nbox/2+1)-wfr(nbox/2))/h - (wfl(nbox/2)-wfl(nbox/2-1))/h) < conv) then
            write (6,*) "Converged!"
            write (6,*) "|Eupper - Elower| =", abs(Eupper - Elower)
            write (6,*) "Energy =", Etrial
            write (6,*) "Exact Energy =",infwell_exact()
            write (6,*) "Difference between calculated and exact =",Etrial-infwell_exact()
            exit
          !end if
        !end if
      end if
    end do

    if (abs(Eupper - Elower) > conv) then
      write (6,*) "Program did not converge!"
      write (*,*) abs(Eupper - Elower)
    end if

    !wavefunctions(0:nbox/2-1) = wfl(0:(nbox/2-1))
    wavefunctions(0:nbox,0,1,1) = wfr(0:nbox,0,1,1)
    ! Normalization
    norm = sqrt(sum(h*wavefunctions(:,0,1,1)*wavefunctions(:,0,1,1)))
    wavefunctions(:,0,1,1) = wavefunctions(:,0,1,1)/norm

    ! Printing points for plotting. I run $ xmgrace plt

    do ir=0,nbox
      test(ir) = sqrt(2/(nbox*h)) * sin((nodes+1) * pi * meshpoints(ir)/(nbox*h))
      test2(ir) = fullwoodsaxon(ir)
      test3(ir) = dfullwoodsaxon(ir)
      write(13,*) ir*h, wavefunctions(ir,0,1,1), wavefunctions(ir,0,1,1)*wavefunctions(ir,0,1,1)
    end do

  end subroutine solvelr

  subroutine solve_r
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! This subroutine is closely based on the notes provided by the organizers
    ! of the 2016 Density Functional Theory TALENT Course.
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    integer :: i, ir, nnodes, j, l, m, is, iq
    real(wp) :: Etrial, Eupper, Elower, a1, a2, a3, norm
    real(wp), allocatable :: potential(:), test(:), test2(:),test3(:)
    logical :: sign

    allocate(potential(0:nbox),test(0:nbox),test2(0:nbox),test3(0:nbox))
    wfr(:,:,:,:) = 0.0
    Eupper = 100000_wp
    Elower = vpb
    do iq =1,2
      do l =0,lmax
        do is = 1,2
            do i=1,100000
              Etrial = (Eupper+Elower)/2.0
              ! Trying very large values right now, may change this if unstable

              ! Attempting to set the potential before hand, if this does not work, we
              ! can do it "on the fly"
              do ir=0,nbox
								if (iq .EQ. 1) then
                	potential(ir) = (-vpb*fullwoodsaxon(ir)-vpb*spinorbit(ir,l,is)+Etrial)/hbar22m
								else 
									potential(ir) = (-vpb*fullwoodsaxon(ir)-vpb*spinorbit(ir,l,is)+Etrial-coulomb(ir))/hbar22m
								end if
              end do

              wfr(nbox,l,is,iq) = 0.0
              wfr(nbox-1,l,is,iq) = 1.0


              do ir=nbox-1,1,-1
                a1 = 2.0 * (1.0 - (5.0/12.0) * h**2 * potential(ir))
                a2 = (1.0 + (1.0/12.0) * h**2 * potential(ir+1))
                a3 = (1.0 + (1.0/12.0) * h**2 * potential(ir-1))

                wfr(ir-1,l,is,iq) = (a1*wfr(ir,l,is,iq) - a2*wfr(ir+1,l,is,iq))/a3

              end do

              if (.NOT. (mod(l,2) .EQ. 0)) then
                wfr(:,l,is,iq) = wfr(:,l,is,iq)
              end if

              nnodes = 0
              ! I believe this is appropriate logic for checking the sign change of the
              ! wavefunction
              sign = wfr(nbox-1,l,is,iq) > 0
              do ir =nbox-1,1,-1
                if ((wfr(ir,l,is,iq) > 0) .NEQV. sign) then
                  sign = wfr(ir,l,is,iq) > 0
                  nnodes = nnodes + 1
                end if
              end do

              if (nnodes > l) then
                Eupper = Etrial
              else if (nnodes < l) then
                Elower = Etrial
              else
                ! This is a variation on the lower energy in order to "squeeze" the
                ! energies together. by moving it a small amount (arbitrarily here)
                ! we can force the solution to converge.
                Elower = Elower + .1

              end if


              if (abs(Eupper - Elower) < conv) then
                !if (abs(wfr(nbox/2) - wfl(nbox/2)) < conv) then
                  !if (abs((wfr(nbox/2+1)-wfr(nbox/2))/h - (wfl(nbox/2)-wfl(nbox/2-1))/h) < conv) then
                    write (6,*) "Converged!"
                    write (6,*) "l =", l
                    write (6,*) "is =",is
                    write (6,*) "iq =",iq
                    write (6,*) "Energy =", Etrial
                    ! Normalization
                    norm = sqrt(sum(h*wfr(:,l,is,iq)*wfr(:,l,is,iq)))
                    wfr(:,l,is,iq) = wfr(:,l,is,iq)/norm
                    exit
                  !end if
                !end if
              end if
            end do
          end do
        end do
      end do


    if (abs(Eupper - Elower) > conv) then
      write (6,*) "Program did not converge!"
      write (*,*) abs(Eupper - Elower)
    end if



    ! Printing points for plotting. I run $ xmgrace plt

    do ir=0,nbox
      test(ir) = sqrt(2/(nbox*h)) * sin((nodes+1) * pi * meshpoints(ir)/(nbox*h))
      test2(ir) = fullwoodsaxon(ir)
      test3(ir) = dfullwoodsaxon(ir)
      write(13,*) ir*h, spinorbit(ir,0,1), spinorbit(ir,1,1), spinorbit(ir,1,2)!wfr(ir,0,1,1)!, wfr(ir,1,1,1), wfr(ir,2,1,1)!, sum(wfr(ir,:,:,:)*wfr(ir,:,:,:))
    end do

  end subroutine solve_r


  function infwell_exact() result(energy)
    real(wp) :: energy

    energy = (nodes+1)**2 *pi**2 *hbar22m/(nbox*h)**2

  end function

  function finite_exact() result(energy)
    real(wp) :: energy

    energy = (nodes+1)**2 *pi**2 *hbar22m/(nbox*h)**2 -v0

  end function

  function infwell(ir, Etrial) result(pot)
    real(wp) :: pot
    real(wp), intent(in) :: Etrial
    integer, intent(in) :: ir

    if ((ir .EQ. 0) .OR. (ir .EQ. nbox)) then
      pot = 1E20_wp
    else
      pot = Etrial/hbar22m
    end if

  end function

  function finitepot(ir, Etrial) result(pot)
    real(wp) :: pot
    real(wp), intent(in) :: Etrial
    integer, intent(in) :: ir

    if ((ir <= nbox/4) .OR. (ir >= nbox*3/4)) then
      pot = Etrial/hbar22m
    else
      pot = (Etrial+v0)/hbar22m
    end if

  end function


  function woodsaxon_s(ir, Etrial) result(pot)
    real(wp) :: pot
    real(wp), intent(in) :: Etrial
    integer, intent(in) :: ir

  !pot = -v0 * 1 / (1 + exp((meshpoints(ir)-300*h)/0.67))
    if (ir < nbox/2) then
      pot = (Etrial + v0 * 1 / (1 + exp((meshpoints(nbox/2-ir)-radius/2*h)/0.67)))/hbar22m
    else
      pot = (Etrial + v0 * 1 / (1 + exp((meshpoints(ir-nbox/2)-radius/2*h)/0.67)))/hbar22m
  end if


  end function

  function woodsaxon(ir, Etrial) result(pot)
    real(wp) :: pot
    integer, intent(in) :: ir
    real(wp), intent(in) :: Etrial

    if (ir < (nbox/2 - radius)) then
      pot = Etrial/hbar22m
    else
      pot = (etrial + v0 * 1 / (1 + exp((meshpoints(ir-(nbox/2 - radius))-radius*h)/0.67)))/ hbar22m
    end if
  end function

!!!Must be multiplied by (positive) vpb in calculations
 function fullwoodsaxon(ir) result(pot)
    real(wp) :: pot
    integer, intent(in) :: ir
      pot = 1 / (1 + exp((meshpoints(ir)-nrad)/0.67))
  end function

!!!Must be multiplied by (positive) vpb in calculations
function dfullwoodsaxon(ir) result(pot)
    real(wp) :: pot
    integer, intent(in) :: ir
      pot = -1 / (1 + exp((meshpoints(ir)-nrad)/0.67))*(1/0.67)*(1 / (1 + exp((-meshpoints(ir)+nrad)/0.67)))
  end function

  function spinorbit(ir,l,is) result(pot)
    integer, intent(in) :: ir,l, is
    real(wp) :: spin, pot
    if(is .EQ. 1) spin = -0.5
    if(is .EQ. 2) spin = 0.5
    if (ir .EQ. 0) then
      pot = 0
    else
      pot = r0**2 * dfullwoodsaxon(ir)/meshpoints(ir) * 0.5 *((l+spin)*(l+spin+1) - l*(l+1) - 0.75)
    end if

  end function

	function coloumb(ir)	result(pot) 
		integer,intent(in) :: ir
		real(wp) ::pot
		if(ir*h .lt. nrads ) pot= (np*e2/nrads)*(3.0d0- (ir*h/nrads)**2) 
		if(ir*h .ge. nrads ) pot= np*e2/(ir*h)

	end function

end module solver
