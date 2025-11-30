# configure docker daemon
  if command -q docker-machine
    eval (docker-machine env default)
  end
