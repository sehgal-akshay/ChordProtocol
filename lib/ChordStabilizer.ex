defmodule ChordStabilizer do
	use GenServer

	def start_link do
		GenServer.start_link(__MODULE__, [], name: :chord_stabilizer)
	end

	def init(_) do
		IO.puts "ChordStabilizer is starting" 
    	{:ok, :ok}
	end

	def handle_cast({:stabilize, current_node}, state) do

		successor = ChordNodeCoordinator.get_successor current_node
		successor_predecessor = ChordNodeCoordinator.get_predecessor(successor)
		
		if successor_predecessor == current_node do
			if successor != nil do
				ChordStabilizerCoordinator.stabilize successor
			end
		else
			IO.puts "Stabilizing at node #{inspect current_node} to successor_predecessor = #{inspect successor_predecessor}, successor = #{inspect successor}}"

			ChordNodeCoordinator.set_successor current_node, successor_predecessor
			ChordNodeCoordinator.set_predecessor successor_predecessor, current_node
			#Continue stabilization after the fix
			ChordStabilizerCoordinator.stabilize successor_predecessor
		end
	    {:noreply, state}
	end

	def handle_cast({:fix_finger, current_node, m}, state) do

		successor = ChordNodeCoordinator.get_successor current_node
		# IO.puts "Fix_Finger at node #{inspect current_node}, successor = #{inspect successor}}"

		FingerTable.fix_finger current_node, m
		#Continue fix_finger after the fix
		ChordStabilizerCoordinator.fix_finger successor, m
	    {:noreply, state}
	end
	
	defp terminate(_ \\ 1) do
	    # IO.inspect :terminating
	    Process.exit self(), :normal
	end

	def start(start_node, m) do
		
		IO.puts "Stabilizer is running ....."
		Supervisor.start_child(:stabilizer_supervisor, [])
		#Starts stabilization at a random node 
		ChordStabilizerCoordinator.stabilize start_node
		ChordStabilizerCoordinator.fix_finger start_node, m
	end
end

defmodule ChordStabilizerCoordinator do

	def stabilize(start_node) do
		GenServer.cast(:chord_stabilizer, {:stabilize, start_node})
	end

	def fix_finger(start_node, m) do
		GenServer.cast(:chord_stabilizer, {:fix_finger, start_node, m})
	end
end
