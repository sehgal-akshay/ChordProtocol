defmodule AppSupervisor do

	#This is the supervisor that coordinates the work among all the workers (chordNodes)
	use Supervisor

	def start_link() do
		Supervisor.start_link(__MODULE__, [], name: :ChordSupervisor)
	end
	def init([]) do
		children = [
			worker(ChordNode, [], restart: :temporary)
		]
		supervise(children, strategy: :simple_one_for_one)
	end
end