defmodule ChordOperations do

	#Stores the given list of keys in the chord ring using chord protocol
	def storeKeys(keys, pid_N_map) do
		
		keys = Enum.slice keys, 0, 5
		Enum.each keys, fn key ->
					# key = Enum.random keys
					IO.inspect "Storing key == #{key}"
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

		sorted_pid_N_list = Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1)))
		sorted_pid_N_map =  sorted_pid_N_list|> 
					 	   Map.new

		IO.puts "sorted_pid_N_map === #{inspect Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1)))}"
		:timer.sleep 5000

		sorted_pid_N_map |> Enum.with_index |>  Enum.each(fn { _ , i} ->
				
				IO.puts "#{i+1}, #{map_size(sorted_pid_N_map)}"

				pid = elem(Enum.at(sorted_pid_N_list, i),0)
				current_N = elem(Enum.at(sorted_pid_N_list, i),1)
				successor = 
					if i+1 < map_size(sorted_pid_N_map) do
						elem(Enum.at(sorted_pid_N_list, i+1),1)
					else
						elem(Enum.at(sorted_pid_N_list, 0),1)
					end
				IO.puts "current_pid = #{inspect pid}, current_N=#{current_N}, s=#{successor}"
				ChordNodeCoordinator.set_successor pid, successor
		end)
		printSuccessors pid_N_map
	end

	def initializePredecessors(pid_N_map) do

		IO.puts "Initializing predecessor pointers for all nodes ..."

		sorted_pid_N_list = Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1)))
		sorted_pid_N_map =  sorted_pid_N_list|> 
					 	   Map.new

		IO.puts "sorted_pid_N_map === #{inspect Map.to_list(pid_N_map) |> 
					 	   Enum.sort_by(&(elem(&1, 1)))}"
		:timer.sleep 5000

		sorted_pid_N_map |> Enum.with_index |>  Enum.each(fn { _ , i} ->
				
				IO.puts "#{i+1}, #{map_size(sorted_pid_N_map)}"

				pid = elem(Enum.at(sorted_pid_N_list, i),0)
				current_N = elem(Enum.at(sorted_pid_N_list, i),1)
				predecessor = 
					if i-1 >= 0 do
						elem(Enum.at(sorted_pid_N_list, i-1),1)
					else
						elem(Enum.at(sorted_pid_N_list, map_size(sorted_pid_N_map)-1),1)
					end
				IO.puts "current_pid = #{inspect pid}, current_N=#{current_N}, p=#{predecessor}"
				ChordNodeCoordinator.set_predecessor pid, predecessor
		end)
		printPredecessors pid_N_map
	end

	def node_join(m, pid_N_map) do
		
		enter_ring_pid = Enum.random Map.keys pid_N_map
		{:ok, pid} = Supervisor.start_child(:ChordSupervisor, [])
		new_node = HashGenerator.hash(m, Kernel.inspect pid)
		pid_N_map = Map.put pid_N_map, pid, new_node
		#Pass the updated pid_N_map to stabilizer
		ChordStabilizerCoordinator.set_pid_N_map pid_N_map
		ChordNodeCoordinator.join enter_ring_pid, new_node, pid_N_map
		:timer.sleep 15000
		printSuccessors pid_N_map
		printPredecessors pid_N_map
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
		IO.inspect "keys ========== #{inspect pid_keys_map, charlists: :as_lists}"

	end

	#Prints all the fingertables stored in all the nodes in the chord ring as %{node, [keys..]}
	def printFingerTables(pid_N_map) do
		
		pids = Map.keys pid_N_map
		pid_fingertable_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					fingertables = ChordNodeCoordinator.get_fingertable pid
					node = Map.get pid_N_map, pid
					Map.put acc, node, fingertables
				end
		IO.inspect pid_fingertable_map
	end

	#Prints all the successors stored in all the nodes in the chord ring as %{node, successor}
	def printSuccessors(pid_N_map) do
		
		pids = Map.keys pid_N_map
		IO.inspect "#{inspect pid_N_map}"
		pid_successors_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					successor = ChordNodeCoordinator.get_successor pid
					IO.puts "pids === #{inspect pid}"
					node = Map.get pid_N_map, pid
					IO.puts "node = #{node}, succ = #{successor}"
					Map.put acc, node, successor
				end
		IO.inspect "successors_map = #{inspect pid_successors_map}"

	end

	#Prints all the predecessors stored in all the nodes in the chord ring as %{node, predecessor}
	def printPredecessors(pid_N_map) do
		
		pids = Map.keys pid_N_map
		IO.inspect "#{inspect pid_N_map}"
		pid_predecessors_map = 
				Enum.reduce pids, %{}, fn pid, acc ->
					predecessor = ChordNodeCoordinator.get_predecessor pid
					IO.puts "pids === #{inspect pid}"
					node = Map.get pid_N_map, pid
					IO.puts "node = #{node}, pred = #{predecessor}"
					Map.put acc, node, predecessor
				end
		IO.inspect "predecessors_map = #{inspect pid_predecessors_map}"

	end
end

# ChordOperations.initializeSuccessors(%{a: 3, b: 2, c: 1})