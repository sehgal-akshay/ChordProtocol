defmodule ChordStabilizer do
	use GenServer

	def start_link do
		GenServer.start_link(__MODULE__, [], name: :chord_stabilizer)
	end

	def init(_) do
		IO.puts "ChordStabilizer is starting" 
		state = %{:pid_N_map => %{}}
    	{:ok, state}
	end

	def handle_call({:get_pid_N_map, _, state} , state) do
		pid_N_map = Map.get(state, :pid_N_map)
	    {:reply, pid_N_map, state}
	end

	def handle_cast({:set_pid_N_map, pid_N_map}, state) do
		new_state = Map.put(state, :pid_N_map, pid_N_map)
	    {:noreply, new_state}
	end

	def handle_cast({:stabilize, current_pid}, state) do

		pid_N_map = Map.get state, :pid_N_map
		successor = ChordNodeCoordinator.get_successor(current_pid)
		current_node = Map.get pid_N_map, current_pid
		successor_tuple = pid_N_map |> Enum.find(fn {_, val} -> 
												 val == successor end)
		successor_pid =
			if successor_tuple != nil do
				elem(successor_tuple, 0)
			else
				IO.puts "### successor_tuple is nil ####"
				nil
			end

		IO.puts "Stabilizing at #{inspect current_node}"
	
		successor_predecessor = ChordNodeCoordinator.get_predecessor(successor_pid)
		if successor_predecessor == current_node do
			if successor_pid != nil do
				ChordStabilizerCoordinator.stabilize successor_pid
			end
		else
			IO.puts "Stabilizing at node #{inspect current_node} to successor_predecessor = #{inspect successor_predecessor}, successor = #{inspect successor}}"

			ChordNodeCoordinator.set_successor current_pid, successor_predecessor
			successor_predecessor_pid = pid_N_map |> Enum.find(fn {_, val} -> 
												 val == successor_predecessor end)
											  |> elem(0)
			ChordNodeCoordinator.set_predecessor successor_predecessor_pid, current_node
		end
	    {:noreply, state}
	end
	
	defp terminate(_ \\ 1) do
	    # IO.inspect :terminating
	    Process.exit self(), :normal
	end

	def start(pid_N_map) do
		
		IO.puts "Stabilizer is running ....."
		Supervisor.start_child(:StabilizerSupervisor, [])
		ChordStabilizerCoordinator.set_pid_N_map pid_N_map
		#Starts stabilization at a random node 
		ChordStabilizerCoordinator.stabilize elem(Enum.at(pid_N_map, 0),0)
	end
end

defmodule ChordStabilizerCoordinator do

	def stabilize(start_pid) do
		GenServer.cast(:chord_stabilizer, {:stabilize, start_pid})
	end

	def get_pid_N_map do
		GenServer.call(:chord_stabilizer, :get_pid_N_map)
	end

	def set_pid_N_map(pid_N_map) do
		IO.inspect "Updating pid_N_map in stabilizer"
		GenServer.cast(:chord_stabilizer, {:set_pid_N_map, pid_N_map})
	end
end
