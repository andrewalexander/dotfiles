install:
	@stow -vS --no-folding config
	@fc-cache

clean:
	@stow -vD --no-folding config
