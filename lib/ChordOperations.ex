defmodule ChordOperations do

	#Stores the given list of keys in the chord ring using chord protocol
	def storeKeys(keys, pid_N_map) do
		
		Enum.each keys, fn key ->
					#Starting node is selected at random to initiate :store_key
					starting_node_pid = Enum.random Enum.sort Map.keys pid_N_map
					ChordNodeCoordinator.store_key starting_node_pid, key, pid_N_map
		end
	end

	#Searches for the given key in the chord ring using chord protocol and finds the node where it is stored
	#Returns nil if search fails
	def searchKey(key) do
		
	end
 
	def initializeSuccessors(pid_N_map) do

		IO.puts "Initializing successor pointers for all nodes ..."

		sorted_pid_N_map = Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1))) |> 
					 	   Map.new

		sorted_pid_N_map |> Enum.with_index |>  Enum.each(fn {{pid, _}, i} ->
				
				successor = 
					if i+1 < map_size(sorted_pid_N_map) do
						elem(Enum.at(sorted_pid_N_map, i+1),1)
					else
						elem(Enum.at(sorted_pid_N_map, 0),1)
					end
				
				ChordNodeCoordinator.set_successor pid, successor
		end)
		printSuccessors pid_N_map
	end

	#Prints all the keys stored in all the nodes in the chord ring as %{node, [keys..]}
	def printKeys(pid_N_map) do
		
		pids = Map.keys pid_N_map
		pid_keys_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					keys = ChordNodeCoordinator.get_keys pid
					node = Map.get pid_N_map, pid
					Map.put acc, node, keys
				end
		IO.inspect "keys ========== #{inspect pid_keys_map}"

	end

	#Prints all the fingertables stored in all the nodes in the chord ring as %{node, [keys..]}
	def printFingerTables(pid_N_map) do
		
		pids = Map.keys pid_N_map
		pid_fingertable_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					keys = ChordNodeCoordinator.get_keys pid
					node = Map.get pid_N_map, pid
					Map.put acc, node, keys
				end
		IO.inspect pid_fingertable_map

	end

	#Prints all the successors stored in all the nodes in the chord ring as %{node, successor}
	def printSuccessors(pid_N_map) do
		
		pids = Map.keys pid_N_map
		pid_successors_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					successor = ChordNodeCoordinator.get_fingertable pid
					node = Map.get pid_N_map, pid
					Map.put acc, node, successor
				end
		IO.inspect pid_successors_map

	end
end

# ChordOperations.initializeSuccessors(%{a: 3, b: 2, c: 1})