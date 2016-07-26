subroutine sphbasis(n,nr,nl,nj,lpr)
      use constants
      implicit none
      integer:: il,nnsph,nlsph,nrsph,mssph,njsph,n,nt 
      logical:: lpr
      integer::nr(n),nl(n),nj(n)

      nr(1) = 0
      nl(1) = 0
      nj(1) = 0
!
      nr(2) = 0
      nl(2) = 0
      nj(2) = 1
!
      il = 2
!
      do nnsph = 1, nbase
         if(mod(nnsph,2) .eq. 0) then
            do nlsph = 0,nnsph,2
            nrsph = (nnsph-nlsph)/2
            do mssph=0,1
               if(nlsph+mssph .gt. 0) then
                 il=il+1
                 nr(il)=nrsph
                 nl(il)=nlsph
                 nj(il)=nlsph+mssph
               endif
            enddo ! mssph
         enddo !nlsph

        elseif(mod(nnsph,2) .eq. 1) then
           do nlsph = 1,nnsph,2
              nrsph = (nnsph-nlsph)/2
              do mssph = 0,1
                 if(nlsph+mssph .gt. 0) then
                    il = il+1
                        nr(il) = nrsph
                        nl(il) = nlsph
                        nj(il) = nlsph+mssph
                endif
             enddo !nlsph
          enddo !mssph
        else
          stop 'error in base'
        endif

        if(nnsph .eq. nbase) nt = il

        enddo

! printout
        if(lpr) then

        write(*,*) ' ****** SPHERICAL BASIS ***************'
   
        do il=1,nt
        nrsph = nr(il)
        nlsph = nl(il)
        njsph = nj(il)
        nnsph = 2*nrsph + nlsph

        !write(*,110)'NN = ',nnsph,'nr = ',nrsph,'ml = ',nlsph,'(2*nj-1)/2 = ',2*njsph-1,'/2'
        write(*,110)'NN = ',nnsph,'nr = ',nrsph,'nl = ',nlsph,'ms = ', 2*(njsph-nlsph)-1, '/2'

  110   format(5x,a,i2,3x,a,i2,3x,a,i2,3x,a,i2,a)

        enddo

        write(*,*) '****** END SPHERICAL BASIS ***********'

        endif
end subroutine sphbasis




