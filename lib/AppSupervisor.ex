defmodule AppSupervisor do

  	# This is the supervisor that coordinates the work among all the workers (chordNodes)
  	
	use Supervisor

	def start_link() do
		Supervisor.start_link(__MODULE__, [], name: :ChordSupervisor)
	end
	
	def init([]) do
		children = [
			worker(ChordNode, [], [restart: :temporary]),
		]
		supervise(children, strategy: :simple_one_for_one)
	end
	
	# def shoot(node_id) do
	# 	 spec = worker(ChordNode, [], [id: node_id, restart: :temporary])
	# 	 Supervisor.start_child(__MODULE__, spec)
	# end

	defmodule StabilizerSupervisor do
		
		use Supervisor

		def start_link() do
			Supervisor.start_link(__MODULE__, [], name: :StabilizerSupervisor)
		end
		
		def init([]) do
			children = [
				worker(ChordStabilizer, [], [restart: :temporary]),
			]
			supervise(children, strategy: :simple_one_for_one)
		end

	end

end
