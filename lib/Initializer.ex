		defmodule Initalizer do

			@m 8

			def start do
				args = System.argv()
			    numNodes = String.to_integer(Enum.at(args, 0))     
			    numRequests = String.to_atom(Enum.at(args, 1))     
			    IO.puts "

			    #########################################

			    		numNodes    : #{numNodes}
			    		numRequests : #{numRequests}

			    #########################################
			    "
			    :timer.sleep 1000
			    IO.puts "Initializing chord with 2 Nodes and joining #{numNodes-2} nodes and starting #{numRequests}"
			    :timer.sleep 1000
			    __init__ numNodes	    
			end

			defp __init__(numNodes) do

				AppSupervisor.start_link
				__init__hopcounter__()
				initNnodes numNodes
			end

			#Initializing the hop counter
			defp __init__hopcounter__ do
				
				AppSupervisor.HopCounterSupervisor.start_link
				AppSupervisor.HopCounterSupervisor.start_node
			end

			#Initializing the stabilizer supervisor
			defp __init__stabilizer__ (pid_N_map) do
				
				AppSupervisor.StabilizerSupervisor.start_link
				ChordStabilizer.start elem(Enum.at(pid_N_map,0) ,1), @m
			end

			#Initializing numNodes in one go
			defp initNnodes(numNodes) do
				
				#Initialize with 2 nodes
				n_values = Enum.map(1..2, fn i -> HashGenerator.hash(@m, Integer.to_string i)|>Integer.to_string|>String.to_atom  end)
				Enum.map(n_values, fn n_value -> AppSupervisor.start_node n_value end)
				child_pids = Supervisor.which_children(:chord_supervisor) |> Enum.map( fn item -> elem(item, 1) end)
				IO.inspect child_pids
				pid_N_map = generateRing child_pids, n_values
				ChordOperations.initializeSuccessors pid_N_map
				ChordOperations.initializePredecessors pid_N_map
				__init__stabilizer__ pid_N_map
				# Generate numNodes*2 number of keys
				# ChordOperations.printFingerTables pid_N_map
				# Join the remaining numNodes-2 to the chord ring 
				pid_N_map = Enum.reduce(1..numNodes-2, pid_N_map, fn _, acc -> 
						    {a, b} = ChordOperations.node_join @m, acc 
					        Map.put acc, a, b
						    end)
				:timer.sleep numNodes*1000
				generateStorePrintKeys numNodes*2, pid_N_map
			end

			#Join numNodes-1 remaining nodes to the chord ring
			defp joinRemnodes(numNodes) do

				{:ok, pid}  = Supervisor.start_child(:chord_supervisor, [])
				hash_pid = HashGenerator.hash @m, Kernel.inspect pid
				pid_N_map = %{pid => hash_pid}		
				Enum.each 1..numNodes-1, fn _ -> ChordOperations.node_join @m, pid_N_map end
			end

			defp generateRing(child_pids, n_values) do

				pid_N_map = child_pids |> Enum.with_index |> Enum.reduce(%{}, fn {pid, i}, acc -> 
										Map.put(acc, pid, Enum.at(n_values, i))
										end)
				IO.inspect pid_N_map
				FingerTable.generate pid_N_map, @m
				ChordOperations.printFingerTables pid_N_map
				pid_N_map
			end

			defp generateStorePrintKeys(numKeys, pid_N_map) do
				keys = KeyGen.generateKeys numKeys, @m
				#Get a random node to start
				start_node = elem(Enum.at(pid_N_map,0) ,1)
				IO.inspect "generated keys ===== #{inspect keys}"
				:timer.sleep 1000
				IO.puts ":store_key in progress ...."
				ChordOperations.storeKeys keys, start_node
				:timer.sleep 1000
				ChordOperations.printKeys pid_N_map
				HopCounter.print_hop_statistics numKeys
			end
		end
		Initalizer.start

