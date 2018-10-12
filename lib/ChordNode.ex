defmodule ChordNode do
	use GenServer

	def start_link() do
		GenServer.start_link(__MODULE__, [])
	end

	def init(_) do
		IO.puts "ChordNode is starting" 
		state = %{:keys => [], :successor => nil, :predecessor => nil, :fingertable => %{}}
    	{:ok, state}
	end

	def handle_call(:get_fingertable, _, state) do
		fingertable = Map.get(state, :fingertable)
	    {:reply, fingertable, state}
	end

	def handle_call(:get_successor, _, state) do
		successor = Map.get(state, :successor)
	    {:reply, successor, state}
	end

	def handle_call(:get_predecessor, _, state) do
		predecessor = Map.get(state, :predecessor)
	    {:reply, predecessor, state}
	end

	def handle_call(:get_keys, _, state) do
		keys = Map.get(state, :keys)
	    {:reply, keys, state}
	end


	def handle_call(:lookup, _, state) do #sets counter when gossip is received
		
	    {:reply, nil , state }
	end

	def handle_cast({:set_successor, successor} , state) do
		new_state = Map.put(state, :successor, successor)
	    {:noreply , new_state}
	end

	def handle_cast({:set_predecessor, predecessor}, state) do
		new_state = Map.put(state, :predecessor, predecessor)
	    {:noreply, new_state}
	end

	def handle_cast({:set_fingertable,fingertable}, state) do
		new_state = Map.put(state, :fingertable, fingertable)
	    {:noreply, new_state}
	end

	def handle_cast({:add_key, key}, state) do
		IO.puts "Adding key .."
		new_state = Map.put(state, :keys, Enum.concat(Map.get(state, :keys), [key]))
		{:noreply, new_state}
	end

	def handle_cast({:store_key, key, pid_N_map}, state) do

		successor = Map.get(state, :successor)
		fingertable = Map.get(state, :fingertable)
		# IO.inspect "fingertable = #{inspect fingertable} at #{inspect self()} for key #{inspect key}"


		#All the nodes in the fingertable
		nodes = Enum.sort(Map.values fingertable)

		nodes_lesser = Enum.filter(nodes, fn x -> x<=key 
										end)

		# IO.puts "At #{inspect self()}"
		if length(nodes_lesser) != 0 do
			max_lesser_node = Enum.max nodes_lesser
			max_lesser_node_pid = pid_N_map |> Enum.find(fn {_, val} -> 
								               val == max_lesser_node end)
									  		|> elem(0) 
			ChordNodeCoordinator.store_key(max_lesser_node_pid, key, pid_N_map)
		else
			#If there is no max node less than key, add key to successor list
			IO.puts "Adding to keys list"
			successor_pid = pid_N_map |> Enum.find(fn {_, val} -> 
										 val == successor end)
									  |> elem(0)
			ChordNodeCoordinator.add_key(successor_pid, key)
		end

		{:noreply, state}
	end

	def handle_cast(:lookup, state) do #sets counter when gossip is received
		
	    {:noreply, state}
	end



	defp terminate(_ \\ 1) do
	    # IO.inspect :terminating
	    Process.exit self(), :normal
	end
end

defmodule ChordNodeCoordinator do

	def get_successor(pid) do
		GenServer.call(pid, :get_successor)
	end

	def set_successor(pid, successor) do
		GenServer.cast(pid, {:set_successor, successor})
	end

	def get_predecessor(pid) do
		GenServer.call(pid, :get_predecessor)
	end

	def set_predecessor(pid, predecessor) do
		GenServer.cast(pid, {:set_predecessor, predecessor})
	end

	def get_fingertable(pid) do
		GenServer.call(pid, :get_fingertable)
	end

	def set_fingertable(pid, fingertable) do
		GenServer.cast(pid, {:set_fingertable,fingertable})
	end

	def get_keys(pid) do
		GenServer.call(pid, :get_keys)
	end

	#Just adds the key to the node's key list
	def add_key(pid, key) do
		GenServer.cast(pid, {:add_key, key})
	end

	#Store key is uses chord algorithm to store the key in the correct node
	def store_key(pid, key, pid_N_map) do
		GenServer.cast(pid, {:store_key, key, pid_N_map})
	end

	def lookup(pid) do
		GenServer.cast(pid, :lookup)
	end
end
