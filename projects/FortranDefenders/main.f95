program main
	use grid

	open(unit=5,file='in',status='old',form='formatted')
	
	call init_params
	call init_grids




	close(5)
end program main
